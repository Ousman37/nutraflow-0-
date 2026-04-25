import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../routes/app_routes.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late AuthController _authCtrl;

  @override
  void initState() {
    super.initState();
    _authCtrl = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildForm(),
                const SizedBox(height: 32),
                _buildSignInButton(),
                const SizedBox(height: 24),
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.restaurant_menu_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(height: 24),
        Text('Welcome back', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue your nutrition journey',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        CustomTextField(
          label: 'Email',
          hint: 'you@example.com',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.email_outlined,
              color: AppColors.textHint, size: 20),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!GetUtils.isEmail(v.trim())) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Password',
          hint: '••••••••',
          controller: _passCtrl,
          obscureText: true,
          textInputAction: TextInputAction.done,
          prefixIcon: const Icon(Icons.lock_outline,
              color: AppColors.textHint, size: 20),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 6) return 'At least 6 characters';
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
            child: Text('Forgot password?',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Obx(() => GradientButton(
          text: 'Sign In',
          isLoading: _authCtrl.isLoading.value,
          onPressed: _submit,
        ));
  }

  Widget _buildSignUpLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "Don't have an account? ",
              style: AppTextStyles.bodyMedium,
            ),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.signup),
                child: Text(
                  'Sign Up',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _authCtrl.signIn(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );
  }
}
