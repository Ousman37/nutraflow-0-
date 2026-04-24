import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../controllers/welcome_controller.dart';

// Pill data: (label, icon)
typedef _Pill = (String, PhosphorIconData);

final _rows = <List<_Pill>>[
  [
    ('Balanced Diet', PhosphorIcons.forkKnife()),
    ('High Protein', PhosphorIcons.barbell()),
    ('Vegan', PhosphorIcons.leaf()),
    ('Keto', PhosphorIcons.fire()),
    ('Mediterranean', PhosphorIcons.fish()),
    ('Low Carb', PhosphorIcons.plant()),
  ],
  [
    ('Weight Loss', PhosphorIcons.chartLineDown()),
    ('Muscle Gain', PhosphorIcons.barbell()),
    ('Maintenance', PhosphorIcons.scales()),
    ('Energy Boost', PhosphorIcons.lightning()),
    ('Detox', PhosphorIcons.drop()),
  ],
  [
    ('Calorie Tracking', PhosphorIcons.chartBar()),
    ('Meal Planning', PhosphorIcons.calendar()),
    ('Mindful Eating', PhosphorIcons.personSimpleTaiChi()),
    ('Intermittent Fasting', PhosphorIcons.clock()),
    ('Portion Control', PhosphorIcons.bowlFood()),
  ],
  [
    ('Hydration', PhosphorIcons.drop()),
    ('Sleep Better', PhosphorIcons.moon()),
    ('Stress Free', PhosphorIcons.leaf()),
    ('Heart Health', PhosphorIcons.heart()),
    ('Gut Health', PhosphorIcons.dna()),
    ('Bone Health', PhosphorIcons.bone()),
  ],
];

const _speeds = [22.0, 19.0, 25.0, 21.0];
bool _isReverse(int index) => index.isOdd;

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WelcomeController());
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildHeadline(),
            const SizedBox(height: 36),
            _buildPillRows(ctrl),
            const Spacer(),
            _buildCTAs(ctrl),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            height: 1.15,
          ),
          children: const [
            TextSpan(text: "Let's make\n"),
            TextSpan(
              text: 'your days',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.primary,
              ),
            ),
            TextSpan(text: '\nhealthier'),
          ],
        ),
      ),
    );
  }

  Widget _buildPillRows(WelcomeController ctrl) {
    return SizedBox(
      height: 4 * 46.0 + 3 * 10.0,
      child: Column(
        children: List.generate(_rows.length, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < _rows.length - 1 ? 10 : 0),
            child: _AutoScrollRow(
              pills: _rows[i],
              speed: _speeds[i],
              reverse: _isReverse(i),
              ctrl: ctrl,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCTAs(WelcomeController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          _DarkButton(
            ctrl: ctrl,
            onTap: () => Get.toNamed(
              AppRoutes.signup,
              arguments: {'interests': ctrl.selectedCategories.toList()},
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.login),
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Text(
                'I Already Have an Account',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
// Auto-scrolling pill row
// ─────────────────────────────────────────────────────────────────────────────

class _AutoScrollRow extends StatefulWidget {
  final List<_Pill> pills;
  final double speed;
  final bool reverse;
  final WelcomeController ctrl;

  const _AutoScrollRow({
    required this.pills,
    required this.speed,
    required this.reverse,
    required this.ctrl,
  });

  @override
  State<_AutoScrollRow> createState() => _AutoScrollRowState();
}

class _AutoScrollRowState extends State<_AutoScrollRow> {
  late final ScrollController _sc;
  Timer? _timer;

  List<_Pill> get _items => [
        ...widget.pills,
        ...widget.pills,
        ...widget.pills,
        ...widget.pills,
      ];

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  void _startScroll() {
    if (!mounted) return;
    final max = _sc.position.maxScrollExtent;
    final quarterMax = max / 4;
    _sc.jumpTo(quarterMax);
    _scheduleNext();
  }

  void _scheduleNext() {
    if (!mounted) return;
    final max = _sc.position.maxScrollExtent;
    final quarterMax = max / 4;
    final target = widget.reverse ? quarterMax : max - quarterMax;
    final current = _sc.offset;
    final distance = (target - current).abs();
    final ms = (distance / widget.speed * 1000).round();

    _timer?.cancel();
    _timer = Timer(Duration.zero, () async {
      if (!mounted) return;
      await _sc.animateTo(
        target,
        duration: Duration(milliseconds: ms),
        curve: Curves.linear,
      );
      if (mounted) {
        _sc.jumpTo(widget.reverse ? max - quarterMax : quarterMax);
        _scheduleNext();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        controller: _sc,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, icon) = _items[i];
          return _PillWidget(label: label, icon: icon, ctrl: widget.ctrl);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill widget — reactive, multi-selectable
// ─────────────────────────────────────────────────────────────────────────────

class _PillWidget extends StatelessWidget {
  final String label;
  final PhosphorIconData icon;
  final WelcomeController ctrl;

  const _PillWidget({
    required this.label,
    required this.icon,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = ctrl.isSelected(label);
      return GestureDetector(
        onTap: () => ctrl.toggle(label),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.10)
                : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE2E5F0),
              width: selected ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: selected ? 10 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
                child: Text(label),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: selected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 5),
                          Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dark CTA button — shows live selection count
// ─────────────────────────────────────────────────────────────────────────────

class _DarkButton extends StatelessWidget {
  final WelcomeController ctrl;
  final VoidCallback onTap;

  const _DarkButton({required this.ctrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Obx(() {
          final count = ctrl.selectedCategories.length;
          final label =
              count > 0 ? 'Get Started  ·  $count selected' : 'Get Started';
          return Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                key: ValueKey(label),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
