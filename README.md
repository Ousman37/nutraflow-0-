<div align="center">

# NutraFlow

**Your AI-powered nutrition companion — track meals, build habits, and reach your goals.**

<br/>

![App Preview](assets/images/preview_placeholder.png)

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![iOS](https://img.shields.io/badge/iOS-14.0+-000000?style=flat&logo=apple&logoColor=white)](https://developer.apple.com)
[![Android](https://img.shields.io/badge/Android-6.0+-3DDC84?style=flat&logo=android&logoColor=white)](https://developer.android.com)
[![Firebase](https://img.shields.io/badge/Firebase-powered-FFCA28?style=flat&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen?style=flat)](https://github.com)

</div>

---

## Overview

NutraFlow is a mobile-first nutrition and wellness app that combines meal tracking, workout logging, and AI-powered insights into a single, cohesive experience. Rather than overwhelming users with raw data, NutraFlow translates daily habits into actionable feedback — surfacing patterns, rewarding consistency, and adapting to each person's goals.

**The problem:** Most nutrition apps are either too complex (spreadsheet-level detail) or too shallow (basic calorie counters). Users drop off because the experience doesn't evolve with them.

**The solution:** NutraFlow meets users where they are. Onboarding is opinionated. Tracking is fast. Insights feel personal. And a built-in rewards system keeps the streak alive.

**Who it's for:** Health-conscious individuals who want more than a calorie counter — people who are building a lifestyle, not just logging meals.

---

## Features

### Meal Tracking
Log breakfast, lunch, dinner, and snacks with a streamlined entry flow. Search foods, scan barcodes, and build a personal food library over time.

### AI Nutrition Insights
Get daily and weekly nutrition breakdowns with AI-generated observations. Understand which meals serve your goals and which don't — without needing a nutritionist.

### Workout Tracking
Log workouts alongside meals to get a full picture of your energy balance. Supports cardio, strength, and custom sessions.

### Progress & Streak System
Track weight, body metrics, and nutrition trends over time with visual charts. A daily streak system keeps momentum going — every logged day counts.

### Rewards & Habit Engine
Earn points and unlock milestones as you build consistent habits. The rewards layer turns routine tracking into a long-term commitment.

### Personalized Onboarding
Goal-based onboarding (weight loss, muscle gain, maintenance) shapes the app experience from day one — macros, targets, and suggestions adapt accordingly.

### Subscription Access
Premium features are gated behind a clean, conversion-optimized paywall. Powered by RevenueCat for cross-platform subscription management.

---

## Screenshots

> Screenshots coming soon. The sections below correspond to the main screens in the app.

| Home | Meals | AI Insights |
|------|-------|-------------|
| ![Home](assets/images/screenshot_home.png) | ![Meals](assets/images/screenshot_meals.png) | ![Insights](assets/images/screenshot_insights.png) |

| Workouts | Progress |
|----------|----------|
| ![Workouts](assets/images/screenshot_workouts.png) | ![Progress](assets/images/screenshot_progress.png) |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart 3.11+) |
| State Management | GetX |
| Authentication | Firebase Auth |
| Database | Cloud Firestore |
| File Storage | Firebase Storage |
| Subscriptions | RevenueCat (`purchases_flutter`) |
| Charts | fl_chart |
| Fonts | Plus Jakarta Sans (Google Fonts) |
| Icons | Phosphor Icons |
| Image Handling | image_picker + cached_network_image |
| Persistence | shared_preferences |
| Platforms | iOS 14.0+ · Android 6.0+ |

---

## Project Structure

The codebase follows a feature-first architecture. Each feature is self-contained with its own controllers, views, models, and services.

```
lib/
├── core/
│   ├── constants/       # App-wide constants (colors, strings, config)
│   ├── theme/           # Global theme, typography, design tokens
│   ├── utils/           # Helpers, extensions, formatters
│   └── widgets/         # Shared UI components
│
├── features/
│   ├── auth/            # Sign in, sign up, session management
│   ├── onboarding/      # Goal setup, personalization flow
│   ├── home/            # Dashboard and daily summary
│   ├── meals/           # Meal list, logging, food search
│   ├── meal/            # Individual meal detail and editing
│   ├── scanner/         # Barcode scanner for food lookup
│   ├── workouts/        # Workout logging and history
│   ├── journal/         # Daily notes and reflections
│   ├── progress/        # Charts, body metrics, trends
│   ├── rewards/         # Streak tracking and milestones
│   ├── analytics/       # AI insights and nutrition analysis
│   ├── subscription/    # Paywall and plan management
│   ├── profile/         # User settings and preferences
│   └── welcome/         # Splash and welcome screens
│
└── routes/              # Named route definitions (GetX routing)
```

Each feature module typically contains:

```
feature/
├── controllers/   # GetX controllers (business logic)
├── views/         # Screens and pages
├── models/        # Data models
├── services/      # API calls, Firestore queries
└── widgets/       # Feature-specific UI components
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.x`
- Dart SDK `>=3.11.5`
- A Firebase project with Auth and Firestore enabled
- Xcode (for iOS builds) / Android Studio (for Android builds)

### 1. Clone the repository

```bash
git clone https://github.com/your-username/nutraflow.git
cd nutraflow
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Place your Firebase configuration files in the appropriate locations:

- iOS: `ios/Runner/GoogleService-Info.plist`
- Android: `android/app/google-services.json`

If you use the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Configure RevenueCat (optional)

Set your RevenueCat API keys in the subscription service before running. Without this, the paywall will not function but the rest of the app will work normally.

### 5. Run the app

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

---

## App Store / Deployment

### iOS Build

```bash
flutter build ipa --release
```

The resulting `.ipa` is found at `build/ios/ipa/`. Upload via Xcode Organizer or Transporter.

### iOS Configuration Checklist

- [ ] Bundle ID set in `ios/Runner.xcodeproj`
- [ ] Signing certificates and provisioning profiles configured in Xcode
- [ ] `GoogleService-Info.plist` added to the Runner target
- [ ] Build number incremented in `pubspec.yaml` (`version: 1.0.0+N`)
- [ ] App icon and launch screen assets in place

### Android Build

```bash
flutter build appbundle --release
```

Upload the `.aab` to Google Play Console.

---

## Roadmap

The following improvements are planned for upcoming releases:

- **Barcode scanner improvements** — expand food database coverage and offline caching
- **AI meal photo analysis** — log a meal by taking a photo instead of searching
- **Apple Health / Google Fit integration** — sync steps and active calories automatically
- **Social streaks** — compare progress with friends and stay accountable together
- **Widget support** — quick-log meals and view daily summary from the home screen
- **Localization** — multi-language support starting with Spanish and French
- **Android subscription parity** — full RevenueCat Android paywall integration

---

## Author

NutraFlow is built and maintained by a solo developer with a focus on building tools that actually change behavior — not just track it.

The vision behind NutraFlow is simple: health apps should feel like a coach, not a spreadsheet. Every design and engineering decision is made with that in mind — from the onboarding flow to the rewards system to the way insights are surfaced.

If you have feedback, feature requests, or want to collaborate, feel free to open an issue or reach out directly.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">
  Built with Flutter · Powered by Firebase · Designed for real people
</div>
