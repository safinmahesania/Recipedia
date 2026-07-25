import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';
import 'match_meter.dart';
import 'recipe_image.dart';

/// Horizontal recipe row — the workhorse. Used by the recipe list, favorites,
/// scan results, and Home's "almost there" section.
///
/// The public API is unchanged (`recipe` map + `onTap`) so every existing
/// caller keeps compiling. When the map carries `matched_count` /
/// `missing_count` / `missing_names` from the scan RPC, the match meter shows
/// automatically; otherwise the card falls back to plain meta.
class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback? onTap;
  final Widget? trailing;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    final id = (recipe['id'] ?? '').toString();
    final title = (recipe['title'] ?? '') as String;
    final imageUrl = recipe['image_url'] as String?;
    final cookTime = recipe['cook_time'] as String?;
    final cuisine = recipe['cuisine'] as String?;
    final diet = recipe['diet'] as String?;

    final matched = (recipe['matched_count'] as num?)?.toInt();
    final missing = (recipe['missing_count'] as num?)?.toInt();
    final missingNames =
        (recipe['missing_names'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final hasMatch = matched != null && missing != null;
    final hasAllergen = recipe['has_allergen'] == true;

    final meta = [
      if (cookTime != null && cookTime.isNotEmpty) cookTime,
      if (cuisine != null && cuisine.isNotEmpty) cuisine,
      if (!hasMatch && diet != null && diet.isNotEmpty) diet,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
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
            RecipeImage(
              seed: id,
              imageUrl: imageUrl,
              width: AppSizes.thumbSize,
              height: AppSizes.thumbSize,
              radius: AppSizes.radiusSm,
            ),
            const SizedBox(width: AppSizes.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium),
                  if (meta.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall
                              ?.copyWith(color: t.textSecondary)),
                    ),
                  if (hasMatch) ...[
                    const SizedBox(height: AppSizes.sm),
                    MatchMeter(matched: matched, missing: missing),
                    const SizedBox(height: AppSizes.sm),
                    Row(
                      children: [
                        MatchLabel(
                            missing: missing, missingNames: missingNames),
                        if (hasAllergen) ...[
                          const SizedBox(width: AppSizes.xs),
                          _AllergenFlag(),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSizes.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Vertical tile for horizontal carousels on Home.
class RecipeTile extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback? onTap;
  final double width;

  const RecipeTile({
    super.key,
    required this.recipe,
    this.onTap,
    this.width = 148,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    final id = (recipe['id'] ?? '').toString();
    final matched = (recipe['matched_count'] as num?)?.toInt();
    final missing = (recipe['missing_count'] as num?)?.toInt();
    final cookTime = recipe['cook_time'] as String?;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipeImage(
              seed: id,
              imageUrl: recipe['image_url'] as String?,
              width: width,
              height: width / AppSizes.ratioCard,
              radius: AppSizes.radiusMd,
            ),
            const SizedBox(height: AppSizes.sm),
            Text((recipe['title'] ?? '') as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(fontSize: 14)),
            if (matched != null && missing != null) ...[
              const SizedBox(height: AppSizes.xs + 1),
              MatchMeter(matched: matched, missing: missing),
            ],
            if (cookTime != null && cookTime.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.xs + 1),
                child: Text(cookTime,
                    style: text.labelSmall?.copyWith(
                        color: t.textSecondary, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}

class _AllergenFlag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.xxs),
      decoration: BoxDecoration(
        color: t.errorTint,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: AppSizes.iconXs, color: t.onErrorTint),
          const SizedBox(width: 3),
          Text('Allergen',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: t.onErrorTint, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
