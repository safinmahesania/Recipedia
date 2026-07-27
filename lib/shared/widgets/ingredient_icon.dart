import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/ingredient_assets.dart';
import '../../services/ingredient_art_service.dart';
import '../../theme/app_tokens.dart';

/// Ingredient artwork with a three-tier fallback, so nothing ever renders
/// blank:
///
///   1. a drawing for this exact `icon_key`      (assets/ing/tomato.svg)
///   2. a drawing for its `category`             (assets/ing/cat_vegetable.svg)
///   3. the first letter on a deterministic tint
///
/// The database carries ~140 icon_key values against 109 drawings, so tier 2
/// and 3 are the normal path for the long tail, not an error case. Availability
/// is checked against a generated compile-time set rather than caught at
/// runtime, because SvgPicture.asset throws at paint time on a missing asset.
class IngredientIcon extends StatelessWidget {
  final String name;
  final String? iconKey;
  final String? category;

  /// Edge length of the artwork itself.
  final double size;

  /// Wrap in a rounded tinted tile. Off for inline use inside a chip.
  final bool tile;

  const IngredientIcon({
    super.key,
    required this.name,
    this.iconKey,
    this.category,
    this.size = 24,
    this.tile = true,
  });

  String? get _asset {
    // Callers that hold a full ingredient row pass these directly. Callers that
    // only have a name — pantry chips, scan chips, autocomplete, shopping list
    // — get them from the cached name lookup instead.
    final key = iconKey ?? IngredientArt.iconKeyFor(name);
    if (key != null && kIngredientArt.contains(key)) {
      return 'assets/ing/$key.svg';
    }
    final cat = category ?? IngredientArt.categoryFor(name);
    if (cat != null && kCategoryArt.contains(cat)) {
      return 'assets/ing/cat_$cat.svg';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Seeded on the name so an ingredient keeps one colour everywhere it
    // appears — pantry chip, recipe list, shopping list.
    final slot = AppColors.slotFor(name.toLowerCase());
    final path = _asset;

    final art = path != null
        ? SvgPicture.asset(path, width: size, height: size)
        : Text(
            name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: t.categoryGlyphs[slot],
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.5,
                ),
          );

    if (!tile) return SizedBox(width: size, height: size, child: Center(child: art));

    final box = size * 1.5;
    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.categoryTints[slot],
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: art,
    );
  }
}

/// Convenience for the common `recipe_ingredients` row shape:
/// `{ quantity, ingredients: { name, icon_key, category } }`.
class IngredientIconFromRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final double size;
  final bool tile;

  const IngredientIconFromRow({
    super.key,
    required this.row,
    this.size = 24,
    this.tile = true,
  });

  @override
  Widget build(BuildContext context) {
    final ing = (row['ingredients'] as Map<String, dynamic>?) ?? row;
    return IngredientIcon(
      name: (ing['name'] ?? '') as String,
      iconKey: ing['icon_key'] as String?,
      category: ing['category'] as String?,
      size: size,
      tile: tile,
    );
  }
}
