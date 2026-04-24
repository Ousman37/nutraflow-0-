import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../subscription_config.dart';

class SubscriptionService {
  // Call once at startup — only initializes the SDK, no user linked yet.
  static Future<void> initializeSdk() async {
    final apiKey = Platform.isIOS
        ? SubscriptionConfig.iosApiKey
        : SubscriptionConfig.androidApiKey;

    // Remove or guard this with kDebugMode in production.
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));
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
    return info.entitlements.active.containsKey(SubscriptionConfig.entitlementId);
  }

  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  // Returns the current RevenueCat offering, or null if unavailable.
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  // Initiates a purchase. Throws PlatformException if it fails or is cancelled.
  Future<CustomerInfo> purchasePackage(Package package) =>
      Purchases.purchasePackage(package);

  // Restores previous purchases (App Store / Play Store).
  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();

  bool isActiveFromInfo(CustomerInfo info) =>
      info.entitlements.active.containsKey(SubscriptionConfig.entitlementId);

  // True when the user cancelled the purchase sheet — no error should be shown.
  bool isCancellation(PlatformException e) {
    try {
      final code = PurchasesErrorHelper.getErrorCode(e);
      return code == PurchasesErrorCode.purchaseCancelledError;
    } catch (_) {
      return false;
    }
  }
}
