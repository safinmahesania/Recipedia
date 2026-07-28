import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_tokens.dart';
import '../home/main_shell.dart';

/// Where a password-reset link lands.
///
/// Before this, "Forgot password" sent an email, the link opened the app, and
/// nothing happened — Supabase raises a passwordRecovery event that no one was
/// listening for, so the flow dead-ended at the point it mattered.
class SetPasswordView extends StatefulWidget {
  const SetPasswordView({super.key});

  @override
  State<SetPasswordView> createState() => _SetPasswordViewState();
}

class _SetPasswordViewState extends State<SetPasswordView> {
  final AuthService _auth = AuthService();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_password, _confirm]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? get _error {
    if (_password.text.isEmpty) return null;
    if (_password.text.length < 8) return 'At least 8 characters';
    if (_confirm.text.isNotEmpty && _confirm.text != _password.text) {
      return 'Those two do not match';
    }
    return null;
  }

  bool get _canSubmit =>
      _password.text.length >= 8 && _confirm.text == _password.text;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await _auth.updatePassword(_password.text);
      if (!mounted) return;
      // The recovery link already signed them in, so there is nothing to log
      // into — go straight to the app.
      Get.offAll(() => const MainShell());
      Get.snackbar('Password changed', 'You are signed in.');
    } catch (_) {
      if (!mounted) return;
      Get.snackbar('Not changed',
          'That link may have expired. Request a new one and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.xl),
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.brandTint,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: AppIcon('key', size: 26, color: t.onBrandTint),
              ),
              const SizedBox(height: AppSizes.lg),
              Text('Set a new password', style: text.headlineMedium),
              const SizedBox(height: AppSizes.sm),
              Text('Pick something you have not used here before.',
                  style: text.bodyMedium?.copyWith(color: t.textSecondary)),

              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'New password',
                icon: 'lock',
                hint: 'At least 8 characters',
                controller: _password,
                obscure: true,
                errorText: _error,
              ),
              const SizedBox(height: AppSizes.md),
              AppTextField(
                label: 'Confirm password',
                icon: 'lock',
                hint: 'Type it again',
                controller: _confirm,
                obscure: true,
              ),

              const SizedBox(height: AppSizes.lg),
              PrimaryButton(
                label: 'Save and continue',
                loading: _busy,
                onTap: _canSubmit ? _save : () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
