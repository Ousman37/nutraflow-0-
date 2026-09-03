import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../../onboarding/models/onboarding_data.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../../core/utils/calorie_calculator.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserProfileModel?> userProfile = Rx<UserProfileModel?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    try {
      firebaseUser.bindStream(_authService.authStateChanges);
      ever(firebaseUser, _handleAuthChange);
    } catch (_) {
      // Firebase not connected — go straight to welcome for UI preview
      Future.microtask(() => Get.offAllNamed(AppRoutes.welcome));
    }
  }

  // Every stage below is deliberately its own try/catch. A downstream
  // failure (Firestore unreachable, RevenueCat unreachable, etc.) must
  // NEVER be indistinguishable from an actual authentication failure — that
  // was the root cause behind a real App Store rejection (Guideline
  // 2.1(a), "sign in failed"): any exception anywhere in this method used
  // to fall through to one catch-all that silently bounced the user back to
  // the login screen with zero explanation, even though Firebase Auth
  // itself had already succeeded. See enterMainApp() and the two try/catch
  // blocks below for how each stage now fails open instead.
  Future<void> _handleAuthChange(User? user) async {
    if (user == null) {
      userProfile.value = null;
      if (Get.currentRoute != AppRoutes.welcome) {
        Get.offAllNamed(AppRoutes.welcome);
      }
      return;
    }

    // Stage 1 — confirm the session itself is still valid, and get the
    // current email-verification state. This is the ONLY stage where an
    // error can legitimately mean "not signed in" — everything after this
    // point already knows the user has a valid Firebase session.
    User? refreshed;
    try {
      await user.reload();
      refreshed = _authService.currentUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] user.reload() failed: ${e.code} — ${e.message}');
      if (e.code == 'user-token-expired' ||
          e.code == 'user-disabled' ||
          e.code == 'user-not-found') {
        // The session really is dead — sign out cleanly and send them to
        // login (with nothing left to retry).
        await _authService.signOut();
        Get.offAllNamed(AppRoutes.login);
      }
      // Anything else (e.g. network-request-failed) is transient — leave
      // the user exactly where they are. The auth stream re-fires on the
      // next successful check, and nothing here misrepresents this as a
      // failed sign-in.
      return;
    } catch (e) {
      debugPrint('[Auth] user.reload() failed with unexpected error: $e');
      return;
    }

    if (refreshed == null || !refreshed.emailVerified) {
      if (Get.currentRoute != AppRoutes.verifyEmail) {
        Get.offAllNamed(AppRoutes.verifyEmail,
            arguments: {'email': user.email ?? ''});
      }
      return;
    }

    // Never interrupt an active onboarding or post-onboarding motivation flow.
    // The user is filling in their profile — disposing the controller here
    // causes "TextEditingController used after disposed" errors.
    if (Get.currentRoute == AppRoutes.onboarding ||
        Get.currentRoute == AppRoutes.motivation) {
      return;
    }

    // Stage 2 — load the Firestore profile. The user IS authenticated by
    // this point, so a failure here is a data-loading problem, never an
    // auth problem — it must not route back to login. Distinguish a clean
    // "no document" (genuinely new user → onboarding) from "the read
    // itself failed" (network/permission error → fail open into the app
    // rather than wrongly re-onboarding an existing user, or getting stuck).
    UserProfileModel? profile;
    try {
      profile = await _firestoreService.getUserProfile(refreshed.uid);
    } catch (e) {
      debugPrint('[Auth] Firestore profile load failed for '
          '${refreshed.uid}: $e');
      await enterMainApp();
      return;
    }

    userProfile.value = profile;
    if (profile == null) {
      Get.offAllNamed(AppRoutes.onboarding, arguments: {
        'uid': refreshed.uid,
        'name': refreshed.displayName ?? '',
        'email': refreshed.email ?? '',
      });
    } else {
      await enterMainApp();
    }
  }

  // The single gate every path into the main app must go through — called
  // here after login/resume, and from the onboarding-complete CTA
  // (motivation_view.dart). Decides Home vs. the subscription paywall based
  // on live RevenueCat entitlement state (never a stale local boolean).
  // `Get.currentRoute != target` avoids an unnecessary rebuild/flash when
  // this is called while already on the correct screen (e.g. a redundant
  // auth-stream re-emission while the user is mid-session).
  Future<void> enterMainApp() async {
    bool hasAccess;
    try {
      hasAccess = Get.isRegistered<SubscriptionController>()
          ? await Get.find<SubscriptionController>().hasActiveAccess()
          : true;
    } catch (e) {
      // A RevenueCat/subscription-check failure must never masquerade as a
      // failed sign-in — fail open into the app rather than block it.
      debugPrint('[Auth] Entitlement check failed, entering app anyway '
          'rather than blocking a successful login: $e');
      hasAccess = true;
    }
    final target = hasAccess ? AppRoutes.home : AppRoutes.paywall;
    if (Get.currentRoute != target) {
      Get.offAllNamed(target);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      await _authService.signInWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] signIn FirebaseAuthException: ${e.code} — ${e.message}');
      Get.snackbar('Sign In Failed', _authErrorMessage(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      // Anything that isn't a FirebaseAuthException (e.g. Firebase not
      // configured/initialized) must still surface something to the user
      // instead of silently doing nothing.
      debugPrint('[Auth] signIn unexpected error: $e');
      Get.snackbar('Sign In Failed',
          'Something went wrong. Please check your connection and try again.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      final cred = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );
      await _authService.updateDisplayName(name);
      await _authService.sendEmailVerification();
      userProfile.value = null;
      Get.offAllNamed(
        AppRoutes.verifyEmail,
        arguments: {'uid': cred.user!.uid, 'name': name, 'email': email},
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] signUp FirebaseAuthException: ${e.code} — ${e.message}');
      Get.snackbar('Sign Up Failed', _authErrorMessage(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('[Auth] signUp unexpected error: $e');
      Get.snackbar('Sign Up Failed',
          'Something went wrong. Please check your connection and try again.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required int age,
    required double heightCm,
    required double weightKg,
    required String gender,
    required FitnessGoal goal,
    required ActivityLevel activityLevel,
    required List<String> dietaryPreferences,
  }) async {
    final bmr = CalorieCalculator.calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );
    final tdee = CalorieCalculator.calculateTDEE(
      bmr: bmr,
      activityLevel: activityLevel,
    );
    final dailyCalories = CalorieCalculator.calculateDailyCalories(
      tdee: tdee,
      goal: goal,
    );
    final macros = CalorieCalculator.calculateMacros(dailyCalories);

    final profile = UserProfileModel(
      id: uid,
      name: name,
      email: email,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      gender: gender,
      goal: goal,
      activityLevel: activityLevel,
      dietaryPreferences: dietaryPreferences,
      dailyCalorieTarget: dailyCalories,
      macroTargets: macros,
      createdAt: DateTime.now(),
    );

    await _firestoreService.saveUserProfile(profile);
    userProfile.value = profile;
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      isLoading.value = true;
      await _authService.sendPasswordResetEmail(email);
      Get.snackbar(
        'Email Sent',
        'Password reset link sent to $email',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] sendPasswordReset FirebaseAuthException: '
          '${e.code} — ${e.message}');
      Get.snackbar('Failed', _authErrorMessage(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
      Get.snackbar(
        'Sent',
        'Verification email resent. Check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] resendVerificationEmail FirebaseAuthException: '
          '${e.code} — ${e.message}');
      Get.snackbar('Error', _authErrorMessage(e.code),
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('[Auth] resendVerificationEmail unexpected error: $e');
      Get.snackbar('Error', 'Could not resend verification email.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> checkEmailVerification({bool silent = false}) async {
    await _authService.reloadUser();
    final user = _authService.currentUser;
    if (user != null && user.emailVerified) {
      await _handleAuthChange(user);
    } else if (!silent) {
      Get.snackbar(
        'Not Verified',
        'Email not verified yet. Check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
  }

  String get currentUserId =>
      _authService.currentUserId ?? firebaseUser.value?.uid ?? '';

  String get currentUserName =>
      userProfile.value?.name ??
      firebaseUser.value?.displayName ??
      'Friend';

  String _authErrorMessage(String code) {
    switch (code) {
      // Modern Firebase Auth versions return 'invalid-credential' for both
      // a wrong password AND an unregistered email, to avoid leaking which
      // one it was — 'user-not-found'/'wrong-password' are kept below for
      // older SDK behavior, but 'invalid-credential' is the one actually
      // seen in current sign-in failures.
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is currently unavailable. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
