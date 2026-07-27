import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/admin_controller.dart';
import '../../theme/app_tokens.dart';
import '../../shared/widgets/skeletons.dart';

/// Every review across the catalogue. StatefulWidget because loadReviews()
/// was firing from build() on every rebuild.
class FeedbackView extends StatefulWidget {
  const FeedbackView({super.key});

  @override
  State<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<FeedbackView> {
  final AdminController c = Get.put(AdminController());

  @override
  void initState() {
    super.initState();
    c.loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Reviews')),
      body: Obx(() {
        if (c.isLoading.value) {
          return const ListSkeleton(thumb: 0);
        }
        if (c.reviews.isEmpty) {
          return const EmptyState(
            icon: Icons.star_outline,
            title: 'No reviews yet',
            message: 'Ratings and comments across the catalogue show up here.',
          );
        }
        return RefreshIndicator(
          color: t.brand,
          onRefresh: c.loadReviews,
          child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPad),
          itemCount: c.reviews.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
          itemBuilder: (_, i) {
            final r = c.reviews[i];
            final user =
                (r['profiles'] as Map<String, dynamic>?)?['name'] ?? 'User';
            final recipe =
                (r['recipes'] as Map<String, dynamic>?)?['title'] ?? '';
            final rating = (r['rating'] ?? 0) as int;
            final comment = (r['comment'] ?? '').toString();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.smd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text('$recipe', style: text.titleMedium)),
                    const SizedBox(width: AppSizes.sm),
                    ...List.generate(
                      5,
                      (s) => Icon(s < rating ? Icons.star : Icons.star_border,
                          size: AppSizes.iconXs + 2, color: t.star),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text('by $user',
                      style: text.labelSmall?.copyWith(color: t.textSecondary)),
                  if (comment.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.sm),
                    Text(comment,
                        style: text.bodyMedium
                            ?.copyWith(color: t.textSecondary, height: 1.45)),
                  ],
                ],
              ),
            );
            },
          ),
        );
      }),
    );
  }
}
