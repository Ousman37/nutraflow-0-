import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/subscription_controller.dart';
import '../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PaywallView — full-screen premium subscription screen
// ─────────────────────────────────────────────────────────────────────────────

class PaywallView extends StatelessWidget {
  const PaywallView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SubscriptionController>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF060D24),
        body: Stack(
          children: [
            // ── Gradient background ─────────────────────────────────────────
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF060D24),
                      Color(0xFF100840),
                      Color(0xFF1A0A50),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            // ── Ambient glow (top) ─────────────────────────────────────────
            Positioned(
              top: -100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.20),
                        AppColors.secondary.withValues(alpha: 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Scrollable content ─────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  _TopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          const _BrandHeader(),
                          const SizedBox(height: 28),
                          const _BenefitsList(),
                          const SizedBox(height: 24),
                          _PriceCard(ctrl: ctrl),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                  _BottomActions(ctrl: ctrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar — close button
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: Get.back,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand header
// ─────────────────────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App icon mark
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'NUTRAFLOW PRO',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary.withValues(alpha: 0.85),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Unlock Your Full\nNutrition Potential',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 29,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.20,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Everything you need to eat smarter,\nmove better, and build lasting habits.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: Colors.white.withValues(alpha: 0.50),
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Benefits list
// ─────────────────────────────────────────────────────────────────────────────

class _BenefitsList extends StatelessWidget {
  const _BenefitsList();

  @override
  Widget build(BuildContext context) {
    final benefits = [
      (
        icon: Icons.restaurant_menu_rounded,
        title: 'Unlimited Meal Tracking',
        subtitle: 'Log every meal without any daily limits',
      ),
      (
        icon: Icons.auto_awesome_rounded,
        title: 'AI Nutrition Insights',
        subtitle: 'Smart analysis of every food you photograph',
      ),
      (
        icon: Icons.local_fire_department_rounded,
        title: 'Progress & Streak Tracking',
        subtitle: 'Build healthy habits that last with daily streaks',
      ),
      (
        icon: Icons.fitness_center_rounded,
        title: 'Training Log',
        subtitle: 'Track workouts alongside your nutrition',
      ),
      (
        icon: Icons.menu_book_rounded,
        title: 'Full Meal History Journal',
        subtitle: 'Browse and revisit your complete nutrition history',
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: benefits
            .map((b) => _BenefitRow(
                  icon: b.icon,
                  title: b.title,
                  subtitle: b.subtitle,
                ))
            .toList(),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.48),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppColors.accent.withValues(alpha: 0.75),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan selector — Monthly / Yearly toggle
// ─────────────────────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final SubscriptionController ctrl;
  const _PriceCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = ctrl.selectedPlan.value;
      return Column(
        children: [
          // ── Yearly card ──────────────────────────────────────────────────
          _PlanTile(
            isSelected: selected == 'yearly',
            badge: 'BEST VALUE',
            title: 'Yearly',
            subtitle: 'Billed once a year · Cancel anytime',
            price: ctrl.yearlyPriceString.value,
            perPeriod: 'per year',
            savingsLabel: _yearlySavings(ctrl),
            onTap: () => ctrl.selectedPlan.value = 'yearly',
          ),
          const SizedBox(height: 10),
          // ── Monthly card ─────────────────────────────────────────────────
          _PlanTile(
            isSelected: selected == 'monthly',
            badge: null,
            title: 'Monthly',
            subtitle: 'Billed monthly · Cancel anytime',
            price: ctrl.monthlyPriceString.value,
            perPeriod: 'per month',
            savingsLabel: null,
            onTap: () => ctrl.selectedPlan.value = 'monthly',
          ),
        ],
      );
    });
  }

  // Shows "Save X%" label if both prices are available.
  String? _yearlySavings(SubscriptionController ctrl) {
    final monthly = ctrl.monthlyPackage.value?.storeProduct.price;
    final yearly = ctrl.yearlyPackage.value?.storeProduct.price;
    if (monthly == null || yearly == null || monthly == 0) return null;
    final annualIfMonthly = monthly * 12;
    final saving = ((annualIfMonthly - yearly) / annualIfMonthly * 100).round();
    if (saving <= 0) return null;
    return 'Save $saving%';
  }
}

class _PlanTile extends StatelessWidget {
  final bool isSelected;
  final String? badge;
  final String title;
  final String subtitle;
  final String price;
  final String perPeriod;
  final String? savingsLabel;
  final VoidCallback onTap;

  const _PlanTile({
    required this.isSelected,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.perPeriod,
    required this.savingsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.22),
                    AppColors.secondary.withValues(alpha: 0.16),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.70)
                : Colors.white.withValues(alpha: 0.10),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.25),
                  width: isSelected ? 5 : 1.5,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
            ),
            const SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (savingsLabel != null)
                  Text(
                    savingsLabel!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  )
                else
                  Text(
                    perPeriod,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.40),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom actions — CTA button + restore + fine print
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActions extends StatelessWidget {
  final SubscriptionController ctrl;
  const _BottomActions({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A0A50).withValues(alpha: 0.0),
            const Color(0xFF1A0A50),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary CTA
          Obx(() {
            final busy = ctrl.isPurchasing.value;
            return GestureDetector(
              onTap: busy
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      ctrl.purchase();
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: busy
                        ? [Colors.grey.shade800, Colors.grey.shade700]
                        : const [Color(0xFFFFB443), Color(0xFFFF8A30)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: busy
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFFFFB443).withValues(alpha: 0.40),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Obx(() => Text(
                          ctrl.selectedPlan.value == 'yearly'
                              ? 'Get Yearly · ${ctrl.yearlyPriceString.value}'
                              : 'Get Monthly · ${ctrl.monthlyPriceString.value}',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        )),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          // Restore purchases
          Obx(() {
            final busy = ctrl.isRestoring.value;
            return GestureDetector(
              onTap: busy ? null : ctrl.restorePurchases,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: busy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white.withValues(alpha: 0.40),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Restore Purchases',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.50),
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
              ),
            );
          }),
          const SizedBox(height: 10),
          Text(
            'Subscription renews automatically. Cancel anytime in App Store / Google Play settings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.26),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
