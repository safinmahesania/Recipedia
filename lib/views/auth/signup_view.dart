import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../controllers/auth_controller.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_tokens.dart';

/// Create account. StatefulWidget so the three controllers are disposed.
class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final AuthController auth = Get.put(AuthController());
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
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
              Text('Create account', style: text.headlineMedium),
              const SizedBox(height: AppSizes.xs + 2),
              Text('Sign up to get started',
                  style: text.bodyMedium?.copyWith(color: t.textSecondary)),
              const SizedBox(height: AppSizes.xl),
              AppTextField(label: 'Name', hint: 'Your name', controller: _name),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                label: 'Email',
                hint: 'you@email.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                label: 'Password',
                hint: 'At least 8 characters',
                controller: _password,
                obscure: true,
              ),
              const SizedBox(height: AppSizes.lg),
              Obx(() => PrimaryButton(
                    label: AppStrings.signup,
                    loading: auth.isLoading.value,
                    onTap: () => auth.signUp(_name.text.trim(),
                        _email.text.trim(), _password.text),
                  )),
              const SizedBox(height: AppSizes.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style:
                          text.bodySmall?.copyWith(color: t.textSecondary)),
                  GestureDetector(
                    onTap: Get.back,
                    child: Text('Log in',
                        style:
                            text.labelMedium?.copyWith(color: t.onBrandTint)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
