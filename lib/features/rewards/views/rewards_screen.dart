import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/reward_controller.dart';
import '../models/reward_model.dart';
import '../../../core/constants/app_colors.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<RewardController>();
    return Scaffold(
      backgroundColor: const Color(0xFF080F26),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(),
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    _StreakSummary(ctrl: ctrl),
                    const SizedBox(height: 24),
                    Text(
                      'YOUR MILESTONES',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white38,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...ctrl.rewards.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BadgeCard(
                          reward: r,
                          currentStreak: ctrl.currentStreak.value,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Get.back<void>(),
          ),
          Expanded(
            child: Text(
              'Rewards',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakSummary extends StatelessWidget {
  final RewardController ctrl;
  const _StreakSummary({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2048), Color(0xFF0E1530)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _StatCell(
            label: 'Current Streak',
            value: '${ctrl.currentStreak.value}',
            unit: 'days',
            emoji: '🔥',
          ),
          Container(width: 1, height: 44, color: Colors.white12),
          _StatCell(
            label: 'Unlocked',
            value: '${ctrl.unlockedCount}',
            unit: 'of ${ctrl.rewards.length}',
            emoji: '🏅',
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String emoji;

  const _StatCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final RewardModel reward;
  final int currentStreak;

  const _BadgeCard({required this.reward, required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    final info = reward.info;
    final isUnlocked = reward.isUnlocked;
    final fraction = reward.progressFraction(currentStreak);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFF111A38)
            : const Color(0xFF0C1228),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked
              ? info.color1.withValues(alpha: 0.35)
              : Colors.white10,
          width: isUnlocked ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          _BadgeIcon(info: info, isUnlocked: isUnlocked),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        info.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? Colors.white : Colors.white60,
                        ),
                      ),
                    ),
                    if (isUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: info.color1.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Unlocked',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: info.color1,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  info.description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white38,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isUnlocked) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 5,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(info.color1),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _progressLabel(currentStreak),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ] else if (reward.unlockedAt != null) ...[
                  Text(
                    'Achieved ${DateFormat('d MMM yyyy').format(reward.unlockedAt!)}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: info.color1.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _progressLabel(int streak) {
    final left = reward.daysRemaining(streak);
    if (left == 0) return 'Unlocking…';
    return '$streak / ${reward.milestoneDays} days  •  $left to go';
  }
}

class _BadgeIcon extends StatelessWidget {
  final MilestoneInfo info;
  final bool isUnlocked;

  const _BadgeIcon({required this.info, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                colors: info.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUnlocked ? null : Colors.white10,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: info.color1.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          info.emoji,
          style: TextStyle(
            fontSize: 26,
            color: isUnlocked ? null : Colors.white.withValues(alpha: 0.25),
          ),
        ),
      ),
    );
  }
}
