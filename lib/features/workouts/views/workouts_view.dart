import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../controllers/workouts_controller.dart';
import '../../progress/models/workout_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/log_workout_sheet.dart';
import '../../../core/constants/app_colors.dart';

class WorkoutsView extends StatelessWidget {
  const WorkoutsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WorkoutsController());
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _WorkoutsAppBar(ctrl: ctrl),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              return RefreshIndicator(
                onRefresh: ctrl.loadWorkouts,
                color: AppColors.primary,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20, 16, 20,
                    MediaQuery.of(context).padding.bottom + 100,
                  ),
                  children: [
                    const SizedBox(height: 90), // room for character overflow above card
                    _BodyStatsCard(),
                    const SizedBox(height: 16),
                    _CaloriesBurnedCard(ctrl: ctrl),
                    const SizedBox(height: 16),
                    _StatsCard(ctrl: ctrl),
                    const SizedBox(height: 16),
                    _LogButton(ctrl: ctrl),
                    const SizedBox(height: 20),
                    if (ctrl.workouts.isEmpty)
                      _EmptyState()
                    else ...[
                      const Text(
                        "Today's Workouts",
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...ctrl.workouts.map(
                        (w) => _WorkoutCard(workout: w, ctrl: ctrl),
                      ),
                    ],
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

class _WorkoutsAppBar extends StatelessWidget {
  final WorkoutsController ctrl;
  const _WorkoutsAppBar({required this.ctrl});

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
                'Workouts',
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

// ── Shared week date strip ────────────────────────────────────────────────────

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

// ── Body stats card with fitness character ────────────────────────────────────

class _BodyStatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profile = Get.find<AuthController>().userProfile.value;
    final weight = profile?.weightKg;
    final ht = profile?.heightCm;
    final targetWeight = weight != null ? (weight - 3).clamp(40.0, weight) : null;

    const cardHeight = 120.0;
    const characterHeight = 210.0;
    const characterWidth = 130.0;
    const overflowTop = characterHeight - cardHeight; // 90px above card

    return SizedBox(
      height: cardHeight + overflowTop,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Card sits at the bottom of the stack ─────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: cardHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Stats section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Body Stats',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _BodyStatItem(
                                label: 'Weight',
                                value: weight != null
                                    ? '${weight.round()} kg'
                                    : '— kg',
                                icon: PhosphorIcons.scales(),
                                color: AppColors.primary,
                              ),
                              Container(
                                  width: 1,
                                  height: 36,
                                  color: AppColors.divider),
                              _BodyStatItem(
                                label: 'Height',
                                value: ht != null ? '${ht.round()} cm' : '—',
                                icon: PhosphorIcons.ruler(),
                                color: AppColors.secondary,
                              ),
                              if (targetWeight != null) ...[
                                Container(
                                    width: 1,
                                    height: 36,
                                    color: AppColors.divider),
                                _BodyStatItem(
                                  label: 'Target',
                                  value: '${targetWeight.round()} kg',
                                  icon: PhosphorIcons.target(),
                                  color: AppColors.warning,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Reserve space for the character on the right
                  const SizedBox(width: characterWidth),
                ],
              ),
            ),
          ),

          // ── Green gradient panel behind the character ─────────────────────
          Positioned(
            right: 0,
            bottom: 0,
            width: characterWidth,
            height: cardHeight,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A7A38),
                    const Color(0xFF0D3D1E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),

          // ── Character image – anchored to bottom-right, overflows top ─────
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/workout_character.png',
              width: characterWidth,
              height: characterHeight,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stack) => SizedBox(
                width: characterWidth,
                height: characterHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: PhosphorIcon(
                    PhosphorIcons.personSimpleRun(),
                    size: 64,
                    color: AppColors.primary.withValues(alpha: 0.35),
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

class _BodyStatItem extends StatelessWidget {
  final String label;
  final String value;
  final PhosphorIconData icon;
  final Color color;

  const _BodyStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 16,
              fontWeight: FontWeight.w800,
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
    );
  }
}

// ── Calories burned hero card ─────────────────────────────────────────────────

class _CaloriesBurnedCard extends StatelessWidget {
  final WorkoutsController ctrl;
  const _CaloriesBurnedCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cals = ctrl.totalCaloriesBurned;
      final types = ctrl.workouts
          .map((w) => w.type)
          .toSet()
          .toList();

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A7A38), Color(0xFF269D4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            PhosphorIcons.flame(PhosphorIconsStyle.fill),
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${cals.round()}',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Calories burned',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (types.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...WorkoutType.values.map((t) {
                          final done = types.contains(t);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: done
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: done
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.20),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${t.emoji} ${t.label}',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 11,
                                fontWeight: done
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: done
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final WorkoutsController ctrl;
  const _StatsCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mins = ctrl.totalMinutes;
      final cals = ctrl.totalCaloriesBurned;

      return Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            _StatItem(
              value: '$mins',
              unit: 'min',
              label: 'Active Time',
              icon: PhosphorIcons.timer(),
              color: AppColors.primary,
            ),
            Container(
              width: 1,
              height: 48,
              color: AppColors.divider,
            ),
            _StatItem(
              value: '${cals.round()}',
              unit: 'kcal',
              label: 'Burned',
              icon: PhosphorIcons.flame(),
              color: AppColors.warning,
            ),
            Container(
              width: 1,
              height: 48,
              color: AppColors.divider,
            ),
            _StatItem(
              value: '${ctrl.workouts.length}',
              unit: '',
              label: 'Sessions',
              icon: PhosphorIcons.barbell(),
              color: AppColors.secondary,
            ),
          ],
        ),
      );
    });
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final PhosphorIconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.unit,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          PhosphorIcon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
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
    );
  }
}

// ── Log button ────────────────────────────────────────────────────────────────

class _LogButton extends StatelessWidget {
  final WorkoutsController ctrl;
  const _LogButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Get.bottomSheet(
          const LogWorkoutSheet(),
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          backgroundColor: Colors.white,
        );
      },
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3CB54A), Color(0xFF1A7A38)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(PhosphorIcons.plus(), color: Colors.white, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Log a Workout',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            PhosphorIcon(
              PhosphorIcons.barbell(),
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            const Text(
              'No workouts yet',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Log your first workout to start\ntracking your fitness progress.',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Workout card ──────────────────────────────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final WorkoutsController ctrl;
  const _WorkoutCard({required this.workout, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(workout.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child:
            PhosphorIcon(PhosphorIcons.trash(), color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) async {
        return await Get.dialog<bool>(
              AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text(
                  'Delete Workout?',
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w700),
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
      onDismissed: (_) => ctrl.deleteWorkout(workout.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  workout.type.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.type.label,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      PhosphorIcon(PhosphorIcons.timer(),
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${workout.durationMinutes} min',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (workout.caloriesBurned != null) ...[
                        const SizedBox(width: 8),
                        const Text('·',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        const Text('🔥',
                            style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 2),
                        Text(
                          '${workout.caloriesBurned!.round()} kcal',
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(workout.createdAt),
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    workout.type.label,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
