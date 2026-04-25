import 'dart:math';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget — same API as before, no callers need changing.
// ─────────────────────────────────────────────────────────────────────────────

class CircularNutritionProgress extends StatefulWidget {
  final int score;
  final double caloriesConsumed;
  final double caloriesTarget;
  final String encouragementText;
  final String levelText;
  final int pageCount;
  final int currentPage;

  const CircularNutritionProgress({
    super.key,
    required this.score,
    required this.caloriesConsumed,
    required this.caloriesTarget,
    this.encouragementText = 'Eat More\nNutritional Food',
    this.levelText = 'Wealthy Level',
    this.pageCount = 3,
    this.currentPage = 0,
  });

  @override
  State<CircularNutritionProgress> createState() =>
      _CircularNutritionProgressState();
}

class _CircularNutritionProgressState extends State<CircularNutritionProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(CircularNutritionProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _progress => widget.caloriesTarget > 0
      ? (widget.caloriesConsumed / widget.caloriesTarget).clamp(0.0, 1.0)
      : (widget.score / 100).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final animatedProgress = _progress * _anim.value;
        final animatedScore = (widget.score * _anim.value).round();

        return SizedBox(
          width: 228,
          height: 228,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Teal-glow ring + glass disc backdrop
              CustomPaint(
                size: const Size(228, 228),
                painter: _GlowRingPainter(progress: animatedProgress),
              ),
              // All inner content — centered vertically and horizontally
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Apple icon — Phosphor appleLogo in white
                    Icon(
                      PhosphorIcons.appleLogo(),
                      size: 26,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    const SizedBox(height: 7),
                    // Encouragement — two lines, centred, soft white
                    Text(
                      widget.encouragementText,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'PlusJakartaSans', 
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.90),
                        height: 1.42,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Score — dominant, bold, white
                    Text(
                      '$animatedScore',
                      style: TextStyle(fontFamily: 'PlusJakartaSans', 
                        fontSize: 54,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Level label — softer, smaller
                    Text(
                      widget.levelText,
                      style: TextStyle(fontFamily: 'PlusJakartaSans', 
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.68),
                        letterSpacing: 0.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Pagination dots — equal-circle style, inside the ring
                    _PaginationDots(
                      count: widget.pageCount,
                      current: widget.currentPage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring + glass CustomPainter
//
// Layers (bottom to top):
//   1. Ambient teal halo  — full-circle blur giving the "glowing orb" feel
//   2. Glass disc fill    — off-axis radial gradient for 3-D glass look
//   3. Glass border       — hairline ring around the disc
//   4. Track ring         — barely-visible white circle
//   5. Arc glow layer     — blurred teal stroke under the main arc
//   6. Progress arc       — mint→teal sweep gradient
//   7. Tip glow dot       — white dot with teal halo at the arc endpoint
// ─────────────────────────────────────────────────────────────────────────────

class _GlowRingPainter extends CustomPainter {
  final double progress;
  const _GlowRingPainter({required this.progress});

  // Teal palette matching the reference
  static const _tealGlow = Color(0xFF4ECFB5);
  static const _mintLight = Color(0xFFCAF5EA);
  static const _tealMid = Color(0xFF5ADEC0);
  static const _tealDeep = Color(0xFF3CC4A6);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const stroke = 5.0;
    final ringR = size.width / 2 - 8;      // outer ring radius
    final glassR = ringR - stroke - 9;     // glass disc radius

    // ── 1. Ambient teal halo (full circle) ───────────────────────────────────
    canvas.drawCircle(
      c, ringR,
      Paint()
        ..color = _tealGlow.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 30
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // ── 2. Glass disc fill (off-axis radial gradient) ─────────────────────────
    canvas.drawCircle(
      c, glassR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.30),
          radius: 1.0,
          colors: [
            Colors.white.withValues(alpha: 0.26),
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: glassR)),
    );

    // ── 3. Glass disc hairline border ─────────────────────────────────────────
    canvas.drawCircle(
      c, glassR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // ── 4. Track ring ─────────────────────────────────────────────────────────
    canvas.drawCircle(
      c, ringR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * pi * progress;
    final rect = Rect.fromCircle(center: c, radius: ringR);

    // ── 5. Arc glow layer (blurred, wider than the arc) ───────────────────────
    canvas.drawArc(
      rect, -pi / 2, sweepAngle, false,
      Paint()
        ..color = _tealGlow.withValues(alpha: 0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── 6. Main progress arc — mint → teal sweep gradient ────────────────────
    canvas.drawArc(
      rect, -pi / 2, sweepAngle, false,
      Paint()
        ..shader = SweepGradient(
          colors: const [
            _mintLight,  // very light mint at 12 o'clock
            _tealMid,    // mid teal
            _tealDeep,   // deeper teal toward tip
            _mintLight,  // wrap back for smooth loop
          ],
          stops: const [0.0, 0.45, 0.80, 1.0],
          startAngle: -pi / 2,
          endAngle: -pi / 2 + 2 * pi,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // ── 7. Tip glow dot ───────────────────────────────────────────────────────
    if (progress > 0.025) {
      final tipAngle = -pi / 2 + sweepAngle;
      final tip = Offset(
        c.dx + ringR * cos(tipAngle),
        c.dy + ringR * sin(tipAngle),
      );
      // Outer glow halo
      canvas.drawCircle(
        tip, stroke + 5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      // Crisp white dot
      canvas.drawCircle(
        tip, stroke / 2 + 1.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_GlowRingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Pagination dots — three equal circles; active is fully white, rest faded.
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationDots extends StatelessWidget {
  final int count;
  final int current;
  const _PaginationDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: 5.5,
          height: 5.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white
                .withValues(alpha: isActive ? 0.90 : 0.35),
          ),
        );
      }),
    );
  }
}
