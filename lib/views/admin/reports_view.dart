import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/admin_controller.dart';

/// Moderation queue for reported recipes / reviews / users (FR18).
class ReportsView extends StatelessWidget {
  const ReportsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdminController c = Get.put(AdminController());
    c.loadReports();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Reports',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (c.reports.isEmpty) {
          return const Center(
              child: Text('No reports', style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: c.reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = c.reports[i];
            final reporter = (r['profiles'] as Map<String, dynamic>?)?['name'] ?? 'User';
            final open = r['status'] == 'open';
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.primaryTint, borderRadius: BorderRadius.circular(8)),
                      child: Text(r['target_type'] ?? '',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                    ),
                    const Spacer(),
                    Text(r['status'] ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            color: open ? AppColors.warning : AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 8),
                  Text(r['reason'] ?? '',
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('reported by $reporter',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  if (open) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => c.resolveReport(r['id'], 'dismissed'),
                          child: const Text('Dismiss'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0),
                          onPressed: () => c.resolveReport(r['id'], 'resolved'),
                          child: const Text('Resolve'),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
