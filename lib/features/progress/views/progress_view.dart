import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../controllers/progress_controller.dart';
import '../../../core/constants/app_colors.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ProgressController());
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _ProgressHeader(),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              return RefreshIndicator(
                onRefresh: ctrl.loadData,
                color: AppColors.primary,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20, 16, 20,
                    MediaQuery.of(context).padding.bottom + 96,
                  ),
                  children: [
                    _StreakCard(ctrl: ctrl),
                    const SizedBox(height: 16),
                    _WeeklyStatsCard(ctrl: ctrl),
                    const SizedBox(height: 16),
                    _CaloriesChart(ctrl: ctrl),
                    const SizedBox(height: 16),
                    _NutritionCard(ctrl: ctrl),
                    const SizedBox(height: 16),
                    _AIInsightCard(ctrl: ctrl),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final ctrl = Get.find<ProgressController>();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.dashboardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -24,
            right: 120,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Text + summary chips
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 20, 160, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This week at a glance',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() => Row(
                  children: [
                    _HeaderChip(
                      icon: PhosphorIcons.flame(PhosphorIconsStyle.fill),
                      label:
                          '${ctrl.currentStreak.value} day streak',
                      color: const Color(0xFFF5A623),
                    ),
                    const SizedBox(width: 8),
                    _HeaderChip(
                      icon: PhosphorIcons.barbell(),
                      label: '${ctrl.totalWorkoutMinutes} min',
                      color: AppColors.secondary,
                    ),
                  ],
                )),
              ],
            ),
          ),

          // Character — starts below status bar so head is never clipped
          Positioned(
            right: 0,
            bottom: 0,
            top: topPad,
            child: Image.asset(
              'assets/images/meal_character.png',
              width: 152,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stack) => SizedBox(
                width: 152,
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.personSimpleRun(),
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final Color color;

  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streak card ───────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final ProgressController ctrl;
  const _StreakCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final streak = ctrl.currentStreak.value;
      final longest = ctrl.longestStreak.value;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0E1530), Color(0xFF1A2048)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Streak',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PhosphorIcon(PhosphorIcons.flame(), size: 28, color: Color(0xFFF5A623)),
                      const SizedBox(width: 8),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          streak == 1 ? 'day' : 'days',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Personal Best',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$longest days',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF5A623),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ── Weekly stats ──────────────────────────────────────────────────────────────

class _WeeklyStatsCard extends StatelessWidget {
  final ProgressController ctrl;
  const _WeeklyStatsCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Week',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _WeekStat(
                  icon: PhosphorIcons.calendarCheck(),
                  label: 'Days Tracked',
                  value: '${ctrl.mealDaysLogged}',
                  unit: '/ 7',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                _WeekStat(
                  icon: PhosphorIcons.barbell(),
                  label: 'Workout Time',
                  value: '${ctrl.totalWorkoutMinutes}',
                  unit: 'min',
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                _WeekStat(
                  icon: PhosphorIcons.flame(),
                  label: 'Kcal Burned',
                  value: '${ctrl.totalCaloriesBurned.round()}',
                  unit: 'kcal',
                  color: AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _WeekStat extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _WeekStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            PhosphorIcon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Calories bar chart ────────────────────────────────────────────────────────

class _CaloriesChart extends StatelessWidget {
  final ProgressController ctrl;
  const _CaloriesChart({required this.ctrl});

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final data = ctrl.caloriesPerWeekday;
      final max = data.reduce((a, b) => a > b ? a : b);
      final todayIdx = DateTime.now().weekday - 1;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calories This Week',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final val = data[i];
                  final frac = max > 0 ? val / max : 0.0;
                  final isToday = i == todayIdx;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (val > 0)
                            Text(
                              '${val.round()}',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: isToday
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 3),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            height: 70 * frac.clamp(0.04, 1.0),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _days[i],
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Nutrition averages ────────────────────────────────────────────────────────

class _NutritionCard extends StatelessWidget {
  final ProgressController ctrl;
  const _NutritionCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cals = ctrl.avgCaloriesPerDay;
      final protein = ctrl.avgProteinPerDay;
      if (cals == 0) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Averages',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            _AverageRow(
              label: 'Calories',
              value: '${cals.round()} kcal',
              color: AppColors.primary,
              progress: (cals / 2000).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 10),
            _AverageRow(
              label: 'Protein',
              value: '${protein.round()} g',
              color: AppColors.secondary,
              progress: (protein / 150).clamp(0.0, 1.0),
            ),
          ],
        ),
      );
    });
  }
}

class _AverageRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double progress;

  const _AverageRow({
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ── AI insight ────────────────────────────────────────────────────────────────

class _AIInsightCard extends StatelessWidget {
  final ProgressController ctrl;
  const _AIInsightCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.secondary.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: PhosphorIcon(PhosphorIcons.sparkle(), size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Weekly Insight',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ctrl.aiInsight,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    });
  }
}
