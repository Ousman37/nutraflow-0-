import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../subscription_config.dart';

class SubscriptionService {
  // Guards against configuring the SDK more than once, regardless of how
  // many times initializeSdk() ends up being called.
  static bool _configured = false;

  // Only ever logs the key's store prefix (e.g. "appl_") — never any part
  // of the actual secret body.
  static String _safePrefixFor(String key) {
    final cut = key.indexOf('_');
    return cut == -1 ? '(unrecognized format)' : key.substring(0, cut + 1);
  }

  // Picks the key to use for this platform + build mode. Returns null if no
  // valid key is available — callers must NOT fall back to a test key or an
  // empty string; RevenueCat's SDK can hard-crash on launch if configured
  // with a Test Store key in a real Release/TestFlight/App Store build.
  static String? _resolveApiKey() {
    final configuredKey = Platform.isIOS
        ? SubscriptionConfig.iosApiKey
        : SubscriptionConfig.androidApiKey;
    final realPrefix = Platform.isIOS ? 'appl_' : 'goog_';

    if (configuredKey.startsWith(realPrefix)) {
      return configuredKey;
    }

    // A Test Store key ("test_...") is only ever acceptable in a true debug
    // build, and only because the developer put it in their own local .env
    // on purpose — never as a silent fallback, and never in release/profile.
    if (kDebugMode && configuredKey.startsWith('test_')) {
      debugPrint('[RevenueCat] Using a Test Store key — debug build only. '
          'This must never happen in a release/TestFlight/App Store build.');
      return configuredKey;
    }

    if (configuredKey.isEmpty) {
      debugPrint('[RevenueCat] No REVENUECAT_${Platform.isIOS ? "IOS" : "ANDROID"}_API_KEY '
          'set in .env — subscription features will be unavailable.');
    } else {
      debugPrint('[RevenueCat] Configured key has prefix '
          '"${_safePrefixFor(configuredKey)}", expected "$realPrefix" '
          '(kDebugMode=$kDebugMode). Refusing to use it — subscription '
          'features will be unavailable rather than risk configuring the '
          'SDK with a wrong/test key in this build.');
    }
    return null;
  }

  // Whether Purchases.configure() has actually run. Callers MUST check this
  // (or the bool this method returns) before calling any other Purchases.*
  // API — PurchasesHybridCommon enforces "configured before use" with a
  // native Swift fatalError(), which is a hard process crash that no Dart
  // or native try/catch can intercept. There is no safe way to "handle" that
  // error after the fact; the only fix is to never make the call.
  static bool get isConfigured => _configured;

  // Call once at startup — only initializes the SDK, no user linked yet.
  // Idempotent: a second call is a safe no-op. Returns whether the SDK is
  // actually configured and safe to call other Purchases.* methods on.
  static Future<bool> initializeSdk() async {
    if (_configured) {
      debugPrint('[RevenueCat] initializeSdk() called again — already '
          'configured, ignoring.');
      return true;
    }

    final apiKey = _resolveApiKey();
    if (apiKey == null) {
      // Graceful failure: do not call Purchases.configure() at all, and the
      // caller must not call anything else in this class either. The app
      // keeps running; SubscriptionController treats this the same as a
      // network failure and falls back to cached pro status.
      return false;
    }

    debugPrint('[RevenueCat] configure() starting — key prefix '
        '"${_safePrefixFor(apiKey)}", '
        '${kReleaseMode ? "release" : kProfileMode ? "profile" : "debug"} build.');
    // Verbose RevenueCat SDK logging (which includes raw signed transaction
    // JWTs) is invaluable for local debugging but must never ship in a
    // release/TestFlight/App Store build — restrict it to non-release
    // builds only.
    await Purchases.setLogLevel(kReleaseMode ? LogLevel.warn : LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
    final appUserId = await Purchases.appUserID;
    debugPrint('[RevenueCat] configure() completed — App User ID: $appUserId');
    return true;
  }

  // Link a Firebase UID to RevenueCat so purchase history follows the user.
  Future<CustomerInfo> logIn(String userId) async {
    final result = await Purchases.logIn(userId);
    return result.customerInfo;
  }

  // Call when the user signs out.
  Future<void> logOut() async {
    await Purchases.logOut();
  }

  // Whether the active customer has the "pro" entitlement.
  Future<bool> checkIsSubscribed() async {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active
        .containsKey(SubscriptionConfig.entitlementId);
  }

  Future<CustomerInfo> getCustomerInfo() async {
    final info = await Purchases.getCustomerInfo();
    debugPrint('[RevenueCat] getCustomerInfo() — active entitlements: '
        '${info.entitlements.active.keys}');
    return info;
  }

  // Returns the current RevenueCat offering, or null if unavailable.
  // Logs the actual failure reason instead of swallowing it — a bad API key,
  // a missing "current" offering, or a network error all land here and were
  // previously indistinguishable from each other (and invisible entirely).
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      debugPrint('[RevenueCat] getOfferings() ok — ${offerings.all.length} '
          'offering(s) total, current = '
          '${offerings.current?.identifier ?? "null (no offering marked \"current\" in RevenueCat → Offerings)"}');
      return offerings;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('[RevenueCat] getOfferings() failed: code=$code '
          'message="${e.message}" details=${e.details}');
      return null;
    } catch (e) {
      debugPrint('[RevenueCat] getOfferings() failed with unexpected error: $e');
      return null;
    }
  }

  // Initiates a purchase. Throws PlatformException if it fails or is cancelled.
  Future<CustomerInfo> purchasePackage(Package package) async {
    debugPrint('[RevenueCat] purchasePackage() starting for '
        '${package.storeProduct.identifier} (${package.storeProduct.priceString})');
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      debugPrint('[RevenueCat] purchasePackage() succeeded — active '
          'entitlements: ${result.customerInfo.entitlements.active.keys}');
      return result.customerInfo;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      debugPrint('[RevenueCat] purchasePackage() failed: code=$code '
          'message="${e.message}"');
      rethrow;
    }
  }

  // Restores previous purchases (App Store / Play Store).
  Future<CustomerInfo> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    debugPrint('[RevenueCat] restorePurchases() — active entitlements: '
        '${info.entitlements.active.keys}');
    return info;
  }

  bool isActiveFromInfo(CustomerInfo info) {
    final active = info.entitlements.active.containsKey(
      SubscriptionConfig.entitlementId,
    );
    debugPrint('[RevenueCat] entitlement check — looking for '
        '"${SubscriptionConfig.entitlementId}", active entitlements on '
        'account: ${info.entitlements.active.keys}, match=$active');
    return active;
  }

  // True when the user cancelled the purchase sheet — no error should be shown.
  bool isCancellation(PlatformException e) {
    try {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return code == PurchasesErrorCode.purchaseCancelledError;
    } catch (_) {
      return false;
    }
  }

  // Register a listener that fires whenever RevenueCat has updated CustomerInfo.
  // This is the reliable hook for sandbox purchases where the entitlement
  // confirmation may arrive after purchasePackage() returns.
  void addCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  void removeCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {
    Purchases.removeCustomerInfoUpdateListener(listener);
  }
}
