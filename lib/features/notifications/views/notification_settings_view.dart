import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../controllers/notification_controller.dart';
import '../../../core/constants/app_colors.dart';

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(NotificationController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(),
              const SizedBox(height: 20),
              _ReminderCard(
                icon: PhosphorIcons.forkKnife(),
                iconColor: AppColors.primary,
                title: 'Meal Reminders',
                subtitle: 'Breakfast, lunch and dinner nudges',
                enabled: ctrl.mealRemindersEnabled,
                onToggle: ctrl.setMealRemindersEnabled,
                rows: [
                  _TimeRowSpec(
                    label: 'Breakfast',
                    time: ctrl.breakfastTime,
                    onPick: ctrl.setBreakfastTime,
                  ),
                  _TimeRowSpec(
                    label: 'Lunch',
                    time: ctrl.lunchTime,
                    onPick: ctrl.setLunchTime,
                  ),
                  _TimeRowSpec(
                    label: 'Dinner',
                    time: ctrl.dinnerTime,
                    onPick: ctrl.setDinnerTime,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ReminderCard(
                icon: PhosphorIcons.drop(),
                iconColor: const Color(0xFF5C7CFA),
                title: 'Water Reminders',
                subtitle: '4 reminders through the day — 10am, 1pm, 4pm, 7pm',
                enabled: ctrl.waterRemindersEnabled,
                onToggle: ctrl.setWaterRemindersEnabled,
                rows: const [],
              ),
              const SizedBox(height: 16),
              _ReminderCard(
                icon: PhosphorIcons.flame(),
                iconColor: const Color(0xFFF5A623),
                title: 'Streak Reminder',
                subtitle: "Evening nudge if you haven't logged yet",
                enabled: ctrl.streakReminderEnabled,
                onToggle: ctrl.setStreakReminderEnabled,
                rows: [
                  _TimeRowSpec(
                    label: 'Reminder time',
                    time: ctrl.streakTime,
                    onPick: ctrl.setStreakTime,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'These reminders run entirely on your device. Turning off notifications for NutraFlow in your phone settings will stop them from showing.',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Get.back();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.arrowLeft(),
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reminder card ────────────────────────────────────────────────────────────

class _TimeRowSpec {
  final String label;
  final Rx<TimeOfDay> time;
  final ValueChanged<TimeOfDay> onPick;
  const _TimeRowSpec({
    required this.label,
    required this.time,
    required this.onPick,
  });
}

class _ReminderCard extends StatelessWidget {
  final PhosphorIconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final RxBool enabled;
  final Future<bool> Function(bool) onToggle;
  final List<_TimeRowSpec> rows;

  const _ReminderCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: PhosphorIcon(icon, size: 20, color: iconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Obx(() => Switch.adaptive(
                    value: enabled.value,
                    activeTrackColor: AppColors.primary,
                    onChanged: (v) async {
                      HapticFeedback.selectionClick();
                      final ok = await onToggle(v);
                      if (!ok) {
                        Get.snackbar(
                          'Permission needed',
                          'Enable notifications for NutraFlow in your phone settings.',
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                        );
                      }
                    },
                  )),
            ],
          ),
          if (rows.isNotEmpty)
            Obx(() {
              if (!enabled.value) return const SizedBox.shrink();
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
                  ...rows.map((r) => _TimeRow(spec: r)),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final _TimeRowSpec spec;
  const _TimeRow({required this.spec});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                spec.label,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: spec.time.value,
                  );
                  if (picked != null) spec.onPick(picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    spec.time.value.format(context),
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
