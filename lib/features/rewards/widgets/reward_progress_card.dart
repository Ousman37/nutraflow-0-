import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/reward_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class RewardProgressCard extends StatelessWidget {
  const RewardProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<RewardController>()) return const SizedBox.shrink();
    final ctrl = Get.find<RewardController>();

    return Obx(() {
      final streak = ctrl.currentStreak.value;
      final next = ctrl.nextMilestone;

      if (next == null && streak == 0) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.rewards),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0E1530), Color(0xFF1A2048)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _StreakBadge(streak: streak),
              const SizedBox(width: 14),
              Expanded(child: _ProgressInfo(streak: streak, next: next)),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
                size: 20,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB443), Color(0xFFFF6B9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB443).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 18)),
          Text(
            '$streak',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressInfo extends StatelessWidget {
  final int streak;
  final dynamic next; // RewardModel?

  const _ProgressInfo({required this.streak, required this.next});

  @override
  Widget build(BuildContext context) {
    if (next == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All milestones unlocked! 🏆',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$streak day streak — you\'re unstoppable',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white54,
            ),
          ),
        ],
      );
    }

    final info = next.info;
    final fraction = next.progressFraction(streak) as double;
    final daysLeft = next.daysRemaining(streak) as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              info.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                info.title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 5,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(info.color1),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          daysLeft == 0
              ? 'Unlocking now…'
              : '$daysLeft day${daysLeft == 1 ? '' : 's'} to go',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}
