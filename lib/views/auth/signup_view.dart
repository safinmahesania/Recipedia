import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/auth_controller.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_tokens.dart';

/// Step 1 of 4. Account creation is the first onboarding step, not a separate
/// errand — the kit shows one continuous progress bar from here through diet,
/// allergies and staples, and stopping the count at signup made the rest feel
/// like an unrelated interruption after logging in.
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
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _email, _password]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// 0 none · 1 weak · 2 fair · 3 strong.
  ///
  /// Length first, because it matters more than symbol soup: a 12-character
  /// passphrase beats "P@ss1" comfortably. Variety only lifts a password that
  /// is already long enough to be worth lifting.
  int get _strength {
    final p = _password.text;
    if (p.isEmpty) return 0;
    if (p.length < 8) return 1;
    var variety = 0;
    if (RegExp(r'[a-z]').hasMatch(p)) variety++;
    if (RegExp(r'[A-Z]').hasMatch(p)) variety++;
    if (RegExp(r'\d').hasMatch(p)) variety++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) variety++;
    if (p.length >= 12 && variety >= 2) return 3;
    if (variety >= 3) return 3;
    return 2;
  }

  static const _strengthLabel = ['', 'Too short', 'Fair password', 'Strong password'];

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty &&
      _email.text.trim().contains('@') &&
      _password.text.length >= 8 &&
      _agreed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final strength = _strength;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPad, 0, AppSizes.screenPad, AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Step 1 of 4',
                  style: text.labelSmall?.copyWith(color: t.textSecondary)),
              const SizedBox(height: AppSizes.sm),
              Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: i == 3 ? 0 : AppSizes.xs + 1),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i == 0 ? t.brandFill : t.surface,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.lg),
              Text('Create your account', style: text.headlineMedium),
              const SizedBox(height: AppSizes.lg),

              AppTextField(
                  label: 'Name',
                  hint: 'Your name',
                  icon: 'person',
                  controller: _name),
              const SizedBox(height: AppSizes.md),
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
                hint: 'At least 8 characters',
                controller: _password,
                obscure: true,
              ),

              if (strength > 0) ...[
                const SizedBox(height: AppSizes.sm),
                Row(children: [
                  ...List.generate(
                    3,
                    (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: i == 2 ? AppSizes.sm : AppSizes.xs),
                        child: AnimatedContainer(
                          duration: AppSizes.durFast,
                          height: 3,
                          decoration: BoxDecoration(
                            color: i < strength
                                ? (strength == 1
                                    ? t.error
                                    : strength == 2
                                        ? t.warning
                                        : t.success)
                                : t.surface,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(_strengthLabel[strength],
                      style: text.labelSmall?.copyWith(
                          color: strength == 1
                              ? t.error
                              : strength == 2
                                  ? t.onWarningTint
                                  : t.onSuccessTint)),
                ]),
              ],

              const SizedBox(height: AppSizes.md),
              // Consent gates the button rather than sitting decoratively
              // beside it. The links are inert until a policy is hosted and
              // url_launcher is added — see docs/BACKLOG.md.
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: AppSizes.durFast,
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _agreed ? t.brandFill : Colors.transparent,
                        border: _agreed
                            ? null
                            : Border.all(color: t.borderStrong, width: 1.6),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusXs),
                      ),
                      child: _agreed
                          ? AppIcon('check',
                              fallback: Icons.check,
                              size: 13,
                              color: t.onBrandFill)
                          : null,
                    ),
                    const SizedBox(width: AppSizes.smd),
                    Expanded(
                      child: Text(
                        'I agree to the Terms and Privacy Policy',
                        style: text.bodySmall?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.lg),
              Obx(() => PrimaryButton(
                    label: 'Continue',
                    loading: auth.isLoading.value,
                    onTap: _canSubmit
                        ? () => auth.signUp(_name.text.trim(),
                            _email.text.trim(), _password.text)
                        : () {},
                  )),
              if (!_canSubmit)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.sm),
                  child: Center(
                    child: Text(
                      !_agreed && _password.text.length >= 8
                          ? 'Accept the terms to continue'
                          : 'Fill in every field to continue',
                      style:
                          text.labelSmall?.copyWith(color: t.textTertiary),
                    ),
                  ),
                ),

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
