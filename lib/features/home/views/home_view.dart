import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../meals/views/meals_view.dart';
import '../../workouts/views/workouts_view.dart';
import '../../workouts/controllers/workouts_controller.dart';
import '../../progress/views/progress_view.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reusable spring press
// ─────────────────────────────────────────────────────────────────────────────

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const _PressScale({
    required this.child,
    required this.onTap,
    this.scale = 0.96,
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

// ─────────────────────────────────────────────────────────────────────────────
// HomeView
// ─────────────────────────────────────────────────────────────────────────────

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(HomeController());

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _TabBody(ctrl: ctrl, tabIndex: 0, child: _HomeTab(ctrl: ctrl)),
          _TabBody(ctrl: ctrl, tabIndex: 1, child: const MealsView()),
          _TabBody(ctrl: ctrl, tabIndex: 2, child: const WorkoutsView()),
          _TabBody(ctrl: ctrl, tabIndex: 3, child: const ProgressView()),
        ],
      ),
      bottomNavigationBar: _FloatingNav(ctrl: ctrl),
    );
  }
}

class _TabBody extends StatelessWidget {
  final HomeController ctrl;
  final int tabIndex;
  final Widget child;

  const _TabBody({
    required this.ctrl,
    required this.tabIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final visible = ctrl.selectedTabIndex.value == tabIndex;
      return IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: child,
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingNav extends StatelessWidget {
  final HomeController ctrl;
  const _FloatingNav({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBarDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Obx(() => _NavIcon(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isActive: ctrl.selectedTabIndex.value == 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ctrl.selectedTabIndex.value = 0;
                      },
                    )),
                Obx(() => _NavIcon(
                      icon: Icons.restaurant_rounded,
                      label: 'Meals',
                      isActive: ctrl.selectedTabIndex.value == 1,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ctrl.selectedTabIndex.value = 1;
                      },
                    )),
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: _PressScale(
                    scale: 0.88,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Get.toNamed(AppRoutes.scanner);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3CB54A), Color(0xFF1A7A38)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                Obx(() => _NavIcon(
                      icon: Icons.fitness_center_rounded,
                      label: 'Workouts',
                      isActive: ctrl.selectedTabIndex.value == 2,
                      onTap: () {
                        if (!Get.find<SubscriptionController>().requirePro()) {
                          return;
                        }
                        HapticFeedback.selectionClick();
                        ctrl.selectedTabIndex.value = 2;
                      },
                    )),
                Obx(() => _NavIcon(
                      icon: Icons.bar_chart_rounded,
                      label: 'Progress',
                      isActive: ctrl.selectedTabIndex.value == 3,
                      onTap: () {
                        if (!Get.find<SubscriptionController>().requirePro()) {
                          return;
                        }
                        HapticFeedback.selectionClick();
                        ctrl.selectedTabIndex.value = 3;
                      },
                    )),
              ],
            ),
          ),
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0.38,
                  end: isActive ? 1.0 : 0.38,
                ),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                builder: (context, opacity, child) => Icon(
                  icon,
                  size: 22,
                  color: Colors.white.withValues(alpha: opacity),
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.38),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Home Tab — dashboard
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final HomeController ctrl;
  const _HomeTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: ctrl.refresh,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 100),
            children: [
              _DashGreeting(ctrl: ctrl),
              const SizedBox(height: 16),
              const _MotivationBanner(),
              const SizedBox(height: 16),
              _TodayStatusCard(ctrl: ctrl),
              const SizedBox(height: 16),
              const _WaterIntakeCard(),
              const SizedBox(height: 16),
              _QuickActivityGrid(ctrl: ctrl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting header
// ─────────────────────────────────────────────────────────────────────────────

class _DashGreeting extends StatelessWidget {
  final HomeController ctrl;
  const _DashGreeting({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        children: [
          _PressScale(
            scale: 0.92,
            onTap: () {
              HapticFeedback.lightImpact();
              Get.toNamed(AppRoutes.profile);
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                Obx(() => Text(
                  ctrl.userName,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                )),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
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
            child: PhosphorIcon(
              PhosphorIcons.bell(),
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's Status Card
// ─────────────────────────────────────────────────────────────────────────────

class _TodayStatusCard extends StatelessWidget {
  final HomeController ctrl;
  const _TodayStatusCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Status",
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Obx(() => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CalorieRingWidget(
                consumed: ctrl.totalCalories,
                target: ctrl.calorieTarget,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _MacroProgressRow(
                      label: 'Protein',
                      current: ctrl.totalProtein,
                      target: ctrl.proteinTarget,
                      color: AppColors.proteinColor,
                    ),
                    const SizedBox(height: 14),
                    _MacroProgressRow(
                      label: 'Fat',
                      current: ctrl.totalFat,
                      target: ctrl.fatTarget,
                      color: AppColors.fatColor,
                    ),
                    const SizedBox(height: 14),
                    _MacroProgressRow(
                      label: 'Carbs',
                      current: ctrl.totalCarbs,
                      target: ctrl.carbsTarget,
                      color: AppColors.carbsColor,
                    ),
                  ],
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated calorie ring
// ─────────────────────────────────────────────────────────────────────────────

class _CalorieRingWidget extends StatefulWidget {
  final double consumed;
  final double target;
  const _CalorieRingWidget({required this.consumed, required this.target});

  @override
  State<_CalorieRingWidget> createState() => _CalorieRingWidgetState();
}

class _CalorieRingWidgetState extends State<_CalorieRingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  late final Animation<double> _anim =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_CalorieRingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consumed != widget.consumed) {
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

  @override
  Widget build(BuildContext context) {
    final progress = widget.target > 0
        ? (widget.consumed / widget.target).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final ap = progress * _anim.value;
        final ac = (widget.consumed * _anim.value).round();
        return SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(112, 112),
                painter: _SmallRingPainter(progress: ap),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$ac',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'of ${widget.target.round()}',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Text(
                    'Consumed',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SmallRingPainter extends CustomPainter {
  final double progress;
  const _SmallRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const stroke = 9.0;
    final r = size.width / 2 - stroke / 2 - 3;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * pi * progress;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(
      rect,
      -pi / 2,
      sweepAngle,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: const [Color(0xFF56C271), Color(0xFF1A7A38)],
          startAngle: -pi / 2,
          endAngle: -pi / 2 + 2 * pi,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0.02) {
      final tipAngle = -pi / 2 + sweepAngle;
      final tip = Offset(
        c.dx + r * cos(tipAngle),
        c.dy + r * sin(tipAngle),
      );
      canvas.drawCircle(
        tip,
        stroke / 2 + 2,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(tip, stroke / 2 - 0.5, Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(_SmallRingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Macro progress bar row
// ─────────────────────────────────────────────────────────────────────────────

class _MacroProgressRow extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const _MacroProgressRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${current.round()}/${target.round()} g',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Water intake card
// ─────────────────────────────────────────────────────────────────────────────

class _WaterIntakeCard extends StatelessWidget {
  const _WaterIntakeCard();

  static const _totalGlasses = 8;
  static const _filledGlasses = 0;
  static const _mlConsumed = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      '$_mlConsumed ml',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(width: 8),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text(
                        'Water Consuming',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(_totalGlasses, (i) {
                    final filled = i < _filledGlasses;
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: PhosphorIcon(
                        PhosphorIcons.drop(
                          filled
                              ? PhosphorIconsStyle.fill
                              : PhosphorIconsStyle.regular,
                        ),
                        size: 21,
                        color: filled ? AppColors.primary : AppColors.divider,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'You drank $_filledGlasses of $_totalGlasses\nglasses of water',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick activity grid
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActivityGrid extends StatelessWidget {
  final HomeController ctrl;
  const _QuickActivityGrid({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Activity",
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActivityTile(
                icon: PhosphorIcons.personSimpleWalk(),
                label: 'Walk',
                value: '—',
                unit: 'Steps',
                bgColor: const Color(0xFFECF0FF),
                iconColor: const Color(0xFF5C7CFA),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() {
                int mins = 0;
                try {
                  mins = Get.find<WorkoutsController>()
                      .workouts
                      .fold(0, (s, w) => s + w.durationMinutes);
                } catch (_) {}
                return _ActivityTile(
                  icon: PhosphorIcons.barbell(),
                  label: 'Workouts',
                  value: mins > 0 ? '$mins' : '—',
                  unit: 'Minutes',
                  bgColor: AppColors.inputFill,
                  iconColor: AppColors.primary,
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActivityTile(
                icon: PhosphorIcons.bed(),
                label: 'Sleep',
                value: '—',
                unit: 'Hours',
                bgColor: const Color(0xFFFFF5E6),
                iconColor: const Color(0xFFF5A623),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() => _ActivityTile(
                icon: PhosphorIcons.star(),
                label: 'Daily Score',
                value: '${ctrl.dailyScore}',
                unit: 'Points',
                bgColor: AppColors.inputFill,
                iconColor: AppColors.primary,
              )),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final String value;
  final String unit;
  final Color bgColor;
  final Color iconColor;

  const _ActivityTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: PhosphorIcon(icon, size: 18, color: iconColor)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
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
// Motivation banner with female character
// ─────────────────────────────────────────────────────────────────────────────

class _MotivationBanner extends StatelessWidget {
  const _MotivationBanner();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final headline = hour < 12
        ? 'Good morning!'
        : hour < 17
            ? 'Keep pushing!'
            : 'Evening hustle!';
    final sub = hour < 12
        ? 'Start your day strong.'
        : hour < 17
            ? "You're doing great today."
            : 'Finish strong tonight.';

    return Container(
      height: 140,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.dashboardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle decorative circles
          Positioned(
            top: -24,
            right: 110,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -28,
            left: 16,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // Motivational text on the left
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            right: 138,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  sub,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text(
                    'View today\'s plan →',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Female character — clipped to card
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/meal_character.png',
              width: 130,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stack) => SizedBox(
                width: 130,
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.personSimpleRun(),
                    size: 56,
                    color: Colors.white.withValues(alpha: 0.30),
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
