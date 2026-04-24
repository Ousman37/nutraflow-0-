import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/meal_detail_controller.dart';
import '../models/meal_model.dart';
import '../models/nutrition_analysis.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class MealDetailView extends StatelessWidget {
  const MealDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(MealDetailController());
    final meal = ctrl.meal;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FB),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(meal: meal),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WealthyLevelCard(meal: meal),
                    const SizedBox(height: 16),
                    _MealPreviewCard(meal: meal),
                    const SizedBox(height: 16),
                    _RainbowCard(colorGroups: meal.nutrition.colorGroups),
                    const SizedBox(height: 16),
                    _MacroGridCard(nutrition: meal.nutrition),
                    const SizedBox(height: 24),
                    _DeleteButton(ctrl: ctrl),
                  ],
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
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final MealModel meal;
  const _TopBar({required this.meal});

  String get _timeStr {
    final t = meal.createdAt;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String get _dateStr {
    final t = meal.createdAt;
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${(t.year % 100).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        children: [
          // Back button
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Title
          Expanded(
            child: Center(
              child: Text(
                '${meal.type.label} Details',
                style: AppTextStyles.headlineMedium,
              ),
            ),
          ),
          // Time + date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeStr,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _dateStr,
                style: AppTextStyles.captionText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wealthy level card — glowing score bubble + feedback
// ─────────────────────────────────────────────────────────────────────────────

class _WealthyLevelCard extends StatelessWidget {
  final MealModel meal;
  const _WealthyLevelCard({required this.meal});

  int get _level =>
      ((meal.nutrition.score / 20).ceil()).clamp(1, 5);

  String get _status {
    final s = meal.nutrition.score;
    if (s >= 80) return 'Excellent';
    if (s >= 60) return 'Diverse';
    if (s >= 40) return 'Balanced';
    if (s >= 20) return 'Moderate';
    return 'Getting Started';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Soft blue radial tint centred on the glow bubble
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Align(
                alignment: const Alignment(0, -0.3),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wealthy Level',
                          style: AppTextStyles.headlineSmall,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _status,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Glow bubble
                _GlowScoreBubble(level: _level),
                const SizedBox(height: 26),
                // Feedback text
                Text(
                  meal.nutrition.feedback,
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glowing score bubble — concentric aura rings + solid core
// ─────────────────────────────────────────────────────────────────────────────

class _GlowScoreBubble extends StatelessWidget {
  final int level;
  const _GlowScoreBubble({required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outermost aura
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
          ),
          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.09),
            ),
          ),
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          // Core circle
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.3),
                radius: 1.0,
                colors: [
                  const Color(0xFF7BA8FF),
                  AppColors.primary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.55),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 50,
                  spreadRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '+$level',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal preview card — name, items, image
// ─────────────────────────────────────────────────────────────────────────────

class _MealPreviewCard extends StatelessWidget {
  final MealModel meal;
  const _MealPreviewCard({required this.meal});

  /// Formats description into bullet-separated items e.g. "Eggs • Chicken • Bread"
  String get _itemsLabel {
    final raw = meal.description ?? meal.name;
    if (raw.isEmpty) return meal.type.label;
    // Try to split on common separators
    final parts = raw
        .split(RegExp(r'[,\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(5)
        .toList();
    if (parts.length <= 1) return raw;
    return parts.map((p) {
      // Capitalise first letter
      return p[0].toUpperCase() + p.substring(1);
    }).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('Meal', style: AppTextStyles.headlineSmall),
              const Spacer(),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _itemsLabel,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          // Image or placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: meal.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: meal.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _ImagePlaceholder(meal: meal),
                    errorWidget: (_, __, ___) => _ImagePlaceholder(meal: meal),
                  )
                : _ImagePlaceholder(meal: meal),
          ),
          const SizedBox(height: 14),
          // Calorie strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total calories',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
                Text(
                  '${meal.nutrition.calories.round()} kcal',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Feedback repeated below image
          Text(
            meal.nutrition.feedback,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final MealModel meal;
  const _ImagePlaceholder({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(meal.type.icon, size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            meal.type.label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Eat-the-rainbow card — 6 colour circles in a row
// ─────────────────────────────────────────────────────────────────────────────

class _RainbowCard extends StatelessWidget {
  final List<ColorGroup> colorGroups;
  const _RainbowCard({required this.colorGroups});

  static const _palette = [
    ('Red',        Color(0xFFFF5252), 'Red'),
    ('Orange',     Color(0xFFFF9F43), 'Orange'),
    ('Yellow',     Color(0xFFFFD93D), 'Yellow'),
    ('Green',      Color(0xFF4CAF82), 'Green'),
    ('Blue/Purple',Color(0xFF7B6CF8), 'Blue'),
    ('White/Brown',Color(0xFFBDAA8A), 'White'),
  ];

  bool _isPresent(String colorKey) => colorGroups
      .any((g) => g.color == colorKey && g.present);

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Eat the rainbow', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: _palette.asMap().entries.map((entry) {
              final i = entry.key;
              final (key, color, label) = entry.value;
              final active = _isPresent(key);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < _palette.length - 1 ? 6 : 0),
                  child: _RainbowBar(color: color, label: label, active: active),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RainbowBar extends StatelessWidget {
  final Color color;
  final String label;
  final bool active;

  const _RainbowBar({
    required this.color,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: active ? 1.0 : 0.30,
      child: Column(
        children: [
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: active ? color : color.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.captionText.copyWith(
              color: active ? AppColors.textPrimary : AppColors.textHint,
              fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Macro grid card — 2×2 status cards
// ─────────────────────────────────────────────────────────────────────────────

class _MacroGridCard extends StatelessWidget {
  final NutritionAnalysis nutrition;
  const _MacroGridCard({required this.nutrition});

  static String _status(double value, double high, double moderate) {
    if (value >= high) return 'High';
    if (value >= moderate) return 'Moderate';
    return 'Low';
  }

  static Color _statusColor(String status) {
    if (status == 'High') return AppColors.success;
    if (status == 'Moderate') return AppColors.primary;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Protein', _status(nutrition.proteinG, 30, 15)),
      ('Carbs',   _status(nutrition.carbsG, 60, 30)),
      ('Fat',     _status(nutrition.fatG, 20, 10)),
      ('Fiber',   _status(nutrition.fiberG, 8, 4)),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Macronutrient breakdown', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          Row(
            children: items.map((item) {
              final (label, status) = item;
              final statusColor = _statusColor(status);
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      status,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTextStyles.captionText.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Delete button
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteButton extends StatelessWidget {
  final MealDetailController ctrl;
  const _DeleteButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Meal'),
            content: const Text(
                'Are you sure you want to delete this meal?'),
            actions: [
              TextButton(onPressed: Get.back, child: const Text('Cancel')),
              TextButton(
                onPressed: ctrl.deleteMeal,
                child: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ),
        icon: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 18),
        label: Text(
          'Delete Meal',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: AppColors.error.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared section card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
