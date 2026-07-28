import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../controllers/auth_controller.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_tokens.dart';
import 'forgot_password_view.dart';
import 'signup_view.dart';
import '../../shared/widgets/auth_hero.dart';

/// Login. Now a StatefulWidget so the text controllers are disposed — they
/// were fields on a StatelessWidget before, which leaked them.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController auth = Get.put(AuthController());
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.smd),
              const PlateHero(),
              const SizedBox(height: AppSizes.lg),
              // Left-aligned like every other screen. A centred wordmark read
              // as a splash rather than the top of a form.
              Text('Welcome back', style: text.headlineMedium),
              const SizedBox(height: AppSizes.sm),
              Text('Log in to pick up where you left off.',
                  style: text.bodyMedium?.copyWith(color: t.textSecondary)),
              const SizedBox(height: AppSizes.xl),
              AppTextField(
                label: 'Email',
                hint: 'you@email.com',
                icon: 'mail_outline',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                label: 'Password',
                icon: 'lock',
                hint: 'Your password',
                controller: _password,
                obscure: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.to(() => const ForgotPasswordView()),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Obx(() => PrimaryButton(
                    label: AppStrings.login,
                    loading: auth.isLoading.value,
                    onTap: () =>
                        auth.login(_email.text.trim(), _password.text),
                  )),
              const SizedBox(height: AppSizes.lg),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.smd),
                  child: Text('or',
                      style:
                          text.labelSmall?.copyWith(color: t.textSecondary)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: AppSizes.lg),
              _SsoButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata,
                  onTap: auth.loginWithGoogle),
              const SizedBox(height: AppSizes.smd),
              _SsoButton(
                  label: 'Continue with Apple',
                  icon: Icons.apple,
                  onTap: auth.loginWithApple),
              const SizedBox(height: AppSizes.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New here? ',
                      style:
                          text.bodySmall?.copyWith(color: t.textSecondary)),
                  GestureDetector(
                    onTap: () => Get.to(() => const SignupView()),
                    child: Text('Create account',
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

class _SsoButton extends StatelessWidget {
  final String label;

  /// IconData, not a Tabler name: Tabler has no Google or Apple mark, and a
  /// generic fallback glyph on a "Continue with Google" button is worse than
  /// using Material's.
  final IconData icon;
  final VoidCallback onTap;

  const _SsoButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: AppSizes.iconMd),
        label: Text(label),
      );
}
