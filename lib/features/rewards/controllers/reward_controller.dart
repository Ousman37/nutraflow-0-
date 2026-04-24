import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/reward_model.dart';
import '../services/reward_service.dart';
import '../widgets/reward_unlocked_modal.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../progress/services/streak_service.dart';

class RewardController extends GetxController {
  final _service = RewardService();
  final _authController = Get.find<AuthController>();

  final RxList<RewardModel> rewards = <RewardModel>[].obs;
  final RxInt currentStreak = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever<User?>(_authController.firebaseUser, _onAuthChanged);
    final uid = _authController.currentUserId;
    if (uid.isNotEmpty) _loadRewards(uid);
  }

  void _onAuthChanged(User? user) {
    if (user == null) {
      rewards.clear();
      currentStreak.value = 0;
    } else if (user.emailVerified) {
      _loadRewards(user.uid);
    }
  }

  Future<void> _loadRewards(String uid) async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _service.loadRewards(uid),
        StreakService().loadStreak(uid),
      ]);
      rewards.value = results[0] as List<RewardModel>;
      currentStreak.value = (results[1] as StreakData).streakCount;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  // Called by AddMealController after streak update completes.
  Future<void> checkForNewRewards(int streakCount) async {
    final uid = _authController.currentUserId;
    if (uid.isEmpty) return;
    currentStreak.value = streakCount;

    try {
      final unlocked = await _service.checkAndUnlock(uid, streakCount);
      if (unlocked.isNotEmpty) {
        final fresh = await _service.loadRewards(uid);
        rewards.value = fresh;
        for (final r in unlocked) {
          await _showUnlockModal(r);
        }
      }
    } catch (_) {}
  }

  Future<void> _showUnlockModal(RewardModel reward) async {
    await Get.dialog<void>(
      RewardUnlockedModal(reward: reward),
      barrierDismissible: false,
    );
  }

  RewardModel? get nextMilestone {
    final locked = rewards.where((r) => !r.isUnlocked).toList()
      ..sort((a, b) => a.milestoneDays.compareTo(b.milestoneDays));
    return locked.isEmpty ? null : locked.first;
  }

  int get unlockedCount => rewards.where((r) => r.isUnlocked).length;
}
