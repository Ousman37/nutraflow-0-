import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/subscription_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/legal_links.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Trial info — derived entirely from the live StoreProduct + this user's
// real eligibility (never hardcoded). A package only counts as an eligible
// free trial when it has a $0 introductory price AND
// Purchases.checkTrialOrIntroductoryPriceEligibility() confirmed this
// specific customer qualifies for it.
// ─────────────────────────────────────────────────────────────────────────────

class _TrialInfo {
  final bool isEligibleFreeTrial;
  final String? lengthLabel; // e.g. "7 days"
  const _TrialInfo({required this.isEligibleFreeTrial, this.lengthLabel});
}

_TrialInfo _resolveTrialInfo(Package? package, bool eligible) {
  final intro = package?.storeProduct.introductoryPrice;
  if (package == null || intro == null || intro.price != 0 || !eligible) {
    return const _TrialInfo(isEligibleFreeTrial: false);
  }
  final n = intro.periodNumberOfUnits;
  final unitLabel = switch (intro.periodUnit) {
    PeriodUnit.day => n == 1 ? 'day' : 'days',
    PeriodUnit.week => n == 1 ? 'week' : 'weeks',
    PeriodUnit.month => n == 1 ? 'month' : 'months',
    PeriodUnit.year => n == 1 ? 'year' : 'years',
    PeriodUnit.unknown => n == 1 ? 'day' : 'days',
  };
  return _TrialInfo(isEligibleFreeTrial: true, lengthLabel: '$n $unitLabel');
}

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
    // Reached two ways: pushed on top of an already-entitled screen (e.g. a
    // free user tapped a Pro feature) — poppable, show the usual close
    // button — or as the hard access gate right after onboarding/login with
    // no active entitlement, where the paywall is the entire navigation
    // stack. There's nothing to "close" back to in that case, so offer Sign
    // Out instead: a subscription is required to use the app, but a user
    // who doesn't want to subscribe must still be able to leave the account
    // rather than being stuck on a screen with no way out at all.
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment:
            canPop ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
        children: [
          if (!canPop)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Get.find<AuthController>().signOut();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  'Sign Out',
                  style: TextStyle(fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          if (canPop)
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
          style: TextStyle(fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary.withValues(alpha: 0.85),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Unlock Your Full\nNutrition Potential',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'PlusJakartaSans',
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
          style: TextStyle(fontFamily: 'PlusJakartaSans',
            fontSize: 14.5,
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
                  style: TextStyle(fontFamily: 'PlusJakartaSans',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: 'PlusJakartaSans',
                    fontSize: 12.5,
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

// ───────────────────────────────────────────────────────────────────────────── paywall
// Plan selector — Monthly / Yearly toggle
// ─────────────────────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final SubscriptionController ctrl;
  const _PriceCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = ctrl.selectedPlan.value;
      // isLoadingOfferings/offeringsFailed are read here so this whole card
      // rebuilds on every state change — the price Text is never allowed to
      // show the "···" not-loaded placeholder to the user.
      final loading = ctrl.isLoadingOfferings.value;
      final failed = ctrl.offeringsFailed.value;

      final yearlyTrial =
          _resolveTrialInfo(ctrl.yearlyPackage.value, ctrl.isYearlyTrialEligible.value);
      final monthlyTrial =
          _resolveTrialInfo(ctrl.monthlyPackage.value, ctrl.isMonthlyTrialEligible.value);

      return Column(
        children: [
          // ── Yearly card ──────────────────────────────────────────────────
          _PlanTile(
            isSelected: selected == 'yearly',
            badge: yearlyTrial.isEligibleFreeTrial
                ? '${yearlyTrial.lengthLabel!.toUpperCase()} FREE'
                : 'BEST VALUE',
            title: 'Yearly',
            subtitle: yearlyTrial.isEligibleFreeTrial
                ? '${yearlyTrial.lengthLabel} free, then billed yearly'
                : 'Billed once a year · Cancel anytime',
            price: failed ? 'Unavailable' : ctrl.yearlyPriceString.value,
            isLoading: loading,
            perPeriod: 'per year',
            savingsLabel: yearlyTrial.isEligibleFreeTrial ? null : _yearlySavings(ctrl),
            onTap: () => ctrl.selectedPlan.value = 'yearly',
          ),
          const SizedBox(height: 10),
          // ── Monthly card ─────────────────────────────────────────────────
          _PlanTile(
            isSelected: selected == 'monthly',
            badge: monthlyTrial.isEligibleFreeTrial
                ? '${monthlyTrial.lengthLabel!.toUpperCase()} FREE'
                : null,
            title: 'Monthly',
            subtitle: monthlyTrial.isEligibleFreeTrial
                ? '${monthlyTrial.lengthLabel} free, then billed monthly'
                : 'Billed monthly · Cancel anytime',
            price: failed ? 'Unavailable' : ctrl.monthlyPriceString.value,
            isLoading: loading,
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
  final bool isLoading;
  final String perPeriod;
  final String? savingsLabel;
  final VoidCallback onTap;

  const _PlanTile({
    required this.isSelected,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isLoading,
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
                        style: TextStyle(fontFamily: 'PlusJakartaSans',
                          fontSize: 15,
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
                            style: TextStyle(fontFamily: 'PlusJakartaSans',
                              fontSize: 10,
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
                    style: TextStyle(fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
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
                isLoading
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      )
                    : Text(
                        price,
                        style: TextStyle(fontFamily: 'PlusJakartaSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                Text(
                  perPeriod,
                  style: TextStyle(fontFamily: 'PlusJakartaSans',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.40),
                  ),
                ),
                if (savingsLabel != null)
                  Text(
                    savingsLabel!,
                    style: TextStyle(fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
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
          // Primary CTA — spinner while purchasing or while offerings are
          // still loading; "Retry" once loading has failed; otherwise the
          // normal buy button. Same button, same styling throughout — only
          // the label/tap-target change with state.
          Obx(() {
            final purchasing = ctrl.isPurchasing.value;
            final loadingOfferings = ctrl.isLoadingOfferings.value;
            final failed = ctrl.offeringsFailed.value;
            final spinner = purchasing || loadingOfferings;
            final isYearly = ctrl.selectedPlan.value == 'yearly';
            final trial = _resolveTrialInfo(
              isYearly ? ctrl.yearlyPackage.value : ctrl.monthlyPackage.value,
              isYearly
                  ? ctrl.isYearlyTrialEligible.value
                  : ctrl.isMonthlyTrialEligible.value,
            );
            final selectedPrice =
                isYearly ? ctrl.yearlyPriceString.value : ctrl.monthlyPriceString.value;
            final ctaLabel = trial.isEligibleFreeTrial
                ? 'Start ${trial.lengthLabel!} Free Trial'
                : 'Continue · $selectedPrice';

            return GestureDetector(
              onTap: spinner
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      if (failed) {
                        ctrl.retryLoadOfferings();
                      } else {
                        ctrl.purchase();
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: spinner
                        ? [Colors.grey.shade800, Colors.grey.shade700]
                        : const [Color(0xFFFFB443), Color(0xFFFF8A30)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: spinner
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
                  child: spinner
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          failed ? 'Retry' : ctaLabel,
                          style: TextStyle(fontFamily: 'PlusJakartaSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                ),
              ),
            );
          }),
          // "N days free, then $X/period" — only shown for an eligible free
          // trial, always using the real localized renewal price, never a
          // hardcoded number.
          Obx(() {
            final isYearly = ctrl.selectedPlan.value == 'yearly';
            final trial = _resolveTrialInfo(
              isYearly ? ctrl.yearlyPackage.value : ctrl.monthlyPackage.value,
              isYearly
                  ? ctrl.isYearlyTrialEligible.value
                  : ctrl.isMonthlyTrialEligible.value,
            );
            if (!trial.isEligibleFreeTrial) return const SizedBox(height: 14);
            final price = isYearly
                ? ctrl.yearlyPriceString.value
                : ctrl.monthlyPriceString.value;
            final period = isYearly ? 'year' : 'month';
            return Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text(
                '${trial.lengthLabel} free, then $price/$period · Cancel anytime',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'PlusJakartaSans',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
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
                        style: TextStyle(fontFamily: 'PlusJakartaSans',
                          fontSize: 14,
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
            // Platform-specific: App Store review (Guideline 2.3.10)
            // rejects any Google Play / Android store wording appearing in
            // the iOS binary's UI — never show it there.
            Platform.isIOS
                ? 'Subscription renews automatically. Cancel anytime in your App Store account settings.'
                : 'Subscription renews automatically. Cancel anytime in your Google Play account settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.26),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const _LegalLinksRow(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legal links — open the public Privacy Policy / Terms of Use webpages
// ─────────────────────────────────────────────────────────────────────────────

class _LegalLinksRow extends StatelessWidget {
  const _LegalLinksRow();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        'Unable to open link',
        'Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.45),
      decoration: TextDecoration.underline,
      decorationColor: Colors.white.withValues(alpha: 0.22),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _open(LegalLinks.privacyPolicy),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Text('Privacy Policy', style: style),
          ),
        ),
        Text(
          '·',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ),
        GestureDetector(
          onTap: () => _open(LegalLinks.termsOfUse),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Text('Terms of Use', style: style),
          ),
        ),
      ],
    );
  }
}
