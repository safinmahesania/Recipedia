import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/icon_assets.dart';
import '../../theme/app_tokens.dart';

/// Tabler icon, falling back to Material.
///
/// The design kit is drawn with Tabler; the app was built on Material Icons,
/// which is why nothing matched no matter how the layouts were adjusted —
/// Material's `restaurant_menu` is a different drawing from Tabler's
/// `tools-kitchen-2`. This ships the real set as SVG and tints it with
/// currentColor, so weight and shape line up with the kit.
///
/// A handful (Google and Apple brand marks) have no Tabler equivalent and
/// stay Material, which is why `fallback` exists.
class AppIcon extends StatelessWidget {
  /// Matches the Material name it replaces — `AppIcon('search')` for what was
  /// `Icon(Icons.search)`. Keeps the migration mechanical and greppable.
  final String name;
  final IconData fallback;

  /// Null inherits from IconTheme, exactly like Icon does. Pinning a default
  /// here would silently resize every icon that relied on the ambient size.
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const AppIcon(
    this.name, {
    super.key,
    required this.fallback,
    this.size,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final resolved = size ?? theme.size ?? 24;
    final tint = color ?? theme.color ?? context.tokens.textPrimary;

    if (!kTablerIcons.contains(name)) {
      return Icon(fallback,
          size: resolved, color: tint, semanticLabel: semanticLabel);
    }
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: resolved,
      height: resolved,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}
