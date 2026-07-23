import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/admin_controller.dart';

class UsersView extends StatelessWidget {
  const UsersView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdminController c = Get.put(AdminController());
    c.loadUsers();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Users',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (c.users.isEmpty) {
          return const Center(
              child: Text('No users', style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: c.users.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (_, i) {
            final u = c.users[i];
            final isAdmin = u['role'] == 'admin';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryTint,
                child: Text((u['name'] ?? '?').toString().characters.first.toUpperCase(),
                    style: const TextStyle(color: AppColors.primary)),
              ),
              title: Text(u['name'] ?? 'Unnamed',
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
              subtitle: Text(u['email'] ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              trailing: isAdmin
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.accentTint, borderRadius: BorderRadius.circular(8)),
                      child: const Text('Admin',
                          style: TextStyle(fontSize: 11, color: AppColors.accentDark)),
                    )
                  : null,
            );
          },
        );
      }),
    );
  }
}
