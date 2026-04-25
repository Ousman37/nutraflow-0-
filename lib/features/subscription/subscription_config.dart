// ─────────────────────────────────────────────────────────────────────────────
// RevenueCat configuration
//
// Setup checklist:
//   1. Create a project in app.revenuecat.com
//   2. Add your iOS app (App Store Connect) and Android app (Google Play)
//   3. Create products in App Store Connect / Google Play console
//   4. Create an entitlement in RevenueCat → the ID must match [entitlementId]
//   5. Create an offering named "default" with monthly + annual packages
//   6. Replace the API key placeholders below with your actual keys
//
// ⚠️  [entitlementId] is CASE-SENSITIVE and must exactly match the RevenueCat
//     dashboard value (RevenueCat → Entitlements → Identifier).
//     Current value: 'nutraflow Pro'  — verify this matches your dashboard.
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionConfig {
  // RevenueCat public SDK keys — app.revenuecat.com → Project → Apps → API Keys
  static const iosApiKey = 'test_gEMJkzUIcoXvVFHMBRrsbPuPgJN';
  static const androidApiKey = 'test_gEMJkzUIcoXvVFHMBRrsbPuPgJN';

  // Must exactly match the entitlement Identifier in RevenueCat dashboard
  static const entitlementId = 'nutraflow Pro';

  // In-app free tier: number of complete meal logs before subscription required
  static const freeLogLimit = 3;

  // SharedPreferences keys
  static const freeLogsPrefsKey = 'nf_free_logs_used';
  // Cached pro flag — used as a fallback when RevenueCat is unreachable
  static const proStatusPrefsKey = 'nf_is_pro_user';
}
