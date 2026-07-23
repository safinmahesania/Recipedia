import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../controllers/auth_controller.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';

class SignupView extends StatelessWidget {
  SignupView({Key? key}) : super(key: key);

  final AuthController auth = Get.put(AuthController());
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, foregroundColor: AppColors.textPrimary),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Sign up to get started', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 28),
              AppTextField(label: 'Name', hint: 'Your name', controller: name),
              const SizedBox(height: 16),
              AppTextField(label: 'Email', hint: 'you@email.com', controller: email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              AppTextField(label: 'Password', hint: '******', controller: password, obscure: true),
              const SizedBox(height: 24),
              Obx(() => PrimaryButton(
                    label: AppStrings.signup,
                    loading: auth.isLoading.value,
                    onTap: () => auth.signUp(name.text.trim(), email.text.trim(), password.text),
                  )),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Text('Login', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
