// ─────────────────────────────────────────────────────────────────────────────
// RevenueCat configuration
//
// Setup checklist:
//   1. Create a project in app.revenuecat.com
//   2. Add your iOS app (App Store Connect) and Android app (Google Play)
//   3. Create products in App Store Connect / Google Play:
//        iOS product ID  : nutraflow_pro_monthly
//        Android product ID: nutraflow_pro_monthly
//   4. Create an entitlement named "pro" in RevenueCat and attach the products
//   5. Create an offering named "default" with a monthly package
//   6. Replace the API key placeholders below with your actual keys
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionConfig {
  // RevenueCat API keys — find them at app.revenuecat.com → Apps → API Keys
  static const iosApiKey = 'test_gEMJkzUIcoXvVFHMBRrsbPuPgJN';
  static const androidApiKey = 'test_gEMJkzUIcoXvVFHMBRrsbPuPgJN';

  // Must exactly match the entitlement identifier in RevenueCat dashboard
  static const entitlementId = 'nutraflow Pro';

  // In-app free tier: number of complete meal logs before subscription required
  static const freeLogLimit = 3;

  // SharedPreferences key for persisting the free log count locally
  static const freeLogsPrefsKey = 'nf_free_logs_used';
}
