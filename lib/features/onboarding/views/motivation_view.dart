import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class MotivationView extends StatefulWidget {
  const MotivationView({super.key});

  @override
  State<MotivationView> createState() => _MotivationViewState();
}

class _MotivationViewState extends State<MotivationView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.dashboardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, child) => Opacity(
              opacity: _fadeAnim.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnim.value),
                child: child,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _buildTitle(),
                const SizedBox(height: 36),
                _buildChart(),
                const SizedBox(height: 36),
                _buildBulletPoints(),
                const Spacer(),
                _buildCTA(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        "You'll meet your goal\neasily with NutraFlow!",
        style: TextStyle(fontFamily: 'PlusJakartaSans', 
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        height: 180,
        child: CustomPaint(
          size: const Size(double.infinity, 180),
          painter: _GoalCurvePainter(),
        ),
      ),
    );
  }

  Widget _buildBulletPoints() {
    const items = [
      'Focus on your feelings.',
      'Track your health, & water balance.',
      'Get new habits.',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: items
            .map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      text,
                      style: TextStyle(fontFamily: 'PlusJakartaSans', 
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCTA() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GestureDetector(
        onTap: () => Get.offAllNamed(AppRoutes.home),
        child: Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D2E),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Start Your Journey',
              style: TextStyle(fontFamily: 'PlusJakartaSans', 
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Custom Painter — growth curve chart ──────────────────────────────────────

class _GoalCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid background lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    for (int i = 1; i <= 4; i++) {
      final y = h * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Filled area under curve
    final fillPath = Path();
    fillPath.moveTo(0, h);
    fillPath.lineTo(0, h * 0.82);

    // S-curve control points
    fillPath.cubicTo(
      w * 0.25, h * 0.80,
      w * 0.45, h * 0.65,
      w * 0.58, h * 0.42,
    );
    fillPath.cubicTo(
      w * 0.70, h * 0.22,
      w * 0.82, h * 0.10,
      w, h * 0.05,
    );
    fillPath.lineTo(w, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF5CF4B0).withValues(alpha: 0.5),
          const Color(0xFF5CF4B0).withValues(alpha: 0.05),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Curve stroke
    final curvePath = Path();
    curvePath.moveTo(0, h * 0.82);
    curvePath.cubicTo(
      w * 0.25, h * 0.80,
      w * 0.45, h * 0.65,
      w * 0.58, h * 0.42,
    );
    curvePath.cubicTo(
      w * 0.70, h * 0.22,
      w * 0.82, h * 0.10,
      w, h * 0.05,
    );

    final curvePaint = Paint()
      ..color = const Color(0xFF5CF4B0)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(curvePath, curvePaint);

    // "You are here" marker (left side)
    _drawMarker(
      canvas,
      offset: Offset(w * 0.05, h * 0.82),
      label: 'You are here!',
      size: size,
      isLeft: true,
    );

    // "Your goal" marker (right side)
    _drawMarker(
      canvas,
      offset: Offset(w * 0.92, h * 0.06),
      label: 'Your goal',
      size: size,
      isLeft: false,
    );
  }

  void _drawMarker(
    Canvas canvas, {
    required Offset offset,
    required String label,
    required Size size,
    required bool isLeft,
  }) {
    // Dot
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(offset, 5, dotPaint);

    // Dashed vertical line
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const dashH = 4.0;
    const gapH = 3.0;
    double y = offset.dy - dashH;
    while (y > 10) {
      canvas.drawLine(
        Offset(offset.dx, y),
        Offset(offset.dx, max(10.0, y - dashH)),
        linePaint,
      );
      y -= dashH + gapH;
    }

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = isLeft ? offset.dx : offset.dx - tp.width;
    tp.paint(canvas, Offset(dx, 2));
  }

  @override
  bool shouldRepaint(_GoalCurvePainter old) => false;
}
