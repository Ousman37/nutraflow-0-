import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../subscription_config.dart';
import '../services/subscription_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';

enum SubscriptionStatus { loading, free, pro }

class SubscriptionController extends GetxController {
  final _service = SubscriptionService();
  final _authController = Get.find<AuthController>();

  final Rx<SubscriptionStatus> status = SubscriptionStatus.loading.obs;
  final RxInt freeAnalysesUsed = 0.obs;
  final RxBool isPurchasing = false.obs;
  final RxBool isRestoring = false.obs;
  final Rx<Package?> monthlyPackage = Rx<Package?>(null);
  final Rx<Package?> yearlyPackage = Rx<Package?>(null);
  final Rx<Package?> lifetimePackage = Rx<Package?>(null);
  final RxString monthlyPriceString = r'$9.99/mo'.obs;
  final RxString yearlyPriceString = r'$59.99/yr'.obs;
  // Which plan is selected on the paywall: 'monthly' or 'yearly'
  final RxString selectedPlan = 'yearly'.obs;

  // Alias used by the purchase button — whichever plan is selected.
  String get priceString => selectedPlan.value == 'yearly'
      ? yearlyPriceString.value
      : monthlyPriceString.value;

  bool _sdkReady = false;

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

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    try {
      await SubscriptionService.initializeSdk();
      _sdkReady = true;
      await _loadFreeAnalysesUsed();

      final uid = _authController.currentUserId;
      if (uid.isNotEmpty) {
        await _loginAndRefresh(uid);
      } else {
        status.value = SubscriptionStatus.free;
      }

      _fetchOfferings(); // fire-and-forget
    } catch (_) {
      status.value = SubscriptionStatus.free;
    }
  }

  Future<void> _loginAndRefresh(String uid) async {
    try {
      final info = await _service.logIn(uid);
      status.value = _service.isActiveFromInfo(info)
          ? SubscriptionStatus.pro
          : SubscriptionStatus.free;
    } catch (_) {
      // Network failure → fail open so paying users aren't blocked
      if (status.value == SubscriptionStatus.loading) {
        status.value = SubscriptionStatus.free;
      }
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

  // ── Free-trial tracking ────────────────────────────────────────────────────

  Future<void> _loadFreeAnalysesUsed() async {
    final prefs = await SharedPreferences.getInstance();
    freeAnalysesUsed.value =
        prefs.getInt(SubscriptionConfig.freeLogsPrefsKey) ?? 0;
  }

  // Call after each successful AI meal analysis (not after save).
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
      if (_service.isActiveFromInfo(info)) {
        status.value = SubscriptionStatus.pro;
        Get.back();
        Get.snackbar(
          'Welcome to NutraFlow Pro!',
          'All features are now unlocked. Enjoy!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
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
        Get.back();
        Get.snackbar(
          'Purchases Restored',
          'Your Pro subscription has been restored.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
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

  // ── Gating helpers ─────────────────────────────────────────────────────────

  // Use for Pro-only features (Journal, Progress). Returns true if subscribed.
  bool requirePro() {
    if (isPro) return true;
    Get.toNamed(AppRoutes.paywall);
    return false;
  }

  // Use for meal analysis. Returns true if subscribed OR free trial remains.
  bool requireMealAccess() {
    if (canLogMeal) return true;
    Get.toNamed(AppRoutes.paywall);
    return false;
  }
}
