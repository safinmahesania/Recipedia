import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';
import 'match_meter.dart';
import 'recipe_image.dart';
import '../../shared/widgets/app_icon.dart';

/// Two-column grid tile.
///
/// Grid tiles are narrow, so the image area has to earn its space. Until real
/// photography lands it carries the cook-time badge and the favourite control
/// rather than sitting empty, and the deterministic placeholder tints give a
/// scrolling grid natural variety instead of 1032 identical squares.
class RecipeGridCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;

  const RecipeGridCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onToggleFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    final id = (recipe['id'] ?? '').toString();
    final title = (recipe['title'] ?? '') as String;
    final cookTime = (recipe['cook_time'] ?? '') as String?;
    final cuisine = (recipe['cuisine'] ?? '') as String?;
    final diet = (recipe['diet'] ?? '') as String?;

    final matched = (recipe['matched_count'] as num?)?.toInt();
    final missing = (recipe['missing_count'] as num?)?.toInt();
    final hasMatch = matched != null && missing != null;

    final sub = [
      if (cuisine != null && cuisine.isNotEmpty) cuisine,
      if (diet != null && diet.isNotEmpty) diet,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LayoutBuilder because the tile width comes from the grid delegate,
          // and RecipeImage needs concrete dimensions to keep a fixed ratio.
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              return Stack(
                children: [
                  RecipeImage(
                    seed: id,
                    imageUrl: recipe['image_url'] as String?,
                    width: w,
                    height: w / AppSizes.ratioCard,
                    radius: AppSizes.radiusMd,
                  ),
                  if (onToggleFavorite != null)
                    Positioned(
                      top: AppSizes.sm,
                      right: AppSizes.sm,
                      child: GestureDetector(
                        onTap: onToggleFavorite,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: t.surfaceRaised.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: AppSizes.iconSm,
                            color: isFavorite ? t.brand : t.textSecondary,
                            semanticLabel:
                                isFavorite ? 'Remove from saved' : 'Save',
                          ),
                        ),
                      ),
                    ),
                  if (cookTime != null && cookTime.isNotEmpty)
                    Positioned(
                      left: AppSizes.sm,
                      bottom: AppSizes.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: t.surfaceRaised.withValues(alpha: 0.92),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon('schedule', fallback: Icons.schedule,
                                size: AppSizes.iconXs, color: t.textSecondary),
                            const SizedBox(width: 3),
                            Text(cookTime,
                                style: text.labelSmall?.copyWith(
                                    color: t.textPrimary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSizes.sm),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium?.copyWith(fontSize: 14, height: 1.25)),
          if (hasMatch) ...[
            const SizedBox(height: AppSizes.xs + 1),
            MatchMeter(matched: matched, missing: missing),
          ] else if (sub.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall
                    ?.copyWith(color: t.textSecondary, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

/// Grid-shaped loading placeholder. Same footprint as a real tile, so the
/// layout does not jump when data arrives.
class RecipeGridSkeleton extends StatefulWidget {
  const RecipeGridSkeleton({super.key});

  @override
  State<RecipeGridSkeleton> createState() => _RecipeGridSkeletonState();
}

class _RecipeGridSkeletonState extends State<RecipeGridSkeleton>
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

    Widget block(double w, double h, double r) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(r),
          ),
        );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(_pulse),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(w, w / AppSizes.ratioCard, AppSizes.radiusMd),
              const SizedBox(height: AppSizes.sm),
              block(w * 0.85, 13, AppSizes.radiusXs),
              const SizedBox(height: 6),
              block(w * 0.5, 10, AppSizes.radiusXs),
            ],
          );
        },
      ),
    );
  }
}
