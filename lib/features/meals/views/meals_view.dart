import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
          _MealsAppBar(ctrl: ctrl),
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
                    20, 16, 20,
                    MediaQuery.of(context).padding.bottom + 96,
                  ),
                  children: [
                    _NutritionSummaryCard(ctrl: ctrl),
                    if (ctrl.meals.isNotEmpty) const SizedBox(height: 20),
                    ...MealType.values.map(
                      (type) => _MealSection(ctrl: ctrl, mealType: type),
                    ),
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

// ── App bar with week date strip ─────────────────────────────────────────────

class _MealsAppBar extends StatelessWidget {
  final MealsController ctrl;
  const _MealsAppBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Meals',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _WeekDateStrip(
            selectedDate: ctrl.selectedDate,
            weekDays: ctrl.currentWeekDays,
            onSelect: (d) {
              HapticFeedback.selectionClick();
              ctrl.selectDate(d);
            },
          ),
        ],
      ),
    );
  }
}

// ── Shared horizontal week date strip ────────────────────────────────────────

class _WeekDateStrip extends StatelessWidget {
  final Rx<DateTime> selectedDate;
  final List<DateTime> weekDays;
  final void Function(DateTime) onSelect;

  const _WeekDateStrip({
    required this.selectedDate,
    required this.weekDays,
    required this.onSelect,
  });

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Obx(() {
      final sel = selectedDate.value;
      return SizedBox(
        height: 78,
        child: Row(
          children: List.generate(weekDays.length, (i) {
            final day = weekDays[i];
            final isSelected = day.year == sel.year &&
                day.month == sel.month &&
                day.day == sel.day;
            final isToday = day.year == now.year &&
                day.month == now.month &&
                day.day == now.day;

            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(day),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _labels[i],
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 14,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}

// ── Nutrition summary card ────────────────────────────────────────────────────

class _NutritionSummaryCard extends StatelessWidget {
  final MealsController ctrl;
  const _NutritionSummaryCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.meals.isEmpty) return const SizedBox.shrink();

      final cals = ctrl.totalCalories;
      final protein = ctrl.totalProtein;
      final carbs = ctrl.totalCarbs;
      final fat = ctrl.totalFat;

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
                  "Today's Nutrition",
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
                _MacroChip(
                  label: 'Protein',
                  value: protein,
                  color: AppColors.proteinColor,
                ),
                const SizedBox(width: 10),
                _MacroChip(
                  label: 'Carbs',
                  value: carbs,
                  color: AppColors.carbsColor,
                ),
                const SizedBox(width: 10),
                _MacroChip(
                  label: 'Fat',
                  value: fat,
                  color: AppColors.fatColor,
                ),
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
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

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
    );
  }
}

// ── Meal section (timeline style) ─────────────────────────────────────────────

const _mealTimeLabels = {
  MealType.breakfast: '7 AM',
  MealType.lunch: '12 PM',
  MealType.dinner: '6 PM',
  MealType.snack: '3 PM',
};

class _MealSection extends StatelessWidget {
  final MealsController ctrl;
  final MealType mealType;
  const _MealSection({required this.ctrl, required this.mealType});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = ctrl.mealsForType(mealType);
      final totalCals =
          items.fold(0.0, (s, m) => s + m.nutrition.calories);
      final timeLabel = _mealTimeLabels[mealType] ?? '';

      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline column
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: items.isNotEmpty
                            ? AppColors.primary
                            : AppColors.divider,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 1.5,
                        color: AppColors.divider,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          PhosphorIcon(
                            mealType.icon,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            mealType.label,
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (items.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${totalCals.round()} kcal',
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded,
                                      size: 13, color: AppColors.primary),
                                  SizedBox(width: 3),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (items.isEmpty)
                      _EmptyMealSlot(mealType: mealType)
                    else
                      ...items.map((meal) => _MealCard(meal: meal, ctrl: ctrl)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFEEF0F8),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
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

// ── Meal card ─────────────────────────────────────────────────────────────────

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
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w700),
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
                    child: const Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ) ??
            false;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal icon / image
              if (meal.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    meal.imageUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _MealIcon(type: meal.type),
                  ),
                )
              else
                _MealIcon(type: meal.type),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Calorie badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${meal.nutrition.calories.round()} kcal',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Macro dots
                    Row(
                      children: [
                        _MacroDot(
                          color: AppColors.proteinColor,
                          value: meal.nutrition.proteinG,
                        ),
                        const SizedBox(width: 8),
                        _MacroDot(
                          color: AppColors.fatColor,
                          value: meal.nutrition.fatG,
                        ),
                        const SizedBox(width: 8),
                        _MacroDot(
                          color: AppColors.carbsColor,
                          value: meal.nutrition.carbsG,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Time
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

class _MacroDot extends StatelessWidget {
  final Color color;
  final double value;
  const _MacroDot({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          '${value.round()}g',
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
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
        child: PhosphorIcon(type.icon, size: 22, color: AppColors.primary),
      ),
    );
  }
}
