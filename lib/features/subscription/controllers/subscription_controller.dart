import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../subscription_config.dart';
import '../services/subscription_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/services/firestore_service.dart';
import '../../../routes/app_routes.dart';

enum SubscriptionStatus { loading, free, pro }

class SubscriptionController extends GetxController with WidgetsBindingObserver {
  final _service = SubscriptionService();
  final _authController = Get.find<AuthController>();
  final _firestoreService = FirestoreService();

  final Rx<SubscriptionStatus> status = SubscriptionStatus.loading.obs;
  final RxInt freeAnalysesUsed = 0.obs;
  final RxBool isPurchasing = false.obs;
  final RxBool isRestoring = false.obs;
  final Rx<Package?> monthlyPackage = Rx<Package?>(null);
  final Rx<Package?> yearlyPackage = Rx<Package?>(null);
  final Rx<Package?> lifetimePackage = Rx<Package?>(null);
  // Neutral placeholders — never shown as a real price. Real prices always
  // come from StoreProduct.priceString once offerings load; if these are
  // still visible when the purchase button is tapped, offerings failed to
  // load (see debug console for the logged reason).
  final RxString monthlyPriceString = '···'.obs;
  final RxString yearlyPriceString = '···'.obs;
  final RxString selectedPlan = 'yearly'.obs;
  bool _offeringsLoaded = false;

  // Drives the paywall's CTA button: spinner while an attempt is in flight,
  // "Retry" once every retry has been exhausted without success. These are
  // deliberately separate from isPurchasing, which is about the purchase
  // sheet, not offerings loading.
  final RxBool isLoadingOfferings = false.obs;
  final RxBool offeringsFailed = false.obs;

  String get priceString => selectedPlan.value == 'yearly'
      ? yearlyPriceString.value
      : monthlyPriceString.value;

  bool _sdkReady = false;
  CustomerInfoUpdateListener? _customerInfoListener;

  bool get isPro => status.value == SubscriptionStatus.pro;
  bool get isStatusLoading => status.value == SubscriptionStatus.loading;
  int get freeAnalysesLeft =>
      (SubscriptionConfig.freeLogLimit - freeAnalysesUsed.value)
          .clamp(0, SubscriptionConfig.freeLogLimit);
  bool get canLogMeal => isPro || freeAnalysesLeft > 0;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    ever<User?>(_authController.firebaseUser, _onAuthChanged);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_customerInfoListener != null) {
      _service.removeCustomerInfoUpdateListener(_customerInfoListener!);
    }
    super.onClose();
  }

  // Re-checks entitlement status whenever the app comes back to the
  // foreground — e.g. a subscription purchased/restored/cancelled outside
  // this session (a different device, App Store Connect, expiry while
  // backgrounded) is reflected promptly instead of only on next full launch.
  // The passive CustomerInfoUpdateListener already covers most of this, but
  // this is a direct, explicit check rather than relying solely on the SDK's
  // own background sync timing.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _sdkReady) {
      _refreshEntitlementOnResume();
    }
  }

  Future<void> _refreshEntitlementOnResume() async {
    try {
      final info = await _service.getCustomerInfo();
      _onCustomerInfoUpdate(info);
    } catch (e) {
      debugPrint('[RevenueCat] entitlement refresh on resume failed: $e');
    }
  }

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    try {
      final configured = await SubscriptionService.initializeSdk();
      await _loadFreeAnalysesUsed();

      if (!configured) {
        // No usable RevenueCat key for this build. _sdkReady stays false,
        // which is what gates every other Purchases.*-touching path in this
        // controller (see _onAuthChanged, _fetchOfferings, purchase(),
        // restorePurchases()) — calling any of them before configure() has
        // run risks a native fatalError() that no try/catch can stop.
        final cached = await _loadCachedProStatus();
        status.value =
            cached ? SubscriptionStatus.pro : SubscriptionStatus.free;
        return;
      }

      _sdkReady = true;

      // Wire up the listener BEFORE any login so no update is ever missed.
      // This is the key fix for sandbox: RC may confirm the entitlement async,
      // after purchasePackage() has already returned.
      _customerInfoListener = _onCustomerInfoUpdate;
      _service.addCustomerInfoUpdateListener(_customerInfoListener!);

      final uid = _authController.currentUserId;
      if (uid.isNotEmpty) {
        await _loginAndRefresh(uid);
      } else {
        status.value = SubscriptionStatus.free;
      }

      _fetchOfferings(); // fire-and-forget
    } catch (_) {
      // SDK failed to init — fall back to local cache so paying users aren't locked out
      final cached = await _loadCachedProStatus();
      status.value =
          cached ? SubscriptionStatus.pro : SubscriptionStatus.free;
    }
  }

  Future<void> _loginAndRefresh(String uid) async {
    try {
      final info = await _service.logIn(uid);
      final isActive = _service.isActiveFromInfo(info);
      status.value =
          isActive ? SubscriptionStatus.pro : SubscriptionStatus.free;
      // Keep local cache in sync with RevenueCat truth
      if (isActive) await _persistProStatus(true);
    } catch (_) {
      // Network failure → fall back to local cache so paying users aren't blocked
      final cached = await _loadCachedProStatus();
      status.value =
          cached ? SubscriptionStatus.pro : SubscriptionStatus.free;
    }
  }

  void _onAuthChanged(User? user) {
    if (!_sdkReady) return;
    if (user == null) {
      _handleSignOut();
    } else if (user.emailVerified) {
      _loginAndRefresh(user.uid);
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _service.logOut();
    } catch (_) {}
    // Clear the cached pro flag so it doesn't bleed into the next login
    await _persistProStatus(false);
    status.value = SubscriptionStatus.free;
    monthlyPackage.value = null;
    yearlyPackage.value = null;
    lifetimePackage.value = null;
    monthlyPriceString.value = '···';
    yearlyPriceString.value = '···';
    _offeringsLoaded = false;
    offeringsFailed.value = false;
  }

  // Public entry point — called once at startup and again by the paywall's
  // Retry action. Wraps the retrying attempt with the loading/failed state
  // the UI observes, so the CTA button can show a spinner while this runs
  // and switch to "Retry" only once every attempt below has been exhausted.
  Future<void> _fetchOfferings() async {
    if (!_sdkReady) {
      // SDK was never configured (missing/invalid key) — surface this as a
      // failure rather than leaving the paywall stuck showing a placeholder
      // price with no explanation and no way to retry.
      offeringsFailed.value = true;
      return;
    }
    if (isLoadingOfferings.value) return; // already in flight

    isLoadingOfferings.value = true;
    try {
      await _fetchOfferingsAttempt(retriesLeft: 3);
    } finally {
      isLoadingOfferings.value = false;
    }
  }

  // Called from the paywall when the user taps "Retry" after a failed load.
  Future<void> retryLoadOfferings() => _fetchOfferings();

  // Fetches offerings and resolves the monthly/yearly packages. StoreKit
  // product loading can be slow (especially cold-launch on a fresh
  // TestFlight install), so this retries a few times with a short delay
  // instead of giving up permanently after one failed/empty attempt.
  Future<void> _fetchOfferingsAttempt({required int retriesLeft}) async {
    final offerings = await _service.getOfferings();
    final current = offerings?.current;

    if (current == null) {
      if (retriesLeft > 0) {
        await Future.delayed(const Duration(seconds: 2));
        return _fetchOfferingsAttempt(retriesLeft: retriesLeft - 1);
      }
      debugPrint('[RevenueCat] giving up after retries — no current offering. '
          'Check RevenueCat → Offerings for one marked "current", and that '
          'App Store Connect subscriptions are in "Ready to Submit"/approved '
          'state (unapproved products often fail to load from sandbox/TestFlight).');
      offeringsFailed.value = true;
      return;
    }

    final packageSummary = current.availablePackages
        .map((p) => '${p.identifier} -> ${p.storeProduct.identifier} '
            '(${p.storeProduct.priceString})')
        .join(', ');
    debugPrint('[RevenueCat] resolving packages from offering '
        '"${current.identifier}": $packageSummary');

    final monthly = current.monthly;
    if (monthly != null) {
      monthlyPackage.value = monthly;
      monthlyPriceString.value = monthly.storeProduct.priceString;
    } else {
      debugPrint('[RevenueCat] no package with type "Monthly" found in '
          'current offering — check the package\'s Package Type in RevenueCat.');
    }

    final yearly = current.annual;
    if (yearly != null) {
      yearlyPackage.value = yearly;
      yearlyPriceString.value = yearly.storeProduct.priceString;
    } else {
      debugPrint('[RevenueCat] no package with type "Annual" found in '
          'current offering — check the package\'s Package Type in RevenueCat.');
    }

    lifetimePackage.value = current.lifetime;

    if (monthly != null || yearly != null) {
      _offeringsLoaded = true;
      offeringsFailed.value = false;
    } else if (retriesLeft > 0) {
      await Future.delayed(const Duration(seconds: 2));
      return _fetchOfferingsAttempt(retriesLeft: retriesLeft - 1);
    } else {
      debugPrint('[RevenueCat] giving up after retries — offering '
          '"${current.identifier}" has packages but none are typed '
          '"Monthly" or "Annual".');
      offeringsFailed.value = true;
    }
  }

  // ── RevenueCat customer info listener ─────────────────────────────────────
  // Called whenever RevenueCat delivers an updated CustomerInfo — including
  // async entitlement confirmations that arrive after purchasePackage() returns.

  void _onCustomerInfoUpdate(CustomerInfo info) {
    final nowIsPro = _service.isActiveFromInfo(info);
    if (nowIsPro && status.value != SubscriptionStatus.pro) {
      status.value = SubscriptionStatus.pro;
      _persistProStatus(true);
    } else if (!nowIsPro && status.value == SubscriptionStatus.pro) {
      // Subscription expired or was revoked
      status.value = SubscriptionStatus.free;
      _persistProStatus(false);
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _persistProStatus(bool isPro) async {
    // 1. Local SharedPreferences — fast, works offline
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SubscriptionConfig.proStatusPrefsKey, isPro);

    // 2. Firestore — survives app reinstall, readable server-side
    final uid = _authController.currentUserId;
    if (uid.isNotEmpty) {
      try {
        await _firestoreService.setProStatus(uid, isPro);
      } catch (_) {
        // Non-fatal: Firestore write fails gracefully, local cache is enough
      }
    }
  }

  Future<bool> _loadCachedProStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(SubscriptionConfig.proStatusPrefsKey) ?? false;
  }

  // ── Free-trial tracking ────────────────────────────────────────────────────

  Future<void> _loadFreeAnalysesUsed() async {
    final prefs = await SharedPreferences.getInstance();
    freeAnalysesUsed.value =
        prefs.getInt(SubscriptionConfig.freeLogsPrefsKey) ?? 0;
  }

  Future<void> recordAnalysis() async {
    if (isPro) return;
    freeAnalysesUsed.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        SubscriptionConfig.freeLogsPrefsKey, freeAnalysesUsed.value);
  }

  // ── Purchase ───────────────────────────────────────────────────────────────

  Package? _resolveSelectedPackage() => selectedPlan.value == 'yearly'
      ? (yearlyPackage.value ?? monthlyPackage.value)
      : monthlyPackage.value;

  Future<void> purchase() async {
    if (!_sdkReady) {
      debugPrint('[RevenueCat] purchase() aborted — SDK was never '
          'configured (missing/invalid API key). Not calling any '
          'Purchases.* API.');
      Get.snackbar(
        'Not Available',
        'Subscription products are loading. Please try again shortly.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    var pkg = _resolveSelectedPackage();

    if (pkg == null && !_offeringsLoaded) {
      // Don't permanently give up just because the background fetch at
      // startup hasn't resolved yet — give it one real attempt right now,
      // since by the time the user reaches the paywall and taps buy,
      // network/StoreKit has often caught up.
      debugPrint('[RevenueCat] purchase() tapped before offerings loaded — '
          'retrying fetch once before failing.');
      await _fetchOfferings();
      pkg = _resolveSelectedPackage();
    }

    if (pkg == null) {
      debugPrint('[RevenueCat] purchase() aborted — no package resolved for '
          'plan "${selectedPlan.value}" (offeringsLoaded=$_offeringsLoaded). '
          'See earlier [RevenueCat] logs for why offerings failed to load.');
      Get.snackbar(
        'Not Available',
        'Subscription products are loading. Please try again shortly.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    isPurchasing.value = true;
    try {
      final info = await _service.purchasePackage(pkg);
      await _handlePurchaseResult(info, isRestore: false);
    } on PlatformException catch (e) {
      if (!_service.isCancellation(e)) {
        Get.snackbar(
          'Purchase Failed',
          'Something went wrong. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } finally {
      isPurchasing.value = false;
    }
  }

  // Shared post-purchase/post-restore entitlement handling.
  //
  // 1. Checks the CustomerInfo returned by the purchase/restore call itself
  //    — on device/production this is normally already up to date.
  // 2. If the entitlement isn't active there yet (RevenueCat's backend can
  //    still be finishing receipt processing — common in sandbox, occasional
  //    on device), makes exactly ONE getCustomerInfo() fallback call, bounded
  //    by an 8s timeout. This never waits indefinitely: the fallback either
  //    resolves, times out, or errors, and every path continues immediately.
  // 3. The passive _onCustomerInfoUpdate listener (registered at startup)
  //    remains as a final backstop for confirmations that arrive even later
  //    — but nothing in this method blocks waiting on it.
  Future<void> _handlePurchaseResult(
    CustomerInfo info, {
    required bool isRestore,
  }) async {
    final action = isRestore ? 'restore' : 'purchase';

    if (_service.isActiveFromInfo(info)) {
      debugPrint('[RevenueCat] entitlement active immediately in $action result.');
      await _activatePro(isRestore: isRestore);
      return;
    }

    debugPrint('[RevenueCat] entitlement not active in $action result — '
        'trying one getCustomerInfo() fallback (8s timeout).');
    try {
      final refreshed =
          await _service.getCustomerInfo().timeout(const Duration(seconds: 8));
      if (_service.isActiveFromInfo(refreshed)) {
        debugPrint('[RevenueCat] entitlement confirmed via fallback fetch.');
        await _activatePro(isRestore: isRestore);
        return;
      }
      debugPrint('[RevenueCat] entitlement still not active after fallback fetch.');
    } on TimeoutException {
      debugPrint('[RevenueCat] getCustomerInfo() fallback timed out after '
          '8s — not waiting any longer.');
    } catch (e) {
      debugPrint('[RevenueCat] getCustomerInfo() fallback failed: $e');
    }

    if (isRestore) {
      // Stay on the paywall — nothing to activate, let the user try again.
      Get.snackbar(
        'No Purchases Found',
        'No active subscription found for this account.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } else {
      // Close the paywall regardless — the store already accepted the
      // transaction. The _onCustomerInfoUpdate listener will handle the
      // final unlock whenever RevenueCat's backend catches up.
      Get.back();
      Get.snackbar(
        'Activating subscription…',
        'Your Pro access is being confirmed and will unlock shortly.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  Future<void> _activatePro({required bool isRestore}) async {
    status.value = SubscriptionStatus.pro;
    await _persistProStatus(true);
    Get.back();
    _showProWelcome(isRestore: isRestore);
  }

  Future<void> restorePurchases() async {
    if (!_sdkReady) {
      debugPrint('[RevenueCat] restorePurchases() aborted — SDK was never '
          'configured (missing/invalid API key). Not calling any '
          'Purchases.* API.');
      Get.snackbar(
        'Restore Failed',
        'Unable to restore purchases. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    isRestoring.value = true;
    try {
      final info = await _service.restorePurchases();
      await _handlePurchaseResult(info, isRestore: true);
    } catch (e) {
      debugPrint('[RevenueCat] restorePurchases() failed: $e');
      Get.snackbar(
        'Restore Failed',
        'Unable to restore purchases. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isRestoring.value = false;
    }
  }

  void _showProWelcome({bool isRestore = false}) {
    Get.snackbar(
      isRestore ? 'Purchases Restored' : 'Welcome to NutraFlow Pro!',
      isRestore
          ? 'Your Pro subscription has been restored.'
          : 'All features are now unlocked. Enjoy!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // ── Gating helpers ─────────────────────────────────────────────────────────

  // If entitlement status is still loading (e.g. right at app launch, before
  // RevenueCat/Firestore have responded), waits briefly for it to resolve
  // instead of letting callers treat "loading" as "not entitled". This is
  // the fix for Pro users occasionally seeing the paywall again: previously
  // a gate checked right after launch could catch status mid-flight and
  // wrongly conclude the user wasn't subscribed. Bounded so a slow/failed
  // network never hangs the UI — _initialize()'s own fallback-to-cache path
  // typically resolves status well within this window anyway.
  Future<void> _awaitStatusResolved({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (status.value != SubscriptionStatus.loading) return;
    try {
      await status.stream
          .firstWhere((s) => s != SubscriptionStatus.loading)
          .timeout(timeout);
    } catch (_) {
      // Timed out (or the stream closed) — proceed with whatever status
      // is currently set rather than waiting any longer.
    }
  }

  Future<bool> requirePro() async {
    await _awaitStatusResolved();
    if (isPro) return true;
    Get.toNamed(AppRoutes.paywall);
    return false;
  }

  Future<bool> requireMealAccess() async {
    await _awaitStatusResolved();
    if (canLogMeal) return true;
    Get.toNamed(AppRoutes.paywall);
    return false;
  }
}
