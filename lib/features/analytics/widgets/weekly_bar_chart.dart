import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../analytics/controllers/analytics_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/helpers.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<DayStats> stats;

  const WeeklyBarChart({super.key, required this.stats});

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
          Text('Weekly Score Trend', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text('Nutrition scores this week', style: AppTextStyles.bodySmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= stats.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          Helpers.dayShort(stats[idx].date),
                          style: AppTextStyles.captionText,
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                ),
                barGroups: List.generate(stats.length, (i) {
                  final score = stats[i].score.toDouble();
                  final isEmpty = stats[i].mealCount == 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: isEmpty ? 0 : score,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        gradient: isEmpty
                            ? null
                            : const LinearGradient(
                                colors: AppColors.primaryGradient,
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                        color: isEmpty ? AppColors.divider : null,
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      '${rod.toY.round()}',
                      AppTextStyles.labelMedium.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}
