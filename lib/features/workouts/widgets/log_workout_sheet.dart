import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../progress/models/workout_model.dart';
import '../controllers/workouts_controller.dart';
import '../../../core/constants/app_colors.dart';

class LogWorkoutSheet extends StatefulWidget {
  const LogWorkoutSheet({super.key});

  @override
  State<LogWorkoutSheet> createState() => _LogWorkoutSheetState();
}

class _LogWorkoutSheetState extends State<LogWorkoutSheet> {
  WorkoutType _selectedType = WorkoutType.running;
  int _durationMinutes = 30;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  double _estimatedCalories() {
    // Simple MET-based estimate at 70 kg bodyweight
    const mets = {
      WorkoutType.running: 9.8,
      WorkoutType.cycling: 7.5,
      WorkoutType.weightLifting: 5.0,
      WorkoutType.yoga: 3.0,
      WorkoutType.hiit: 10.0,
      WorkoutType.swimming: 8.0,
      WorkoutType.walking: 3.5,
      WorkoutType.other: 5.0,
    };
    final met = mets[_selectedType] ?? 5.0;
    return met * 70 * (_durationMinutes / 60);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE0EE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'Log Workout',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Workout type grid
            const Text(
              'Type',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _WorkoutTypeGrid(
              selected: _selectedType,
              onSelect: (t) => setState(() => _selectedType = t),
            ),

            const SizedBox(height: 22),

            // Duration
            Row(
              children: [
                const Text(
                  'Duration',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_durationMinutes min',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                thumbColor: AppColors.primary,
                inactiveTrackColor: AppColors.primary.withValues(alpha: 0.2),
                overlayColor: AppColors.primary.withValues(alpha: 0.12),
                trackHeight: 4,
              ),
              child: Slider(
                value: _durationMinutes.toDouble(),
                min: 5,
                max: 180,
                divisions: 35,
                onChanged: (v) => setState(() => _durationMinutes = v.round()),
              ),
            ),

            const SizedBox(height: 8),

            // Estimated calories
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIcons.flame(),
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated ${_estimatedCalories().round()} kcal burned',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Notes
            const Text(
              'Notes (optional)',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Morning run in the park',
                hintStyle: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: AppColors.textHint,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            GetBuilder<WorkoutsController>(
              builder: (ctrl) {
                return GestureDetector(
                  onTap: ctrl.isSaving.value
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();
                          await ctrl.logWorkout(
                            type: _selectedType,
                            durationMinutes: _durationMinutes,
                            caloriesBurned: _estimatedCalories(),
                            notes: _notesCtrl.text.trim().isEmpty
                                ? null
                                : _notesCtrl.text.trim(),
                          );
                          if (mounted) Get.back();
                          Get.snackbar(
                            'Workout Logged',
                            '${_selectedType.label} · $_durationMinutes min',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.primary,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(16),
                            borderRadius: 12,
                          );
                        },
                  child: Obx(() => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: ctrl.isSaving.value
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF3CB54A),
                                    Color(0xFF1A7A38)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: ctrl.isSaving.value
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : null,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: ctrl.isSaving.value
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save Workout',
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Workout type grid ─────────────────────────────────────────────────────────

class _WorkoutTypeGrid extends StatelessWidget {
  final WorkoutType selected;
  final ValueChanged<WorkoutType> onSelect;
  const _WorkoutTypeGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemCount: WorkoutType.values.length,
      itemBuilder: (_, i) {
        final type = WorkoutType.values[i];
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  type.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  type.label,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
