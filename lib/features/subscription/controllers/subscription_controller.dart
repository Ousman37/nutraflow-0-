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

class SubscriptionController extends GetxController {
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
  final RxString monthlyPriceString = r'$9.99/mo'.obs;
  final RxString yearlyPriceString = r'$59.99/yr'.obs;
  final RxString selectedPlan = 'yearly'.obs;

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
    _initialize();
    ever<User?>(_authController.firebaseUser, _onAuthChanged);
  }

  @override
  void onClose() {
    if (_customerInfoListener != null) {
      _service.removeCustomerInfoUpdateListener(_customerInfoListener!);
    }
    super.onClose();
  }

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    try {
      await SubscriptionService.initializeSdk();
      _sdkReady = true;

      // Wire up the listener BEFORE any login so no update is ever missed.
      // This is the key fix for sandbox: RC may confirm the entitlement async,
      // after purchasePackage() has already returned.
      _customerInfoListener = _onCustomerInfoUpdate;
      _service.addCustomerInfoUpdateListener(_customerInfoListener!);

      await _loadFreeAnalysesUsed();

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
    monthlyPriceString.value = r'$9.99/mo';
    yearlyPriceString.value = r'$59.99/yr';
  }

  Future<void> _fetchOfferings() async {
    final offerings = await _service.getOfferings();
    final current = offerings?.current;
    if (current == null) return;

    final monthly = current.monthly;
    if (monthly != null) {
      monthlyPackage.value = monthly;
      monthlyPriceString.value = monthly.storeProduct.priceString;
    }
    final yearly = current.annual;
    if (yearly != null) {
      yearlyPackage.value = yearly;
      yearlyPriceString.value = yearly.storeProduct.priceString;
    }
    lifetimePackage.value = current.lifetime;
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

  Future<void> purchase() async {
    final pkg = selectedPlan.value == 'yearly'
        ? (yearlyPackage.value ?? monthlyPackage.value)
        : monthlyPackage.value;

    if (pkg == null) {
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

      // Always close the paywall — the transaction was accepted by the store.
      Get.back();

      if (_service.isActiveFromInfo(info)) {
        // Entitlement confirmed immediately (common on device/prod)
        status.value = SubscriptionStatus.pro;
        await _persistProStatus(true);
        _showProWelcome();
      } else {
        // Store accepted the purchase but RC hasn't confirmed the entitlement
        // yet (common in sandbox). The _onCustomerInfoUpdate listener will
        // handle the final unlock — show a brief holding message.
        Get.snackbar(
          'Activating subscription…',
          'Your Pro access is being confirmed, just a moment.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
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

  Future<void> restorePurchases() async {
    isRestoring.value = true;
    try {
      final info = await _service.restorePurchases();
      if (_service.isActiveFromInfo(info)) {
        status.value = SubscriptionStatus.pro;
        await _persistProStatus(true);
        Get.back();
        _showProWelcome(isRestore: true);
      } else {
        Get.snackbar(
          'No Purchases Found',
          'No active subscription found for this account.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (_) {
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

  bool requirePro() {
    if (isPro) return true;
    Get.toNamed(AppRoutes.paywall);
    return false;
  }

  bool requireMealAccess() {
    if (canLogMeal) return true;
    Get.toNamed(AppRoutes.paywall);
    return false;
  }
}
