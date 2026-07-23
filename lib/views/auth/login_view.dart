import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../controllers/auth_controller.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import 'signup_view.dart';
import 'forgot_password_view.dart';

class LoginView extends StatelessWidget {
  LoginView({Key? key}) : super(key: key);

  final AuthController auth = Get.put(AuthController());
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 6),
              const Text('Login to continue',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              AppTextField(label: 'Email', hint: 'you@email.com', controller: email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              AppTextField(label: 'Password', hint: '******', controller: password, obscure: true),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.to(() => ForgotPasswordView()),
                  child: const Text('Forgot password?', style: TextStyle(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 4),
              Obx(() => PrimaryButton(
                    label: AppStrings.login,
                    loading: auth.isLoading.value,
                    onTap: () => auth.login(email.text.trim(), password.text),
                  )),
              const SizedBox(height: 20),
              const Row(children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or', style: TextStyle(color: AppColors.textSecondary))),
                Expanded(child: Divider(color: AppColors.border)),
              ]),
              const SizedBox(height: 20),
              _sso('Continue with Google', Icons.g_mobiledata, () => auth.loginWithGoogle()),
              const SizedBox(height: 12),
              _sso('Continue with Apple', Icons.apple, () => auth.loginWithApple()),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () => Get.to(() => SignupView()),
                  child: const Text('Sign up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sso(String label, IconData icon, VoidCallback onTap) => SizedBox(
        height: 50,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onTap,
          icon: Icon(icon, color: AppColors.textPrimary),
          label: Text(label),
        ),
      );
}
