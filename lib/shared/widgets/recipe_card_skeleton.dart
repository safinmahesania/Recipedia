import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';

/// Loading placeholder shaped exactly like a RecipeCard.
///
/// A centred spinner tells the user nothing about what is coming and makes the
/// list jump when data lands. Same-shape skeletons keep the layout stable and
/// make the wait feel shorter.
class RecipeCardSkeleton extends StatefulWidget {
  const RecipeCardSkeleton({super.key});

  @override
  State<RecipeCardSkeleton> createState() => _RecipeCardSkeletonState();
}

class _RecipeCardSkeletonState extends State<RecipeCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusXs),
          ),
        );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(_pulse),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.smd),
        decoration: BoxDecoration(
          color: t.surfaceRaised,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
            ),
            const SizedBox(width: AppSizes.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(double.infinity, 14),
                  const SizedBox(height: AppSizes.sm),
                  bar(120, 11),
                  const SizedBox(height: AppSizes.smd),
                  Row(children: [bar(58, 18), const SizedBox(width: 6), bar(74, 18)]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
