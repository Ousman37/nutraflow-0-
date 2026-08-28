// ─────────────────────────────────────────────────────────────────────────────
// RevenueCat configuration
//
// API keys are read from `.env` (gitignored — see .env.example) and are NEVER
// hardcoded here. This file must not contain a real or placeholder key value.
//
// Setup checklist:
//   1. Create a project in app.revenuecat.com
//   2. Add your iOS app (App Store Connect) and Android app (Google Play)
//   3. Create products in App Store Connect / Google Play console
//   4. Create an entitlement in RevenueCat → the ID must match [entitlementId]
//   5. Create an offering named "default" with monthly + annual packages
//   6. In your local `.env`, set:
//        REVENUECAT_IOS_API_KEY=appl_...
//        REVENUECAT_ANDROID_API_KEY=goog_...
//      Real public SDK keys only — from RevenueCat → Project → Apps → API
//      Keys. Never a "test_..." Test Store key outside a debug build; the
//      RevenueCat SDK can crash on launch if configured with one in a
//      release/TestFlight/App Store build.
//
// ⚠️  [entitlementId] is CASE-SENSITIVE and must exactly match the RevenueCat
//     dashboard value (RevenueCat → Entitlements → Identifier).
//     Current value: 'nutraflow_pro' — confirmed 2026-08-28 from a live
//     device CustomerInfo log (a real sandbox purchase showed up as
//     `active entitlements on account: (nutraflow_pro)`), which overrides
//     any earlier assumption about the dashboard's naming.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_dotenv/flutter_dotenv.dart';

class SubscriptionConfig {
  // Real public SDK keys, sourced from .env — see setup checklist above.
  static String get iosApiKey => dotenv.env['REVENUECAT_IOS_API_KEY'] ?? '';
  static String get androidApiKey =>
      dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? '';

  // Must exactly match the entitlement Identifier in RevenueCat dashboard
  static const entitlementId = 'nutraflow_pro';

  // In-app free tier: number of complete meal logs before subscription required
  static const freeLogLimit = 3;

  // SharedPreferences keys
  static const freeLogsPrefsKey = 'nf_free_logs_used';
  // Cached pro flag — used as a fallback when RevenueCat is unreachable
  static const proStatusPrefsKey = 'nf_is_pro_user';
}
