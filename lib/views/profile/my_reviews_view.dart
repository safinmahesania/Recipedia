import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/my_reviews_controller.dart';
import '../../shared/widgets/recipe_image.dart';
import '../../theme/app_tokens.dart';
import '../recipes/recipe_details_view.dart';
import '../recipes/review_rating_view.dart';
import '../../shared/widgets/skeletons.dart';
import '../../shared/widgets/app_icon.dart';

/// Everything the user has written. The data existed from the start — there
/// was simply no screen that read it back.
class MyReviewsView extends StatefulWidget {
  const MyReviewsView({super.key});

  @override
  State<MyReviewsView> createState() => _MyReviewsViewState();
}

class _MyReviewsViewState extends State<MyReviewsView> {
  final MyReviewsController c = Get.put(MyReviewsController());

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('My reviews')),
      body: Obx(() {
        if (c.isLoading.value && c.reviews.isEmpty) {
          return const ListSkeleton(thumb: 48, card: true);
        }
        if (c.reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon('rate_review_outlined', fallback: Icons.rate_review_outlined,
                      size: AppSizes.iconXl, color: t.borderStrong),
                  const SizedBox(height: AppSizes.smd),
                  Text('No reviews yet',
                      style: text.titleLarge?.copyWith(fontSize: 16)),
                  const SizedBox(height: AppSizes.xs),
                  Text('Cook something and say how it went — it helps whoever '
                      'reads it next.',
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(color: t.textSecondary)),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: t.brand,
          onRefresh: c.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.screenPad),
            itemCount: c.reviews.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.smd),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.xs),
                  child: Text(
                    '${c.reviews.length} ${c.reviews.length == 1 ? 'review' : 'reviews'} '
                    '· ${c.average.toStringAsFixed(1)} average',
                    style: text.labelSmall?.copyWith(color: t.textSecondary),
                  ),
                );
              }
              final r = c.reviews[i - 1];
              final recipe = (r['recipes'] as Map<String, dynamic>?) ?? {};
              final stars = (r['rating'] ?? 0) as int;
              final comment = (r['comment'] ?? '').toString();
              final id = (recipe['id'] ?? '').toString();

              return Dismissible(
                key: ValueKey(r['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSizes.md),
                  decoration: BoxDecoration(
                    color: t.errorTint,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: AppIcon('delete_outline', fallback: Icons.delete_outline, color: t.onErrorTint),
                ),
                onDismissed: (_) => c.remove(r),
                child: InkWell(
                  onTap: id.isEmpty
                      ? null
                      : () => Get.to(() => RecipeDetailsView(recipeId: id)),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.smd),
                    decoration: BoxDecoration(
                      color: t.surfaceRaised,
                      border: Border.all(color: t.cardBorder),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      boxShadow: t.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          RecipeImage(
                            seed: id,
                            imageUrl: recipe['image_url'] as String?,
                            width: 48,
                            height: 48,
                            radius: AppSizes.radiusSm,
                          ),
                          const SizedBox(width: AppSizes.smd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text((recipe['title'] ?? 'Recipe') as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.titleMedium),
                                const SizedBox(height: 3),
                                Row(
                                  children: List.generate(
                                    5,
                                    (s) => Icon(
                                        s < stars
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: AppSizes.iconXs + 2,
                                        color: t.star),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (id.isNotEmpty)
                            IconButton(
                              icon: AppIcon('edit_outlined', fallback: Icons.edit_outlined,
                                  size: AppSizes.iconMd, color: t.textSecondary),
                              tooltip: 'Edit review',
                              onPressed: () async {
                                await Get.to(() => ReviewRatingView(
                                    recipeId: id,
                                    recipeTitle:
                                        (recipe['title'] ?? '') as String));
                                await c.load();
                              },
                            ),
                        ]),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.sm),
                          Text(comment,
                              style: text.bodyMedium?.copyWith(
                                  color: t.textSecondary, height: 1.45)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
