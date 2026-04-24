import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../controllers/home_controller.dart';
import '../widgets/circular_nutrition_progress.dart';
import '../widgets/weekday_selector.dart';
import '../../meal/models/meal_model.dart';
import '../../analytics/views/analytics_view.dart';
import '../../journal/views/journal_view.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../rewards/widgets/reward_progress_card.dart';
import '../../profile/views/profile_view.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reusable spring press — wraps any child with a scale-down-on-press animation
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
          _TabBody(ctrl: ctrl, tabIndex: 1, child: const AnalyticsView()),
          _TabBody(ctrl: ctrl, tabIndex: 2, child: const ProfileView()),
          _TabBody(ctrl: ctrl, tabIndex: 3, child: const JournalView()),
        ],
      ),
      bottomNavigationBar: _FloatingNav(ctrl: ctrl),
    );
  }
}

// Each tab owns its Obx — only its thin wrapper rebuilds on tab switch, not the child content.
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
    // Container decoration never changes — no Obx needed here.
    // Individual _NavIcon wrappers use Obx to react to tab changes only.
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
                      icon: Icons.calendar_month_outlined,
                      isActive: ctrl.selectedTabIndex.value == 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ctrl.selectedTabIndex.value = 0;
                      },
                    )),
                Obx(() => _NavIcon(
                      icon: Icons.trending_up_rounded,
                      isActive: ctrl.selectedTabIndex.value == 1,
                      onTap: () {
                        if (!Get.find<SubscriptionController>().requirePro()) {
                          return;
                        }
                        HapticFeedback.selectionClick();
                        ctrl.selectedTabIndex.value = 1;
                      },
                    )),
                // Centre FAB — translated upward so it protrudes above the bar.
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: _PressScale(
                    scale: 0.88,
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      final result =
                          await Get.toNamed(AppRoutes.selectMethod);
                      if (result == true) ctrl.refresh();
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withValues(alpha: 0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                Obx(() => _NavIcon(
                      icon: Icons.history_rounded,
                      isActive: ctrl.selectedTabIndex.value == 3,
                      onTap: () {
                        if (!Get.find<SubscriptionController>().requirePro()) {
                          return;
                        }
                        HapticFeedback.selectionClick();
                        ctrl.selectedTabIndex.value = 3;
                      },
                    )),
                Obx(() => _NavIcon(
                      icon: Icons.person_outline_rounded,
                      isActive: ctrl.selectedTabIndex.value == 2,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ctrl.selectedTabIndex.value = 2;
                      },
                    )),
              ],
            ),
          ),
          // Safe-area filler — fills home-indicator region with same dark colour.
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}

// Nav icon with animated scale-up + colour brightening + active dot indicator.
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.18 : 1.0,
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
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: isActive ? 4.0 : 0.0,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Home Tab
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final HomeController ctrl;
  const _HomeTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.dashboardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              _GreetingHeader(ctrl: ctrl),
              const SizedBox(height: 18),
              Obx(() => CircularNutritionProgress(
                    score: ctrl.dailyScore,
                    caloriesConsumed: ctrl.totalCalories,
                    caloriesTarget: ctrl.calorieTarget,
                    encouragementText: ctrl.scoreEncouragement,
                    levelText: ctrl.scoreLevel,
                  )),
              const SizedBox(height: 18),
              WeekdaySelector(ctrl: ctrl),
              const SizedBox(height: 16),
              Expanded(child: _MealPanel(ctrl: ctrl)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting header
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final HomeController ctrl;
  const _GreetingHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      'Hello, ${ctrl.userName}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    )),
                const SizedBox(height: 2),
                Text(
                  "You're on track to...",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          _PressScale(
            scale: 0.92,
            onTap: () => HapticFeedback.lightImpact(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
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

// ─────────────────────────────────────────────────────────────────────────────
// White rounded meal panel
// ─────────────────────────────────────────────────────────────────────────────

class _MealPanel extends StatelessWidget {
  final HomeController ctrl;
  const _MealPanel({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE0EE),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _PanelHeader(ctrl: ctrl),
          Expanded(
            child: RefreshIndicator(
              onRefresh: ctrl.refresh,
              color: AppColors.primary,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                20, 4, 20,
                MediaQuery.of(context).padding.bottom + 88,
              ),
                children: [
                  const RewardProgressCard(),
                  ...MealType.values
                    .where((t) => t != MealType.snack)
                    .map((type) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Obx(() => _MealRow(
                                mealType: type,
                                meal: ctrl.getMealByType(type),
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  final result = await Get.toNamed(
                                    AppRoutes.selectMethod,
                                    arguments: {'preselectedType': type},
                                  );
                                  if (result == true) ctrl.refresh();
                                },
                              )),
                        ))
                ,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel header
// ─────────────────────────────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final HomeController ctrl;
  const _PanelHeader({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Obx(() {
              final date = ctrl.selectedDate;
              final isToday = ctrl.selectedDateIsToday;
              final label = isToday
                  ? 'Today, ${DateFormat('d MMM yyyy').format(date)}'
                  : DateFormat('EEE, d MMM yyyy').format(date);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Obx(() => Text(
                        '${ctrl.loggedMealCount}/3 • ${ctrl.mealTimeGap}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      )),
                ],
              );
            }),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 17,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal row
// ─────────────────────────────────────────────────────────────────────────────

class _MealRow extends StatelessWidget {
  final MealType mealType;
  final MealModel? meal;
  final VoidCallback onTap;

  const _MealRow({
    required this.mealType,
    this.meal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLogged = meal != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _TappableCard(
            onTap: onTap,
            child: Row(
              children: [
                // Meal icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLogged
                        ? AppColors.primary.withValues(alpha: 0.07)
                        : const Color(0xFFF4F6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      mealType.icon,
                      size: 20,
                      color:
                          isLogged ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            mealType.label,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isLogged) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '+${meal!.nutrition.score}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLogged ? _buildSubtitle(meal!) : 'Tap to log meal',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Logged/unlogged indicator — animates between states
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: isLogged
                      ? Container(
                          key: const ValueKey('logged'),
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.navBarDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      : Container(
                          key: const ValueKey('unlogged'),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFCDD0E3),
                              width: 1.5,
                            ),
                            color: Colors.transparent,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: AppColors.textSecondary,
                            size: 17,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        // Time label
        if (isLogged) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44,
              height: 48,
              child: Center(
                child: Text(
                  _formatTime(meal!.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ] else
          const SizedBox(width: 48),
      ],
    );
  }

  String _buildSubtitle(MealModel m) {
    if (m.description != null && m.description!.trim().isNotEmpty) {
      return m.description!.trim();
    }
    if (m.name.isNotEmpty) return m.name;
    return '${m.nutrition.calories.round()} kcal';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tappable card — spring-press scale with shadow lift
// ─────────────────────────────────────────────────────────────────────────────

class _TappableCard extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TappableCard({required this.onTap, required this.child});

  static const _r = 16.0;
  static const _padding = EdgeInsets.symmetric(horizontal: 14, vertical: 13);

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      onTap: onTap,
      scale: 0.97,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_r),
          clipBehavior: Clip.hardEdge,
          child: Container(
            padding: _padding,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFEEF0F8)),
              borderRadius: BorderRadius.circular(_r),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
