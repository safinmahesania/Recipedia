import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/app_colors.dart';
import '../../theme/app_tokens.dart';

/// Fixed-ratio image slot with an illustrated, deterministic placeholder.
///
/// Two rules make the missing photography survivable:
///   1. The box is a FIXED size. Layout never depends on the photo, so when
///      real photography lands it drops in and nothing reflows.
///   2. The placeholder is seeded on the recipe id, so each recipe keeps the
///      same tint and dish drawing forever. A scrolling grid reads as a varied
///      mosaic rather than 1032 identical broken boxes.
///
/// The drawing is a two-tone SVG rather than a Material glyph, and ships in a
/// light and a dark cut per slot — the artwork carries baked colours, so it
/// cannot recolour itself the way a font icon can.
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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final slot = AppColors.slotFor(seed);
    final tint = t.categoryTints[slot];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = 'assets/dish/d$slot${isDark ? '_d' : '_l'}.svg';

    Widget placeholder() => Container(
          width: width,
          height: height,
          color: tint,
          alignment: Alignment.center,
          child: SvgPicture.asset(
            asset,
            width: height * 0.46,
            height: height * 0.46,
          ),
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
                // Many source images 404 or block hotlinking — fall back to the
                // illustration rather than showing a broken box.
                errorWidget: (_, __, ___) => placeholder(),
              ),
      ),
    );
  }
}
