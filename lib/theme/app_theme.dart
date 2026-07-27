import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import 'app_tokens.dart';

/// THEME WIRING — light and dark ThemeData built from one shared recipe.
///
/// Everything Material renders (buttons, inputs, chips, dialogs, nav bar) is
/// configured here once, so screens contain layout and content only. If a
/// screen is styling a Material component inline, that is a bug in this file.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppTokens.light);
  static ThemeData get dark => _build(Brightness.dark, AppTokens.dark);

  static ThemeData _build(Brightness brightness, AppTokens t) {
    final isLight = brightness == Brightness.light;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.brandFill,
      onPrimary: t.onBrandFill,
      primaryContainer: t.brandTint,
      onPrimaryContainer: t.onBrandTint,
      secondary: t.accent,
      onSecondary: isLight ? Colors.white : AppColors.canvasDark,
      secondaryContainer: t.accentTint,
      onSecondaryContainer: t.onAccentTint,
      error: t.error,
      onError: Colors.white,
      errorContainer: t.errorTint,
      onErrorContainer: t.onErrorTint,
      surface: t.canvas,
      onSurface: t.textPrimary,
      surfaceContainerHighest: t.surface,
      onSurfaceVariant: t.textSecondary,
      outline: t.borderStrong,
      outlineVariant: t.border,
    );

    final text = TextTheme(
      displayLarge: AppTextStyles.displayLg.copyWith(color: t.textPrimary),
      headlineMedium: AppTextStyles.headline.copyWith(color: t.textPrimary),
      titleLarge: AppTextStyles.title.copyWith(color: t.textPrimary),
      titleMedium: AppTextStyles.cardTitle.copyWith(color: t.textPrimary),
      bodyLarge: AppTextStyles.bodyLg.copyWith(color: t.textPrimary),
      bodyMedium: AppTextStyles.bodyMd.copyWith(color: t.textPrimary),
      bodySmall: AppTextStyles.bodySm.copyWith(color: t.textSecondary),
      labelLarge: AppTextStyles.label.copyWith(color: t.textPrimary),
      labelMedium: AppTextStyles.labelSm.copyWith(color: t.textSecondary),
      labelSmall: AppTextStyles.caption.copyWith(color: t.textSecondary),
    );

    final radiusMd = BorderRadius.circular(AppSizes.radiusMd);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      fontFamily: AppTextStyles.body,
      scaffoldBackgroundColor: t.canvas,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[t],

      appBarTheme: AppBarTheme(
        backgroundColor: t.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title.copyWith(color: t.textPrimary),
        iconTheme: IconThemeData(color: t.textPrimary, size: AppSizes.iconMd),
      ),

      // Primary action. Uses brandFill (not brand) so the white label passes AA.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.brandFill,
          foregroundColor: t.onBrandFill,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: AppTextStyles.label,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          side: BorderSide(color: t.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: AppTextStyles.label,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.brandFill,
          textStyle: AppTextStyles.label,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.smd,
        ),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: t.textTertiary),
        labelStyle: AppTextStyles.labelSm.copyWith(color: t.textSecondary),
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: t.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: t.error),
        ),
        errorStyle: AppTextStyles.caption.copyWith(color: t.error),
      ),

      cardTheme: CardThemeData(
        color: t.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          // Transparent in light, hairline in dark — see AppTokens.cardBorder.
          side: BorderSide(color: t.cardBorder),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: t.surface,
        selectedColor: t.brandTint,
        side: BorderSide(color: t.cardBorder),
        labelStyle: AppTextStyles.caption.copyWith(color: t.textSecondary),
        secondaryLabelStyle: AppTextStyles.caption.copyWith(color: t.onBrandTint),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.smd),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navBarHeight,
        backgroundColor: t.canvas,
        surfaceTintColor: Colors.transparent,
        indicatorColor: t.brandTint,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: AppSizes.iconMd,
            color: s.contains(WidgetState.selected) ? t.onBrandTint : t.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppTextStyles.caption.copyWith(
            color: s.contains(WidgetState.selected) ? t.textPrimary : t.textSecondary,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),

      dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),

      dialogTheme: DialogThemeData(
        backgroundColor: t.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        titleTextStyle: AppTextStyles.title.copyWith(color: t.textPrimary),
        contentTextStyle: AppTextStyles.bodyMd.copyWith(color: t.textSecondary),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        showDragHandle: true,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? AppColors.textPrimary : AppColors.surfaceRaisedDark,
        contentTextStyle: AppTextStyles.bodyMd.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.brand,
        linearTrackColor: t.border,
      ),
    );
  }
}
