import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// SEMANTIC TOKENS — the layer widgets actually read.
///
/// Widgets ask for a *role* ("the colour of secondary text") rather than a
/// *value* ("#6B6B72"). That indirection is what makes light and dark a single
/// codebase instead of two: swap the token set, every screen follows.
///
/// Usage:  final t = context.tokens;  Text(x, style: ...copyWith(color: t.textSecondary))
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  // surfaces
  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color borderStrong;

  // text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // brand
  /// Identity colour — icons, indicators, borders, large text. NOT small text.
  final Color brand;
  /// Text-bearing fill (buttons). Darker than `brand` so white labels pass AA.
  final Color brandFill;
  final Color onBrandFill;
  final Color brandTint;
  final Color onBrandTint;

  // accent
  final Color accent;
  final Color accentTint;
  final Color onAccentTint;

  // status
  final Color success, successTint, onSuccessTint;
  final Color warning, warningTint, onWarningTint;
  final Color error, errorTint, onErrorTint;
  final Color info, infoTint, onInfoTint;
  final Color star;

  // signature: match meter
  final Color pipFilled;
  final Color pipEmpty;

  // placeholders
  final List<Color> categoryTints;
  final List<Color> categoryGlyphs;

  final List<BoxShadow> cardShadow;

  const AppTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brand,
    required this.brandFill,
    required this.onBrandFill,
    required this.brandTint,
    required this.onBrandTint,
    required this.accent,
    required this.accentTint,
    required this.onAccentTint,
    required this.success,
    required this.successTint,
    required this.onSuccessTint,
    required this.warning,
    required this.warningTint,
    required this.onWarningTint,
    required this.error,
    required this.errorTint,
    required this.onErrorTint,
    required this.info,
    required this.infoTint,
    required this.onInfoTint,
    required this.star,
    required this.pipFilled,
    required this.pipEmpty,
    required this.categoryTints,
    required this.categoryGlyphs,
    required this.cardShadow,
  });

  static const light = AppTokens(
    canvas: AppColors.canvas,
    surface: AppColors.surface,
    surfaceRaised: AppColors.surfaceRaised,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    brand: AppColors.primary,
    brandFill: AppColors.primaryPressed, // 4.50:1 with white — the AA-safe one
    onBrandFill: Colors.white,
    brandTint: AppColors.primaryTint,
    onBrandTint: AppColors.onPrimaryTint,
    accent: AppColors.accent,
    accentTint: AppColors.accentTint,
    onAccentTint: AppColors.accentDark,
    success: AppColors.success,
    successTint: AppColors.successTint,
    onSuccessTint: AppColors.successDark,
    warning: AppColors.warning,
    warningTint: AppColors.warningTint,
    onWarningTint: AppColors.warningDark,
    error: AppColors.error,
    errorTint: AppColors.errorTint,
    onErrorTint: AppColors.errorDark,
    info: AppColors.info,
    infoTint: AppColors.infoTint,
    onInfoTint: AppColors.infoDark,
    star: AppColors.star,
    pipFilled: AppColors.primary,
    pipEmpty: AppColors.borderStrong,
    categoryTints: AppColors.categoryTints,
    categoryGlyphs: AppColors.categoryGlyphs,
    cardShadow: AppShadows.card,
  );

  static const dark = AppTokens(
    canvas: AppColors.canvasDark,
    surface: AppColors.surfaceDark,
    surfaceRaised: AppColors.surfaceRaisedDark,
    border: AppColors.borderDark,
    borderStrong: AppColors.borderStrongDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textTertiary: AppColors.textTertiaryDark,
    brand: AppColors.primaryLight, // 6.80:1 on the dark card
    brandFill: AppColors.primary, // full coral reads correctly on dark
    onBrandFill: Colors.white,
    brandTint: AppColors.primaryTintDark,
    onBrandTint: AppColors.primaryLight,
    accent: AppColors.accentLight,
    accentTint: AppColors.accentTintDark,
    onAccentTint: AppColors.accentLight,
    success: Color(0xFF4CD68C),
    successTint: Color(0xFF12301F),
    onSuccessTint: Color(0xFF4CD68C),
    warning: Color(0xFFF5B942),
    warningTint: Color(0xFF33280F),
    onWarningTint: Color(0xFFF5B942),
    error: Color(0xFFF97066),
    errorTint: Color(0xFF3A1A17),
    onErrorTint: Color(0xFFF97066),
    info: Color(0xFF6BA1FF),
    infoTint: Color(0xFF1A2438),
    onInfoTint: Color(0xFF6BA1FF),
    star: Color(0xFFF5B942),
    pipFilled: AppColors.primaryLight,
    pipEmpty: AppColors.borderStrongDark,
    categoryTints: AppColors.categoryTintsDark,
    categoryGlyphs: AppColors.categoryGlyphsDark,
    cardShadow: AppShadows.none, // dark uses raised surfaces, not shadows
  );

  @override
  AppTokens copyWith({Color? canvas, Color? surface, Color? textPrimary}) =>
      AppTokens(
        canvas: canvas ?? this.canvas,
        surface: surface ?? this.surface,
        surfaceRaised: surfaceRaised,
        border: border,
        borderStrong: borderStrong,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        brand: brand,
        brandFill: brandFill,
        onBrandFill: onBrandFill,
        brandTint: brandTint,
        onBrandTint: onBrandTint,
        accent: accent,
        accentTint: accentTint,
        onAccentTint: onAccentTint,
        success: success,
        successTint: successTint,
        onSuccessTint: onSuccessTint,
        warning: warning,
        warningTint: warningTint,
        onWarningTint: onWarningTint,
        error: error,
        errorTint: errorTint,
        onErrorTint: onErrorTint,
        info: info,
        infoTint: infoTint,
        onInfoTint: onInfoTint,
        star: star,
        pipFilled: pipFilled,
        pipEmpty: pipEmpty,
        categoryTints: categoryTints,
        categoryGlyphs: categoryGlyphs,
        cardShadow: cardShadow,
      );

  /// Snap rather than blend. Light<->dark is a mode switch, not an animation,
  /// and half-interpolated tokens produce muddy intermediate colours.
  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
