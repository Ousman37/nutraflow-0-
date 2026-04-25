import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../controllers/analytics_controller.dart';
import '../widgets/weekly_bar_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/helpers.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AnalyticsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: ctrl.loadWeeklyData,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progress', style: AppTextStyles.displayMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Your nutrition journey this week',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Obx(() => ctrl.isLoading.value
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : Column(
                              children: [
                                _StatCards(ctrl: ctrl),
                                const SizedBox(height: 16),
                                WeeklyBarChart(stats: ctrl.weeklyStats),
                                const SizedBox(height: 16),
                                _DailyBreakdown(ctrl: ctrl),
                              ],
                            )),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCards extends StatelessWidget {
  final AnalyticsController ctrl;
  const _StatCards({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: PhosphorIcons.target(),
            label: 'Avg Score',
            value: ctrl.avgWeeklyScore.round().toString(),
            gradient: AppColors.primaryGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: PhosphorIcons.fire(),
            label: 'Day Streak',
            value: ctrl.currentStreak.toString(),
            gradient: [AppColors.warning, const Color(0xFFFF6B9D)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: PhosphorIcons.forkKnife(),
            label: 'Meals',
            value: ctrl.totalMealsThisWeek.toString(),
            gradient: [AppColors.success, AppColors.accent],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
          ),
          Text(
            label,
            style: AppTextStyles.captionText
                .copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _DailyBreakdown extends StatelessWidget {
  final AnalyticsController ctrl;
  const _DailyBreakdown({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Breakdown', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 14),
          ...ctrl.weeklyStats.map(
            (day) => _DayRow(day: day),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final DayStats day;
  const _DayRow({required this.day});

  Color get _scoreColor {
    if (day.score >= 80) return AppColors.success;
    if (day.score >= 60) return AppColors.primary;
    if (day.score >= 40) return AppColors.warning;
    return day.mealCount == 0 ? AppColors.divider : AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final isToday = () {
      final now = DateTime.now();
      return day.date.year == now.year &&
          day.date.month == now.month &&
          day.date.day == now.day;
    }();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              Helpers.dayShort(day.date),
              style: AppTextStyles.labelMedium.copyWith(
                color: isToday ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: day.mealCount > 0 ? day.score / 100 : 0,
                minHeight: 8,
                backgroundColor: AppColors.inputFill,
                valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              day.mealCount > 0 ? '${day.score}' : '—',
              style: AppTextStyles.labelMedium.copyWith(color: _scoreColor),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              day.mealCount > 0
                  ? '${day.calories.round()} cal'
                  : 'No data',
              style: AppTextStyles.captionText,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
