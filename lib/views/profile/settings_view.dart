import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../theme/app_tokens.dart';
import '../admin/admin_portal_view.dart';
import '../submissions/my_submissions_view.dart';
import 'about_view.dart';
import 'faq_view.dart';

/// Settings: submissions, admin (admins only), about, FAQ, logout.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.put(AuthController());
    final ProfileController profile = Get.put(ProfileController());
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _Tile(Icons.edit_note, 'My submissions',
              () => Get.to(() => const MySubmissionsView())),

          // Admins are normal users with one extra entry. Hiding it is a
          // convenience; RLS is what actually enforces the permission.
          Obx(() => profile.profile.value?.isAdmin == true
              ? _Tile(Icons.admin_panel_settings_outlined, 'Admin portal',
                  () => Get.to(() => const AdminPortalView()))
              : const SizedBox.shrink()),

          Divider(height: 1, color: t.border),
          _Tile(Icons.info_outline, 'About us',
              () => Get.to(() => const AboutView())),
          _Tile(Icons.help_outline, 'FAQs', () => Get.to(() => const FaqView())),
          Divider(height: 1, color: t.border),
          _Tile(Icons.logout, 'Log out', () => _confirmLogout(context, auth),
              danger: true),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              auth.logout();
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;
  const _Tile(this.icon, this.title, this.onTap, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = danger ? t.error : null;
    return ListTile(
      leading: Icon(icon, color: fg ?? t.textSecondary),
      title: Text(title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: fg)),
      trailing: danger
          ? null
          : Icon(Icons.chevron_right, color: t.borderStrong),
      onTap: onTap,
    );
  }
}
