import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import 'manage_recipe_view.dart';
import 'pending_recipes_view.dart';
import 'users_view.dart';
import 'feedback_view.dart';
import 'reports_view.dart';

/// Admin dashboard — entry point to all admin tools.
class AdminPortalView extends StatelessWidget {
  const AdminPortalView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(Icons.restaurant_menu, 'Recipes', 'Add, edit, delete', () => Get.to(() => const ManageRecipeView())),
      _Item(Icons.pending_actions, 'Pending submissions', 'Approve or reject', () => Get.to(() => const PendingRecipesView())),
      _Item(Icons.people_outline, 'Users', 'View all users', () => Get.to(() => const UsersView())),
      _Item(Icons.star_outline, 'Reviews', 'Ratings & comments', () => Get.to(() => const FeedbackView())),
      _Item(Icons.flag_outlined, 'Reports', 'Moderation queue', () => Get.to(() => const ReportsView())),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(AppStrings.adminPortal,
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final it = items[i];
          return InkWell(
            onTap: it.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.primaryTint, borderRadius: BorderRadius.circular(10)),
                  child: Icon(it.icon, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                      Text(it.subtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.border),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _Item(this.icon, this.title, this.subtitle, this.onTap);
}
