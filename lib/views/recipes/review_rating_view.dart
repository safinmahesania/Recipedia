import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/review_controller.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/recipe_image.dart';
import '../../shared/widgets/skeletons.dart';
import '../../theme/app_tokens.dart';

/// Rate a recipe you just cooked, then read what others said.
///
/// Rating comes first and the existing reviews sit below: this screen is
/// almost always reached straight from cook mode, when the person has an
/// opinion and no interest in scrolling past other people's to leave it.
class ReviewRatingView extends StatefulWidget {
  final String recipeId;
  final String recipeTitle;
  final String? imageUrl;

  const ReviewRatingView({
    super.key,
    required this.recipeId,
    this.recipeTitle = '',
    this.imageUrl,
  });

  @override
  State<ReviewRatingView> createState() => _ReviewRatingViewState();
}

class _ReviewRatingViewState extends State<ReviewRatingView> {
  final ReviewController c = Get.put(ReviewController());
  final _comment = TextEditingController();
  int rating = 0;

  /// Quick descriptors. Appended to the comment rather than stored separately —
  /// a tags column would be a migration for something the review text already
  /// carries perfectly well.
  static const _tags = ['Easy', 'Quick', 'Spicy', 'Family favourite'];
  final _picked = <String>{};

  @override
  void initState() {
    super.initState();
    c.load(widget.recipeId);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  String get _body {
    final note = _comment.text.trim();
    if (_picked.isEmpty) return note;
    final tags = _picked.join(' · ');
    return note.isEmpty ? tags : '$note\n\n$tags';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Rate this recipe')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.sm,
            AppSizes.screenPad, AppSizes.xxl),
        children: [
          if (widget.recipeTitle.isNotEmpty)
            Row(children: [
              RecipeImage(
                seed: widget.recipeId,
                imageUrl: widget.imageUrl,
                width: 56,
                height: 56,
                radius: AppSizes.radiusSm,
              ),
              const SizedBox(width: AppSizes.smd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.recipeTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge?.copyWith(fontSize: 16)),
                    Obx(() => Text(
                          c.reviews.isEmpty
                              ? 'Be the first to review it'
                              : '${c.average.value.toStringAsFixed(1)} · '
                                  '${c.reviews.length} '
                                  '${c.reviews.length == 1 ? 'review' : 'reviews'}',
                          style: text.labelSmall
                              ?.copyWith(color: t.textSecondary),
                        )),
                  ],
                ),
              ),
            ]),

          const SizedBox(height: AppSizes.lg),
          Center(
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 52, minHeight: 52),
                    tooltip: '${i + 1} star${i == 0 ? '' : 's'}',
                    icon: Icon(i < rating ? Icons.star : Icons.star_border,
                        size: 36, color: t.star),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => rating = i + 1);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(rating == 0 ? 'Tap to rate' : _label(rating),
                  style: text.labelSmall?.copyWith(color: t.textSecondary)),
            ]),
          ),

          const SizedBox(height: AppSizes.lg),
          Text('YOUR NOTES',
              style: text.labelSmall?.copyWith(
                  color: t.textTertiary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1)),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _comment,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'What worked? What would you change?'),
          ),
          const SizedBox(height: AppSizes.smd),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: _tags.map((tag) {
              final on = _picked.contains(tag);
              return GestureDetector(
                onTap: () => setState(
                    () => on ? _picked.remove(tag) : _picked.add(tag)),
                child: AnimatedContainer(
                  duration: AppSizes.durFast,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.smd, vertical: AppSizes.sm),
                  decoration: BoxDecoration(
                    color: on ? t.brandTint : t.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: Text(tag,
                      style: text.labelSmall?.copyWith(
                          color: on ? t.onBrandTint : t.textSecondary,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSizes.lg),
          Obx(() => PrimaryButton(
                label: 'Post review',
                loading: c.isSubmitting.value,
                onTap: rating == 0
                    ? () {}
                    : () => c.submit(widget.recipeId, rating, _body),
              )),
          if (rating == 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.sm),
              child: Center(
                child: Text('Pick a rating to post',
                    style:
                        text.labelSmall?.copyWith(color: t.textTertiary)),
              ),
            ),

          const SizedBox(height: AppSizes.xl),
          Text('ALL REVIEWS',
              style: text.labelSmall?.copyWith(
                  color: t.textTertiary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1)),
          const SizedBox(height: AppSizes.smd),
          Obx(() {
            if (c.isLoading.value) {
              return const ListSkeleton(
                  count: 2, thumb: 0, padding: EdgeInsets.zero);
            }
            if (c.reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                child: Text('No reviews yet.',
                    style:
                        text.bodyMedium?.copyWith(color: t.textSecondary)),
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
                            style: text.bodyMedium?.copyWith(
                                color: t.textSecondary, height: 1.45)),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  static String _label(int n) => switch (n) {
        1 => "Wouldn't make it again",
        2 => 'It was fine',
        3 => 'Good',
        4 => 'Really good',
        _ => "I'd make this weekly",
      };
}
