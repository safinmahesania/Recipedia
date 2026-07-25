import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/submission_controller.dart';
import 'submit_recipe_view.dart';

/// The user's own submissions and their review status (FR36).
class MySubmissionsView extends StatelessWidget {
  const MySubmissionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final SubmissionController c = Get.put(SubmissionController());
    c.loadMySubmissions();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('My submissions',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Get.to(() => const SubmitRecipeView()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (c.mySubmissions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_note, size: 44, color: AppColors.border),
                SizedBox(height: 10),
                Text('You have not submitted any recipes yet',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: c.mySubmissions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = c.mySubmissions[i];
            final status = r['status'] ?? 'pending';
            final canEdit = status != 'approved';
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(r['title'] ?? '',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary)),
                    ),
                    _statusChip(status),
                  ]),
                  if (status == 'rejected' &&
                      (r['rejection_reason'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('Reason: ${r['rejection_reason']}',
                          style: const TextStyle(fontSize: 12, color: AppColors.error)),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(children: [
                    if (canEdit)
                      TextButton.icon(
                        onPressed: () => Get.to(() => SubmitRecipeView(existing: r)),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                      ),
                    if (canEdit)
                      TextButton.icon(
                        onPressed: () => _confirmDelete(context, c, r['id']),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      ),
                    if (!canEdit)
                      const Text('Published — edits go back for review',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  void _confirmDelete(BuildContext context, SubmissionController c, String id) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Delete submission'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              c.delete(id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
