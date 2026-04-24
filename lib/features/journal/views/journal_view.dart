import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/journal_controller.dart';
import '../../meal/models/meal_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class JournalView extends StatelessWidget {
  const JournalView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(JournalController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _JournalHeader(ctrl: ctrl),
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) return const _LoadingState();
                if (ctrl.errorMessage.value.isNotEmpty) {
                  return _ErrorState(ctrl: ctrl);
                }
                if (ctrl.meals.isEmpty) return _EmptyState(ctrl: ctrl);
                return _MealList(ctrl: ctrl);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _JournalHeader extends StatelessWidget {
  final JournalController ctrl;
  const _JournalHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Journal', style: AppTextStyles.displayMedium),
                const SizedBox(height: 2),
                Obx(() {
                  final count = ctrl.meals.length;
                  return Text(
                    count == 0
                        ? 'Your food diary'
                        : '$count meal${count == 1 ? '' : 's'} logged',
                    style: AppTextStyles.bodyMedium,
                  );
                }),
              ],
            ),
          ),
          // Refresh button
          _IconBtn(
            icon: Icons.refresh_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              ctrl.fetchMeals();
            },
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scrollable meal list grouped by date
// ─────────────────────────────────────────────────────────────────────────────

class _MealList extends StatelessWidget {
  final JournalController ctrl;
  const _MealList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return RefreshIndicator(
      onRefresh: ctrl.fetchMeals,
      color: AppColors.primary,
      child: Obx(() {
        final sections = ctrl.sections;

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad + 96),
          itemCount: sections.fold<int>(0, (n, s) => n + 1 + s.meals.length),
          itemBuilder: (context, index) {
            // Resolve which section + item this index maps to.
            int cursor = 0;
            for (final section in sections) {
              // Section header
              if (index == cursor) {
                return _SectionHeader(
                  label: section.label,
                  mealCount: section.meals.length,
                );
              }
              cursor++;

              // Meal cards within this section
              final offset = index - cursor;
              if (offset >= 0 && offset < section.meals.length) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MealCard(
                    meal: section.meals[offset],
                    onTap: () => ctrl.openDetail(section.meals[offset]),
                  ),
                );
              }
              cursor += section.meals.length;
            }
            return const SizedBox.shrink();
          },
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header  e.g.  "TODAY  ·  3 meals"
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int mealCount;
  const _SectionHeader({required this.label, required this.mealCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.textHint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$mealCount meal${mealCount == 1 ? '' : 's'}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 1, color: AppColors.divider),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal card
// ─────────────────────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final MealModel meal;
  final VoidCallback onTap;

  const _MealCard({required this.meal, required this.onTap});

  // Per-type gradient for the icon box.
  List<Color> get _gradient {
    switch (meal.type) {
      case MealType.breakfast:
        return [const Color(0xFFFFB443), const Color(0xFFFF8C69)];
      case MealType.lunch:
        return AppColors.primaryGradient;
      case MealType.dinner:
        return [AppColors.secondary, const Color(0xFF5B4CE8)];
      case MealType.snack:
        return [AppColors.success, AppColors.accent];
    }
  }

  Color get _scoreColor {
    final s = meal.nutrition.score;
    if (s >= 80) return AppColors.success;
    if (s >= 60) return AppColors.primary;
    if (s >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String get _timeStr {
    final t = meal.createdAt;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String get _dateStr {
    return DateFormat('d MMM').format(meal.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Meal type icon ───────────────────────────────────────
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        meal.type.icon,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // ── Content ──────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type label + time
                        Row(
                          children: [
                            Text(
                              meal.type.label,
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AppColors.textHint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_dateStr · $_timeStr',
                              style: AppTextStyles.captionText,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Meal name
                        Text(
                          meal.name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),

                        // Calories + feedback
                        Text(
                          '${meal.nutrition.calories.round()} kcal  ·  ${meal.nutrition.feedback}',
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Score badge ──────────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _scoreColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${meal.nutrition.score}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _scoreColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'score',
                        style: AppTextStyles.captionText,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Optional image strip ─────────────────────────────────────
            if (meal.imageUrl != null) _ImageStrip(url: meal.imageUrl!),

            // ── Macro pills ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  _MacroPill(
                    label: 'P',
                    value: meal.nutrition.proteinG,
                    color: AppColors.proteinColor,
                  ),
                  const SizedBox(width: 8),
                  _MacroPill(
                    label: 'C',
                    value: meal.nutrition.carbsG,
                    color: AppColors.carbsColor,
                  ),
                  const SizedBox(width: 8),
                  _MacroPill(
                    label: 'F',
                    value: meal.nutrition.fatG,
                    color: AppColors.fatColor,
                  ),
                  const Spacer(),
                  // Chevron — "tap to view details"
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  final String url;
  const _ImageStrip({required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          height: 130,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            height: 130,
            color: AppColors.inputFill,
          ),
          errorWidget: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label  ${value.round()}g',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading state
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      itemCount: 4,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShimmerCard(),
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final opacity = 0.04 + _ctrl.value * 0.06;
        return Container(
          height: 112,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final JournalController ctrl;
  const _EmptyState({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No meals saved yet',
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your meals and your full food journal will appear here.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => Get.until(
                (route) => route.settings.name == AppRoutes.home,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Log Your First Meal',
                  style: AppTextStyles.buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final JournalController ctrl;
  const _ErrorState({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text('Could not load meals', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Obx(() => Text(
                  ctrl.errorMessage.value,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                )),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: ctrl.fetchMeals,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Try Again', style: AppTextStyles.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
