import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Spring press — scales down on tap, springs back on release
// ─────────────────────────────────────────────────────────────────────────────

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const _PressScale({
    required this.child,
    required this.onTap,
    this.scale = 0.95,
  });

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _anim = Tween<double>(
    begin: 1.0,
    end: widget.scale,
  ).animate(CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
    reverseCurve: Curves.elasticOut,
  ));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) => Transform.scale(scale: _anim.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// Method data: (label, key, icon)
typedef _Method = (String, String, IconData);

const _methods = <_Method>[
  ('Add Food via Photo', 'camera', Icons.camera_alt_rounded),
  ('Import Image', 'gallery', Icons.photo_library_rounded),
  ('Text Only', 'text', Icons.edit_note_rounded),
  ('From Past Meals', 'past', Icons.history_rounded),
];

class SelectMethodView extends StatelessWidget {
  const SelectMethodView({super.key});

  Future<void> _handleMethod(String method) async {
    if (method == 'past') {
      Get.snackbar(
        'Coming Soon',
        'Meal history import will be available soon.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final args = Get.arguments as Map?;
    final result = await Get.toNamed(
      AppRoutes.addMeal,
      arguments: {
        'method': method,
        if (args?['preselectedType'] != null)
          'preselectedType': args!['preselectedType'],
      },
    );
    if (result == true) Get.back(result: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.onboardingBlueGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 40),
              _buildMethods(),
              const Spacer(),
              _buildCancelButton(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Select a Method',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add your meal in the most convenient way',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.65),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMethods() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: List.generate(_methods.length, (i) {
          final (label, key, icon) = _methods[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _PressScale(
              scale: 0.96,
              onTap: () {
                HapticFeedback.lightImpact();
                _handleMethod(key);
              },
              child: _MethodPill(label: label),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCancelButton() {
    return _PressScale(
      scale: 0.90,
      onTap: () {
        HapticFeedback.lightImpact();
        Get.back();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            'Cancel',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Method pill with dashed border
// ─────────────────────────────────────────────────────────────────────────────

class _MethodPill extends StatelessWidget {
  final String label;

  const _MethodPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: 18,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed rounded-rectangle border painter
// ─────────────────────────────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  const _DashedBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    const dashLen = 5.0;
    const gapLen = 4.5;

    double dist = 0;
    while (dist < metric.length) {
      final end = min(dist + dashLen, metric.length);
      canvas.drawPath(metric.extractPath(dist, end), paint);
      dist += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}
