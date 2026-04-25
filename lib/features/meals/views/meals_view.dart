import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/meals_controller.dart';
import '../../meal/models/meal_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class MealsView extends StatelessWidget {
  const MealsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(MealsController());
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _MealsHeader(ctrl: ctrl),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              return RefreshIndicator(
                onRefresh: ctrl.loadMeals,
                color: AppColors.primary,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20, 12, 20,
                    MediaQuery.of(context).padding.bottom + 96,
                  ),
                  children: [
                    _NutritionSummaryCard(ctrl: ctrl),
                    const SizedBox(height: 20),
                    ...MealType.values.map((type) => _MealSection(
                          ctrl: ctrl,
                          mealType: type,
                        )),
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

// ── Header with date navigation ───────────────────────────────────────────────

class _MealsHeader extends StatelessWidget {
  final MealsController ctrl;
  const _MealsHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.dashboardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meals',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _DateNavigator(ctrl: ctrl),
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final MealsController ctrl;
  const _DateNavigator({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final date = ctrl.selectedDate.value;
      final label = ctrl.isToday
          ? 'Today'
          : DateFormat('EEE, MMM d').format(date);

      return Row(
        children: [
          _NavArrow(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              ctrl.previousDay();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('MMMM d, yyyy').format(date),
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          if (!ctrl.isToday)
            _NavArrow(
              icon: Icons.chevron_right_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                ctrl.nextDay();
              },
            ),
        ],
      );
    });
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ── Nutrition summary card ─────────────────────────────────────────────────────

class _NutritionSummaryCard extends StatelessWidget {
  final MealsController ctrl;
  const _NutritionSummaryCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cals = ctrl.totalCalories;
      final protein = ctrl.totalProtein;
      final carbs = ctrl.totalCarbs;
      final fat = ctrl.totalFat;

      if (ctrl.meals.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Today\'s Nutrition',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${cals.round()} kcal',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _MacroChip(label: 'Protein', value: protein, color: AppColors.proteinColor),
                const SizedBox(width: 10),
                _MacroChip(label: 'Carbs', value: carbs, color: AppColors.carbsColor),
                const SizedBox(width: 10),
                _MacroChip(label: 'Fat', value: fat, color: AppColors.fatColor),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MacroChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '${value.round()}g',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meal section ──────────────────────────────────────────────────────────────

class _MealSection extends StatelessWidget {
  final MealsController ctrl;
  final MealType mealType;
  const _MealSection({required this.ctrl, required this.mealType});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = ctrl.mealsForType(mealType);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(mealType: mealType, count: items.length),
          const SizedBox(height: 8),
          if (items.isEmpty)
            _EmptyMealSlot(mealType: mealType)
          else
            ...items.map((meal) => _MealCard(meal: meal, ctrl: ctrl)),
          const SizedBox(height: 16),
        ],
      );
    });
  }
}

class _SectionHeader extends StatelessWidget {
  final MealType mealType;
  final int count;
  const _SectionHeader({required this.mealType, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Icon(mealType.icon, size: 16, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          mealType.label,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
        const Spacer(),
        GestureDetector(
          onTap: () => Get.toNamed(
            AppRoutes.selectMethod,
            arguments: {'preselectedType': mealType},
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 3),
                Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyMealSlot extends StatelessWidget {
  final MealType mealType;
  const _EmptyMealSlot({required this.mealType});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.selectMethod,
        arguments: {'preselectedType': mealType},
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFEEF0F8),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 18,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Text(
              'Log ${mealType.label.toLowerCase()}',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealModel meal;
  final MealsController ctrl;
  const _MealCard({required this.meal, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) async {
        return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Delete Meal?',
              style: TextStyle(
                  fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700),
            ),
            content: const Text(
              'This meal will be permanently removed.',
              style: TextStyle(fontFamily: 'PlusJakartaSans'),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => ctrl.deleteMeal(meal.id),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.mealDetail, arguments: meal),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image or icon
              if (meal.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    meal.imageUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => _MealIcon(type: meal.type),
                  ),
                )
              else
                _MealIcon(type: meal.type),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${meal.nutrition.calories.round()} kcal  ·  '
                      'P ${meal.nutrition.proteinG.round()}g  ·  '
                      'C ${meal.nutrition.carbsG.round()}g  ·  '
                      'F ${meal.nutrition.fatG.round()}g',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Text(
                _formatTime(meal.createdAt),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

class _MealIcon extends StatelessWidget {
  final MealType type;
  const _MealIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(type.icon, size: 22, color: AppColors.primary),
      ),
    );
  }
}
