import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../routes/app_routes.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
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
    _nameCtrl.dispose();
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
                GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 28),
                Text('Create account', style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Start your personalized nutrition journey',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 36),
                CustomTextField(
                  label: 'Full Name',
                  hint: 'Your name',
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.textHint, size: 20),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 32),
                Obx(() => GradientButton(
                      text: 'Create Account',
                      isLoading: _authCtrl.isLoading.value,
                      onPressed: _submit,
                    )),
                const SizedBox(height: 24),
                Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Already have an account? ',
                          style: AppTextStyles.bodyMedium,
                        ),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.login),
                            child: Text(
                              'Sign In',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _authCtrl.signUp(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );
  }
}
