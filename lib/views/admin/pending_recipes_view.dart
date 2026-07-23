import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/admin_controller.dart';

/// Approval queue for user-submitted recipes (FR35).
class PendingRecipesView extends StatelessWidget {
  const PendingRecipesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdminController c = Get.put(AdminController());
    c.loadPending();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Pending submissions',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (c.pending.isEmpty) {
          return const Center(
              child: Text('Nothing waiting for review',
                  style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: c.pending.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final r = c.pending[i];
            final author = (r['profiles'] as Map<String, dynamic>?)?['name'] ?? 'Unknown';
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['title'] ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('by $author',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Text(r['instructions'] ?? '',
                      maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error)),
                        onPressed: () => _rejectDialog(context, c, r['id']),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success, foregroundColor: Colors.white, elevation: 0),
                        onPressed: () => c.approve(r['id']),
                        child: const Text('Approve'),
                      ),
                    ),
                  ]),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  void _rejectDialog(BuildContext context, AdminController c, String recipeId) {
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject recipe'),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              c.reject(recipeId, reason.text.trim());
            },
            child: const Text('Reject', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
