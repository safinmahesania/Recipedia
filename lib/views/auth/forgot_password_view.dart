import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/auth_controller.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_tokens.dart';

/// Password reset request. StatefulWidget so the controller is disposed.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final AuthController auth = Get.put(AuthController());
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Forgot password', style: text.headlineMedium),
              const SizedBox(height: AppSizes.xs + 2),
              Text("Enter your email and we'll send a reset link.",
                  style: text.bodyMedium?.copyWith(color: t.textSecondary)),
              const SizedBox(height: AppSizes.xl),
              AppTextField(
                label: 'Email',
                hint: 'you@email.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSizes.lg),
              Obx(() => PrimaryButton(
                    label: 'Send reset link',
                    loading: auth.isLoading.value,
                    onTap: () => auth.forgotPassword(_email.text.trim()),
                  )),
              const SizedBox(height: AppSizes.md),
              Center(
                child: TextButton(
                  onPressed: Get.back,
                  child: const Text('Back to login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
