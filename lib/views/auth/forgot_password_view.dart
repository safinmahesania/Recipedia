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
              // The kit gives this screen a hero; login and signup deliberately
              // have none — they are forms people arrive at knowing what to do.
              Center(
                child: SizedBox(
                  height: 132,
                  width: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: t.categoryTints[3],
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusXl),
                        ),
                      ),
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: t.canvas.withValues(alpha: 0.5)),
                        ),
                      ),
                      AppIcon('key',
                          fallback: Icons.key,
                          size: 42,
                          color: t.categoryGlyphs[3]),
                      Positioned(
                        right: 12,
                        bottom: 16,
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.surfaceRaised,
                            boxShadow: t.cardShadow,
                          ),
                          child: AppIcon('lock',
                              fallback: Icons.lock,
                              size: 17,
                              color: t.categoryGlyphs[3]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
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
                icon: 'mail_outline',
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
