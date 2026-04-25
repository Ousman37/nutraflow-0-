import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../../onboarding/models/onboarding_data.dart';
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

  Future<void> _handleAuthChange(User? user) async {
    try {
      if (user == null) {
        userProfile.value = null;
        Get.offAllNamed(AppRoutes.welcome);
        return;
      }

      // Reload to get the latest emailVerified state from Firebase
      await user.reload();
      final refreshed = _authService.currentUser;
      if (refreshed == null || !refreshed.emailVerified) {
        Get.offAllNamed(AppRoutes.verifyEmail,
            arguments: {'email': user.email ?? ''});
        return;
      }

      final profile = await _firestoreService.getUserProfile(refreshed.uid);
      userProfile.value = profile;
      if (profile == null) {
        Get.offAllNamed(AppRoutes.onboarding,
            arguments: {
              'uid': refreshed.uid,
              'name': refreshed.displayName ?? '',
              'email': refreshed.email ?? '',
            });
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (_) {
      Get.offAllNamed(AppRoutes.login);
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
      Get.snackbar('Sign In Failed', _authErrorMessage(e.code),
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
      Get.snackbar('Sign Up Failed', _authErrorMessage(e.code),
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
    } catch (_) {
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
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
