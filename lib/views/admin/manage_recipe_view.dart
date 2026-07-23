import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/admin_controller.dart';
import 'edit_recipe_view.dart';

/// Admin recipe list: add, edit, delete.
class ManageRecipeView extends StatelessWidget {
  const ManageRecipeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdminController c = Get.put(AdminController());
    c.loadRecipes();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Recipes',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Get.to(() => const EditRecipeView()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (c.recipes.isEmpty) {
          return const Center(
              child: Text('No recipes', style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: c.recipes.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (_, i) {
            final r = c.recipes[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(r['title'] ?? '',
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
              subtitle: Row(children: [
                _statusChip(r['status'] ?? 'pending'),
                const SizedBox(width: 8),
                Text((r['categories'] as Map<String, dynamic>?)?['name'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                  onPressed: () => Get.to(() => EditRecipeView(recipe: r)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: () => _confirmDelete(context, c, r['id'], r['title'] ?? ''),
                ),
              ]),
            );
          },
        );
      }),
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'approved'
        ? AppColors.success
        : status == 'rejected'
            ? AppColors.error
            : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  void _confirmDelete(BuildContext context, AdminController c, String id, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete recipe'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              c.deleteRecipe(id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
