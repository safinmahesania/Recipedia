import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/auth_controller.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_tokens.dart';
import '../../shared/widgets/app_icon.dart';
import 'mail_sent_view.dart';

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
              Text('Forgot your\npassword?', style: text.headlineMedium),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Happens to everyone. Enter the email you signed up with and '
                "we'll send a link to set a new one.",
                style: text.bodyMedium
                    ?.copyWith(color: t.textSecondary, height: 1.5),
              ),
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
                    onTap: () async {
                      final email = _email.text.trim();
                      if (email.isEmpty) return;
                      await auth.forgotPassword(email);
                      if (!mounted) return;
                      Get.to(() => MailSentView(
                            title: 'Link sent',
                            email: email,
                            message: 'Check ',
                            changeLabel: 'Try another email',
                            onResend: () => auth.forgotPassword(email),
                          ));
                    },
                  )),
              const SizedBox(height: AppSizes.md),
              Container(
                padding: const EdgeInsets.all(AppSizes.smd),
                decoration: BoxDecoration(
                  color: t.surfaceRaised,
                  border: Border.all(color: t.cardBorder),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: t.cardShadow,
                ),
                child: Row(children: [
                  AppIcon('shield_outlined',
                      fallback: Icons.shield_outlined,
                      size: AppSizes.iconMd,
                      color: t.onAccentTint),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text('The link works once and expires after an hour.',
                        style: text.labelSmall
                            ?.copyWith(color: t.textSecondary)),
                  ),
                ]),
              ),
              const SizedBox(height: AppSizes.md),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Remembered it? ',
                        style: text.bodySmall
                            ?.copyWith(color: t.textSecondary)),
                    GestureDetector(
                      onTap: Get.back,
                      child: Text('Back to log in',
                          style: text.labelMedium
                              ?.copyWith(color: t.onBrandTint)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
