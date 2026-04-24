import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../features/auth/views/splash_screen.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/signup_view.dart';
import '../features/auth/views/forgot_password_view.dart';
import '../features/auth/views/verify_email_view.dart';
import '../features/onboarding/views/onboarding_view.dart';
import '../features/onboarding/views/motivation_view.dart';
import '../features/home/views/home_view.dart';
import '../features/meal/views/add_meal_view.dart';
import '../features/meal/views/meal_detail_view.dart';
import '../features/meal/views/select_method_view.dart';
import '../features/welcome/views/welcome_view.dart';
import '../features/subscription/views/paywall_view.dart';
import '../features/rewards/views/rewards_screen.dart';
import 'app_routes.dart';

// Slight slide-up + fade — used for action sheets and add-meal flows.
class _SlideUpFadeTransition extends CustomTransition {
  _SlideUpFadeTransition();

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

// Scale-up + fade — used for detail screens opened from a list.
class _ScaleFadeTransition extends CustomTransition {
  _ScaleFadeTransition();

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

abstract class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.welcome,
      page: () => const WelcomeView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.verifyEmail,
      page: () => const VerifyEmailView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.addMeal,
      page: () => const AddMealView(),
      customTransition: _SlideUpFadeTransition(),
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.selectMethod,
      page: () => const SelectMethodView(),
      customTransition: _SlideUpFadeTransition(),
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.mealDetail,
      page: () => const MealDetailView(),
      customTransition: _ScaleFadeTransition(),
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: AppRoutes.motivation,
      page: () => const MotivationView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.paywall,
      page: () => const PaywallView(),
      customTransition: _SlideUpFadeTransition(),
      transitionDuration: const Duration(milliseconds: 280),
    ),
    GetPage(
      name: AppRoutes.rewards,
      page: () => const RewardsScreen(),
      customTransition: _SlideUpFadeTransition(),
      transitionDuration: const Duration(milliseconds: 260),
    ),
  ];
}
