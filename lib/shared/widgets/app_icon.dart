import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';

/// Icon lookup by name.
///
/// Backed by Phosphor rather than a folder of SVGs. The previous approach
/// shipped 78 hand-extracted files with a generated manifest, a build script
/// and a guard test — and still produced five missing-asset bugs in a single
/// session, because nothing stopped a name being typed that had no file.
/// A font cannot be missing.
///
/// It also fixes something the SVGs could not: `filled` gives real weight
/// variants, so a selected tab is the solid glyph rather than the outline in a
/// different colour.
///
/// Names are kept in Material vocabulary. They read as what the UI means
/// ("delete_outline", "shopping_basket_outlined") and renaming ~100 call sites
/// to Phosphor's vocabulary would be churn for no benefit.
IconData _resolve(String name, bool filled) {
  final style = filled ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular;
  return switch (name) {
    // navigation
    'home' || 'home_outlined' => PhosphorIcons.house(style),
    'menu_book' || 'menu_book_outlined' => PhosphorIcons.bookOpen(style),
    'document_scanner' || 'document_scanner_outlined' =>
      PhosphorIcons.scan(style),
    'bookmark' => PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
    'bookmark_border' => PhosphorIcons.bookmarkSimple(style),
    'person' || 'person_outline' => PhosphorIcons.user(style),
    'people_outline' => PhosphorIcons.users(style),

    // actions
    'search' => PhosphorIcons.magnifyingGlass(style),
    'search_off' => PhosphorIcons.magnifyingGlassMinus(style),
    'close' => PhosphorIcons.x(style),
    'check' || 'check_rounded' => PhosphorIcons.check(style),
    'check_circle' => PhosphorIcons.checkCircle(style),
    'add' => PhosphorIcons.plus(style),
    'refresh' => PhosphorIcons.arrowClockwise(style),
    'arrow_back' => PhosphorIcons.arrowLeft(style),
    'arrow_upward' => PhosphorIcons.arrowUp(style),
    'chevron_right' => PhosphorIcons.caretRight(style),
    'chevron_left' => PhosphorIcons.caretLeft(style),
    'dots_vertical' => PhosphorIcons.dotsThreeVertical(style),
    'share' => PhosphorIcons.shareNetwork(style),
    'logout' => PhosphorIcons.signOut(style),
    'delete_outline' => PhosphorIcons.trash(style),
    'edit_outlined' => PhosphorIcons.pencilSimple(style),
    'edit_note' => PhosphorIcons.notePencil(style),
    'link' => PhosphorIcons.link(style),
    'tune' => PhosphorIcons.slidersHorizontal(style),
    'swap_vert' => PhosphorIcons.arrowsDownUp(style),
    'list_alt' => PhosphorIcons.listBullets(style),

    // media
    'camera_alt' || 'photo_camera_outlined' => PhosphorIcons.camera(style),
    'add_a_photo_outlined' => PhosphorIcons.cameraPlus(style),
    'photo' || 'image_outlined' => PhosphorIcons.image(style),
    'photo_library_outlined' => PhosphorIcons.images(style),

    // cooking — the reason a food-literate set matters
    'restaurant_menu' => PhosphorIcons.cookingPot(style),
    'local_fire_department' => PhosphorIcons.fire(style),
    'eco' || 'eco_outlined' => PhosphorIcons.plant(style),
    'shopping_basket_outlined' => PhosphorIcons.basket(style),
    'shopping_cart' => PhosphorIcons.shoppingCart(style),
    'schedule' => PhosphorIcons.clock(style),
    'calendar_month_outlined' => PhosphorIcons.calendarBlank(style),

    // feedback and status
    'favorite' => PhosphorIcons.heart(PhosphorIconsStyle.fill),
    'star_border' || 'star_outline' => PhosphorIcons.star(style),
    'rate_review_outlined' => PhosphorIcons.chatCircleText(style),
    'info_outline' => PhosphorIcons.info(style),
    'help_outline' => PhosphorIcons.question(style),
    'warning_amber_rounded' => PhosphorIcons.warning(style),
    'flag_outlined' => PhosphorIcons.flag(style),
    'inbox_outlined' => PhosphorIcons.tray(style),
    'auto_awesome' => PhosphorIcons.sparkle(style),
    'notifications_none' => PhosphorIcons.bell(style),
    'pending_actions' => PhosphorIcons.clockCountdown(style),

    // account
    'mail_outline' => PhosphorIcons.envelope(style),
    'lock' => PhosphorIcons.lock(style),
    'key' || 'key_outlined' => PhosphorIcons.key(style),
    'shield_outlined' => PhosphorIcons.shieldCheck(style),
    'admin_panel_settings_outlined' => PhosphorIcons.shieldStar(style),
    'dark_mode_outlined' => PhosphorIcons.moon(style),
    'visibility' => PhosphorIcons.eye(style),
    'visibility_off' => PhosphorIcons.eyeSlash(style),
    'sparkles' => PhosphorIcons.sparkle(style),

    // A name with no mapping is a mistake, not a fallback case. Circle is
    // visibly wrong on purpose so it gets noticed in review.
    _ => PhosphorIcons.circle(style),
  };
}

class AppIcon extends StatelessWidget {
  /// Material-style name, e.g. `search`, `delete_outline`.
  final String name;

  /// Kept so call sites need no edit, and so a genuinely absent glyph can still
  /// nominate a Material one. Unused while every name resolves.
  final IconData? fallback;

  /// Null inherits from IconTheme, exactly like Icon does.
  final double? size;
  final Color? color;
  final String? semanticLabel;

  /// Solid weight. Used for selected tabs and active states.
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
      _resolve(name, filled),
      size: size ?? theme.size ?? 24,
      color: color ?? theme.color ?? context.tokens.textPrimary,
      semanticLabel: semanticLabel,
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
