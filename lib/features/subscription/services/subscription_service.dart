import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../subscription_config.dart';

class SubscriptionService {
  // Call once at startup — only initializes the SDK, no user linked yet.
  static Future<void> initializeSdk() async {
    final apiKey = Platform.isIOS
        ? SubscriptionConfig.iosApiKey
        : SubscriptionConfig.androidApiKey;

    // RevenueCat public SDK keys are always prefixed `appl_` (iOS) or
    // `goog_` (Android) — anything else is a placeholder that was never
    // replaced with the real key from app.revenuecat.com.
    final expectedPrefix = Platform.isIOS ? 'appl_' : 'goog_';
    if (!apiKey.startsWith(expectedPrefix)) {
      debugPrint(
          '[RevenueCat] WARNING: iosApiKey/androidApiKey does not look like a '
          'real RevenueCat key (expected prefix "$expectedPrefix", got '
          '"$apiKey"). Purchases.configure() will "succeed" locally but every '
          'server call (getOfferings, purchase, restore) will fail auth. '
          'Replace it with the real key from RevenueCat → Project → Apps.');
    }

    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    debugPrint('[RevenueCat] configure() completed (key: '
        '${apiKey.substring(0, apiKey.length.clamp(0, 8))}…)');
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

  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

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
  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();

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
