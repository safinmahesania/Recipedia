import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../theme/app_tokens.dart';

/// Fixed-ratio image slot with a deterministic placeholder.
///
/// Recipe photos are absent today (the source blocks hotlinking) and arrive
/// later. Two rules make that survivable:
///   1. The box is a FIXED size/ratio, so layout never depends on the photo.
///      When real photography lands it drops in and nothing reflows.
///   2. The placeholder is seeded on the recipe id, so each recipe keeps the
///      same tint+glyph forever and a scrolling grid reads as designed rather
///      than as 1032 identical broken boxes.
class RecipeImage extends StatelessWidget {
  final String? imageUrl;

  /// Seed the placeholder. Pass the recipe id — titles get edited, ids don't.
  final String seed;
  final double width;
  final double height;
  final double radius;

  const RecipeImage({
    super.key,
    required this.seed,
    required this.width,
    required this.height,
    this.imageUrl,
    this.radius = 12,
  });

  static const _glyphs = <IconData>[
    Icons.restaurant_menu,
    Icons.eco,
    Icons.egg_alt,
    Icons.local_cafe,
    Icons.cake,
    Icons.rice_bowl,
    Icons.cookie,
    Icons.ramen_dining,
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final slot = AppColors.slotFor(seed);
    final tint = t.categoryTints[slot];
    final glyph = t.categoryGlyphs[slot];

    Widget placeholder() => Container(
          width: width,
          height: height,
          color: tint,
          alignment: Alignment.center,
          child: Icon(_glyphs[slot], color: glyph, size: height * 0.34),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? placeholder()
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, __) => Container(color: tint),
                errorWidget: (_, __, ___) => placeholder(),
              ),
      ),
    );
  }
}
