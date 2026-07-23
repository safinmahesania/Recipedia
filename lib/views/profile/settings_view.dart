import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import 'about_view.dart';
import 'faq_view.dart';

/// Settings: about, FAQ, logout.
class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.put(AuthController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Settings',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: ListView(
        children: [
          _tile(Icons.info_outline, 'About Us', () => Get.to(() => const AboutView())),
          _tile(Icons.help_outline, 'FAQs', () => Get.to(() => const FaqView())),
          const Divider(height: 1, color: AppColors.border),
          _tile(Icons.logout, 'Logout', () => _confirmLogout(context, auth),
              color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap, {Color? color}) => ListTile(
        leading: Icon(icon, color: color ?? AppColors.textSecondary),
        title: Text(title,
            style: TextStyle(color: color ?? AppColors.textPrimary, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.border),
        onTap: onTap,
      );

  void _confirmLogout(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              auth.logout();
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
