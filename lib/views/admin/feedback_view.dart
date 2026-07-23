import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/admin_controller.dart';

class FeedbackView extends StatelessWidget {
  const FeedbackView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdminController c = Get.put(AdminController());
    c.loadReviews();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Reviews',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (c.reviews.isEmpty) {
          return const Center(
              child: Text('No reviews yet', style: TextStyle(color: AppColors.textSecondary)));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: c.reviews.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (_, i) {
            final r = c.reviews[i];
            final user = (r['profiles'] as Map<String, dynamic>?)?['name'] ?? 'User';
            final recipe = (r['recipes'] as Map<String, dynamic>?)?['title'] ?? '';
            final rating = r['rating'] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(recipe,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    const Spacer(),
                    ...List.generate(
                        5,
                        (s) => Icon(s < rating ? Icons.star : Icons.star_border,
                            size: 14, color: AppColors.star)),
                  ]),
                  const SizedBox(height: 3),
                  Text('by $user',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  if ((r['comment'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(r['comment'],
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
