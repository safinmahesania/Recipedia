import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../services/auth_service.dart';
import '../../theme/app_tokens.dart';

/// Email, password and account deletion.
///
/// Account deletion is not optional if this ever ships on iOS — Apple requires
/// any app with account creation to offer in-app deletion.
class AccountSecurityView extends StatefulWidget {
  const AccountSecurityView({super.key});

  @override
  State<AccountSecurityView> createState() => _AccountSecurityViewState();
}

class _AccountSecurityViewState extends State<AccountSecurityView> {
  final AuthService _auth = AuthService();
  final ProfileController profile = Get.put(ProfileController());
  bool _busy = false;

  /// Keep in step with `version:` in pubspec.yaml. A hardcoded string beats a
  /// dependency for one label; swap to package_info_plus if this drifts.
  static const _version = '1.0.0 (1)';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final user = _auth.currentUser;
    final confirmed = user?.emailConfirmedAt != null;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Account and security')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.md,
            AppSizes.screenPad, AppSizes.xxl),
        children: [
          _Label('SIGN IN'),
          const SizedBox(height: AppSizes.sm),
          _Card(children: [
            _Row(
              icon: Icons.mail_outline,
              title: 'Email',
              subtitle: user?.email ?? '—',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm, vertical: AppSizes.xxs),
                decoration: BoxDecoration(
                  color: confirmed ? t.successTint : t.warningTint,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Text(confirmed ? 'Verified' : 'Unverified',
                    style: text.labelSmall?.copyWith(
                        color: confirmed ? t.onSuccessTint : t.onWarningTint,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            Divider(height: 1, color: t.border),
            _Row(
              icon: Icons.key_outlined,
              title: 'Change password',
              onTap: _busy ? null : _changePassword,
            ),
          ]),

          const SizedBox(height: AppSizes.lg),
          _Label('ABOUT'),
          const SizedBox(height: AppSizes.sm),
          _Card(children: [
            _Row(
              icon: Icons.info_outline,
              title: 'Version',
              trailing: Text(_version,
                  style: text.labelSmall?.copyWith(color: t.textSecondary)),
            ),
          ]),

          const SizedBox(height: AppSizes.lg),
          _Label('DANGER ZONE'),
          const SizedBox(height: AppSizes.sm),
          InkWell(
            onTap: _busy ? null : _deleteAccount,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: t.errorTint,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delete account',
                      style: text.titleMedium?.copyWith(color: t.onErrorTint)),
                  const SizedBox(height: 3),
                  Text(
                    'Removes your recipes, reviews, saved list and shopping '
                    'list. This cannot be undone.',
                    style: text.labelSmall
                        ?.copyWith(color: t.onErrorTint, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    final ctrl = TextEditingController();
    final confirm = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'New password'),
            ),
            const SizedBox(height: AppSizes.smd),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'Confirm new password'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('Update')),
        ],
      ),
    );

    final next = ctrl.text;
    final matches = next == confirm.text;
    ctrl.dispose();
    confirm.dispose();
    if (ok != true) return;

    if (next.length < 8) {
      Get.snackbar('Too short', 'Use at least 8 characters.');
      return;
    }
    if (!matches) {
      Get.snackbar('No match', 'Those two passwords are different.');
      return;
    }

    setState(() => _busy = true);
    try {
      await _auth.updatePassword(next);
      Get.snackbar('Updated', 'Your password has been changed.');
    } catch (_) {
      Get.snackbar('Not updated', 'Could not change your password.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    // Two-step on purpose: a single tap is too little friction for something
    // irreversible, so the second step requires typing the word.
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'Your recipes, reviews, saved list and shopping list will be '
            'permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(dctx).colorScheme.error),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Type DELETE to confirm'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'DELETE'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () =>
                Navigator.pop(dctx, ctrl.text.trim().toUpperCase() == 'DELETE'),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(dctx).colorScheme.error),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (confirmed != true) return;

    setState(() => _busy = true);
    final full = await _auth.deleteAccount();
    if (!mounted) return;
    if (!full) {
      Get.snackbar('Partially removed',
          'Your data is gone. The login itself is removed once the '
          'delete-account function is deployed.');
    }
    Get.put(AuthController()).logout();
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.tokens.textTertiary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ));
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        border: Border.all(color: t.cardBorder),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: t.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.smd),
        child: Row(children: [
          Icon(icon, size: AppSizes.iconMd, color: t.textSecondary),
          const SizedBox(width: AppSizes.smd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.bodyLarge),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall
                            ?.copyWith(color: t.textSecondary)),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (trailing == null && onTap != null)
            Icon(Icons.chevron_right, color: t.borderStrong),
        ]),
      ),
    );
  }
}
