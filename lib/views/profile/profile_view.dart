import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import 'settings_view.dart';

/// Profile tab: avatar, name/email, edit name, link to settings.
class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProfileController c = Get.put(ProfileController());
    final nameCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () => Get.to(() => const SettingsView()),
          ),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value && c.profile.value == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final p = c.profile.value;
        nameCtrl.text = p?.name ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryTint,
                backgroundImage:
                    (p?.avatarUrl != null && p!.avatarUrl!.isNotEmpty)
                        ? NetworkImage(p.avatarUrl!)
                        : null,
                child: (p?.avatarUrl == null || p!.avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(p?.name ?? '',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(p?.email ?? '',
                  style: const TextStyle(color: AppColors.textSecondary)),
              if (p?.isAdmin == true) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.accentTint, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Admin',
                      style: TextStyle(fontSize: 12, color: AppColors.accentDark)),
                ),
              ],
              const SizedBox(height: 28),
              AppTextField(label: 'Name', hint: 'Your name', controller: nameCtrl),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Save changes',
                onTap: () => c.updateName(nameCtrl.text.trim()),
              ),
            ],
          ),
        );
      }),
    );
  }
}
