import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';

/// Icon lookup by name.
///
/// Material Symbols, not Phosphor: phosphor_flutter subclasses IconData, which
/// recent Flutter made a final class, so it cannot compile at all. Symbols are
/// plain IconData constants — nothing to break.
///
/// Symbols is also a variable font, so weight and fill are parameters rather
/// than separate glyphs. That gives real filled states for selected tabs from
/// a single name, which is what the SVG set could not do and why we moved off
/// it. The rounded family suits the app's 26px radii.
///
/// Names stay in Material vocabulary because that is what Symbols uses, so the
/// mapping is mostly identity and stays readable.
IconData _resolve(String name) => switch (name) {
      // navigation
      'home' || 'home_outlined' => Symbols.home,
      'menu_book' || 'menu_book_outlined' => Symbols.menu_book,
      'document_scanner' || 'document_scanner_outlined' =>
        Symbols.document_scanner,
      'bookmark' || 'bookmark_border' => Symbols.bookmark,
      'person' || 'person_outline' => Symbols.person,
      'people_outline' => Symbols.group,

      // actions
      'search' => Symbols.search,
      'search_off' => Symbols.search_off,
      'close' => Symbols.close,
      'check' || 'check_rounded' => Symbols.check,
      'check_circle' => Symbols.check_circle,
      'add' => Symbols.add,
      'refresh' => Symbols.refresh,
      'arrow_back' => Symbols.arrow_back,
      'arrow_upward' => Symbols.arrow_upward,
      'chevron_right' => Symbols.chevron_right,
      'chevron_left' => Symbols.chevron_left,
      'dots_vertical' => Symbols.more_vert,
      'share' => Symbols.share,
      'logout' => Symbols.logout,
      'delete_outline' => Symbols.delete,
      'edit_outlined' => Symbols.edit,
      'edit_note' => Symbols.edit_note,
      'link' => Symbols.link,
      'tune' => Symbols.tune,
      'swap_vert' => Symbols.swap_vert,
      'list_alt' => Symbols.list_alt,

      // media
      'camera_alt' || 'photo_camera_outlined' => Symbols.photo_camera,
      'add_a_photo_outlined' => Symbols.add_a_photo,
      'photo' || 'image_outlined' => Symbols.image,
      'photo_library_outlined' => Symbols.photo_library,

      // cooking
      'restaurant_menu' => Symbols.cooking,
      'local_fire_department' => Symbols.local_fire_department,
      'eco' || 'eco_outlined' => Symbols.eco,
      'shopping_basket_outlined' => Symbols.shopping_basket,
      'shopping_cart' => Symbols.shopping_cart,
      'schedule' => Symbols.schedule,
      'calendar_month_outlined' => Symbols.calendar_month,

      // feedback and status
      'favorite' => Symbols.favorite,
      'star_border' || 'star_outline' => Symbols.star,
      'rate_review_outlined' => Symbols.rate_review,
      'info_outline' => Symbols.info,
      'help_outline' => Symbols.help,
      'warning_amber_rounded' => Symbols.warning,
      'flag_outlined' => Symbols.flag,
      'inbox_outlined' => Symbols.inbox,
      'auto_awesome' || 'sparkles' => Symbols.auto_awesome,
      'notifications_none' => Symbols.notifications,
      'pending_actions' => Symbols.pending_actions,

      // account
      'mail_outline' => Symbols.mail,
      'lock' => Symbols.lock,
      'key' || 'key_outlined' => Symbols.key,
      'shield_outlined' => Symbols.shield,
      'admin_panel_settings_outlined' => Symbols.admin_panel_settings,
      'dark_mode_outlined' => Symbols.dark_mode,
      'visibility' => Symbols.visibility,
      'visibility_off' => Symbols.visibility_off,

      // An unmapped name is a mistake, not a fallback. A circle is visibly
      // wrong so it gets noticed, and the guard test fails on it.
      _ => Symbols.circle,
    };

class AppIcon extends StatelessWidget {
  /// Material-style name, e.g. `search`, `delete_outline`.
  final String name;

  /// Retained so existing call sites compile unchanged. Unused while every
  /// name resolves.
  final IconData? fallback;

  /// Null inherits from IconTheme, exactly like Icon does.
  final double? size;
  final Color? color;
  final String? semanticLabel;

  /// Solid weight, for selected tabs and active states. Symbols is a variable
  /// font, so this is the same glyph filled rather than a second icon.
  final bool filled;

  const AppIcon(
    this.name, {
    super.key,
    this.fallback,
    this.size,
    this.color,
    this.semanticLabel,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    return Icon(
      _resolve(name),
      size: size ?? theme.size ?? 24,
      color: color ?? theme.color ?? context.tokens.textPrimary,
      semanticLabel: semanticLabel,
      fill: filled ? 1 : 0,
      // 400 is the regular weight; heavier reads as shouty at small sizes.
      weight: 400,
      opticalSize: size ?? theme.size ?? 24,
    );
  }
}

/// Icon for the inside of a text field.
///
/// Owns size and colour so call sites cannot drift — they previously each
/// picked their own size and none passed a colour, so field icons rendered at
/// full text weight.
class FieldIcon extends StatelessWidget {
  final String name;
  final IconData? fallback;

  const FieldIcon(this.name, {super.key, this.fallback});

  @override
  Widget build(BuildContext context) => AppIcon(
        name,
        size: AppSizes.iconInput,
        color: context.tokens.textTertiary,
      );
}
