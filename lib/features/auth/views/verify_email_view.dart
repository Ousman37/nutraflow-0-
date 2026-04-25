import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/gradient_button.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  late AuthController _authCtrl;
  Timer? _pollTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  String get _email {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      return args['email'] as String? ?? '';
    }
    return _authCtrl.firebaseUser.value?.email ?? '';
  }

  @override
  void initState() {
    super.initState();
    _authCtrl = Get.find<AuthController>();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await _authCtrl.checkEmailVerification(silent: true);
    });
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCooldown <= 1) {
        _cooldownTimer?.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    await _authCtrl.resendVerificationEmail();
    _startCooldown();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              _buildIllustration(),
              const SizedBox(height: 32),
              Text(
                'Check your email',
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "We sent a verification link to",
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _email,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Click the link in the email to verify your account. This page will continue automatically.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _buildCheckButton(),
              const SizedBox(height: 16),
              _buildResendButton(),
              const SizedBox(height: 24),
              _buildSignOutLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.mark_email_unread_rounded,
        color: Colors.white,
        size: 56,
      ),
    );
  }

  Widget _buildCheckButton() {
    return Obx(() => GradientButton(
          text: "I've verified my email",
          isLoading: _authCtrl.isLoading.value,
          onPressed: _authCtrl.checkEmailVerification,
        ));
  }

  Widget _buildResendButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _resendCooldown > 0 ? null : _resend,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _resendCooldown > 0 ? AppColors.divider : AppColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          _resendCooldown > 0
              ? 'Resend in ${_resendCooldown}s'
              : 'Resend verification email',
          style: AppTextStyles.labelLarge.copyWith(
            color:
                _resendCooldown > 0 ? AppColors.textHint : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutLink() {
    return GestureDetector(
      onTap: _authCtrl.signOut,
      child: Text(
        'Use a different account',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}
