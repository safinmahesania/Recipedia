import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/review_controller.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_tokens.dart';
import '../../shared/widgets/skeletons.dart';
import '../../shared/widgets/app_icon.dart';

/// Rate and review a recipe, and read what others said.
class ReviewRatingView extends StatefulWidget {
  final String recipeId;
  final String recipeTitle;
  const ReviewRatingView(
      {super.key, required this.recipeId, this.recipeTitle = ''});

  @override
  State<ReviewRatingView> createState() => _ReviewRatingViewState();
}

class _ReviewRatingViewState extends State<ReviewRatingView> {
  final ReviewController c = Get.put(ReviewController());
  final _comment = TextEditingController();
  int rating = 0;

  @override
  void initState() {
    super.initState();
    c.load(widget.recipeId);
  }

  @override
  void dispose() {
    _comment.dispose(); // was leaking: created in State, never released
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Reviews')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.recipeTitle.isNotEmpty)
              Text(widget.recipeTitle, style: text.titleLarge),
            const SizedBox(height: AppSizes.sm),
            Obx(() => Row(children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < c.average.value.round()
                          ? Icons.star
                          : Icons.star_border,
                      size: AppSizes.iconMd,
                      color: t.star,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(c.average.value.toStringAsFixed(1),
                      style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600)),
                  Text('  (${c.reviews.length})',
                      style: text.labelSmall?.copyWith(color: t.textSecondary)),
                ])),

            const SizedBox(height: AppSizes.lg),
            Text('Your rating', style: text.titleLarge?.copyWith(fontSize: 17)),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: List.generate(
                5,
                (i) => IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  tooltip: '${i + 1} star${i == 0 ? '' : 's'}',
                  icon: Icon(i < rating ? Icons.star : Icons.star_border,
                      size: 30, color: t.star),
                  onPressed: () => setState(() => rating = i + 1),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.smd),
            TextField(
              controller: _comment,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Share your thoughts (optional)'),
            ),
            const SizedBox(height: AppSizes.md),
            Obx(() => PrimaryButton(
                  label: 'Submit review',
                  loading: c.isSubmitting.value,
                  onTap: () => c.submit(widget.recipeId, rating, _comment.text),
                )),

            const SizedBox(height: AppSizes.xl),
            Text('All reviews', style: text.titleLarge?.copyWith(fontSize: 17)),
            const SizedBox(height: AppSizes.smd),
            Obx(() {
              if (c.isLoading.value) {
                return const ListSkeleton(
                    count: 3, thumb: 0, padding: EdgeInsets.zero);
              }
              if (c.reviews.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                  child: Center(
                    child: Column(children: [
                      AppIcon('rate_review_outlined', fallback: Icons.rate_review_outlined,
                          size: AppSizes.iconXl, color: t.borderStrong),
                      const SizedBox(height: AppSizes.sm),
                      Text('No reviews yet',
                          style: text.bodyMedium
                              ?.copyWith(color: t.textSecondary)),
                      const SizedBox(height: 2),
                      Text('Be the first to cook it and say how it went.',
                          textAlign: TextAlign.center,
                          style: text.bodySmall
                              ?.copyWith(color: t.textTertiary)),
                    ]),
                  ),
                );
              }
              return Column(
                children: c.reviews.map((r) {
                  final name =
                      (r['profiles'] as Map<String, dynamic>?)?['name'] ?? 'User';
                  final stars = (r['rating'] ?? 0) as int;
                  final comment = (r['comment'] ?? '').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.smd),
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
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: t.brandTint,
                            child: Text(
                              name.toString().isEmpty
                                  ? '?'
                                  : name.toString()[0].toUpperCase(),
                              style: text.labelSmall
                                  ?.copyWith(color: t.onBrandTint),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text('$name',
                                style: text.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                          ...List.generate(
                            5,
                            (s) => Icon(
                                s < stars ? Icons.star : Icons.star_border,
                                size: AppSizes.iconXs + 2,
                                color: t.star),
                          ),
                        ]),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.sm),
                          Text(comment,
                              style: text.bodyMedium
                                  ?.copyWith(color: t.textSecondary, height: 1.45)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}
