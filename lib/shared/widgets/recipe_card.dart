import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';
import 'match_meter.dart';
import 'recipe_image.dart';
import '../../shared/widgets/app_icon.dart';

/// Horizontal recipe row — the workhorse across browse, saved, scan and Home.
///
/// The public API is unchanged (`recipe` map + `onTap`) so every caller keeps
/// compiling. Optional data lights up extra rows:
///   * matched_count / missing_count / missing_names  -> match meter
///   * diet, categories.name, cuisine, cook_time      -> meta chips
///   * onToggleFavorite                               -> heart button
class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Shows a heart in the top-right when provided.
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;

  /// When provided and the card carries missing ingredients, the match label
  /// becomes tappable and adds them to the shopping list.
  final VoidCallback? onAddMissing;

  /// Secondary action — used for "add to collection" on the saved list.
  final VoidCallback? onLongPress;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.trailing,
    this.onToggleFavorite,
    this.isFavorite = false,
    this.onAddMissing,
    this.onLongPress,
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
    final category =
        ((recipe['categories'] as Map?)?['name'] ?? '') as String?;

    final matched = (recipe['matched_count'] as num?)?.toInt();
    final missing = (recipe['missing_count'] as num?)?.toInt();
    final missingNames =
        (recipe['missing_names'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final hasMatch = matched != null && missing != null;
    final hasAllergen = recipe['has_allergen'] == true;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.smd),
        decoration: BoxDecoration(
          color: t.surfaceRaised,
          border: Border.all(color: t.cardBorder),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: t.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipeImage(
              seed: id,
              imageUrl: recipe['image_url'] as String?,
              width: 84,
              height: 84,
              radius: AppSizes.radiusSm,
            ),
            const SizedBox(width: AppSizes.smd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium),
                      ),
                      if (onToggleFavorite != null)
                        GestureDetector(
                          onTap: onToggleFavorite,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(left: AppSizes.sm),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: AppSizes.iconMd,
                              color:
                                  isFavorite ? t.brand : t.textTertiary,
                              semanticLabel:
                                  isFavorite ? 'Remove from saved' : 'Save',
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (cookTime != null && cookTime.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.xs + 1),
                    Row(
                      children: [
                        AppIcon('schedule', fallback: Icons.schedule,
                            size: AppSizes.iconXs + 1,
                            color: t.textSecondary),
                        const SizedBox(width: 4),
                        Text(cookTime,
                            style: text.labelSmall
                                ?.copyWith(color: t.textSecondary)),
                        if (cuisine != null && cuisine.isNotEmpty) ...[
                          Text('  ·  ',
                              style: text.labelSmall
                                  ?.copyWith(color: t.textTertiary)),
                          Flexible(
                            child: Text(cuisine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelSmall
                                    ?.copyWith(color: t.textSecondary)),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (hasMatch) ...[
                    const SizedBox(height: AppSizes.sm),
                    MatchMeter(matched: matched, missing: missing),
                    const SizedBox(height: AppSizes.sm),
                    Wrap(
                      spacing: AppSizes.xs,
                      runSpacing: AppSizes.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        MatchLabel(
                            missing: missing, missingNames: missingNames),
                        if (hasAllergen) const _AllergenFlag(),
                        if (onAddMissing != null && missing > 0)
                          GestureDetector(
                            onTap: onAddMissing,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.sm,
                                  vertical: AppSizes.xxs),
                              decoration: BoxDecoration(
                                color: t.surface,
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusPill),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                AppIcon('add', fallback: Icons.add,
                                    size: AppSizes.iconXs + 2,
                                    color: t.textSecondary),
                                const SizedBox(width: 3),
                                Text('List',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: t.textSecondary,
                                            fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                      ],
                    ),
                  ] else if ((diet != null && diet.isNotEmpty) ||
                      (category != null && category.isNotEmpty)) ...[
                    const SizedBox(height: AppSizes.sm),
                    Wrap(
                      spacing: AppSizes.xs,
                      runSpacing: AppSizes.xs,
                      children: [
                        if (diet != null && diet.isNotEmpty)
                          _MetaChip(label: diet, tone: _Tone.accent),
                        if (category != null && category.isNotEmpty)
                          _MetaChip(label: category, tone: _Tone.neutral),
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

enum _Tone { accent, neutral }

class _MetaChip extends StatelessWidget {
  final String label;
  final _Tone tone;
  const _MetaChip({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = tone == _Tone.accent;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.xxs),
      decoration: BoxDecoration(
        color: accent ? t.accentTint : t.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: accent ? null : Border.all(color: t.cardBorder),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accent ? t.onAccentTint : t.textSecondary,
              fontWeight: FontWeight.w600,
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
                    style: text.labelSmall
                        ?.copyWith(color: t.textSecondary, fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}

class _AllergenFlag extends StatelessWidget {
  const _AllergenFlag();

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
          AppIcon('warning_amber_rounded', fallback: Icons.warning_amber_rounded,
              size: AppSizes.iconXs, color: t.onErrorTint),
          const SizedBox(width: 3),
          Text('Allergen',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: t.onErrorTint, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
