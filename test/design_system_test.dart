import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipedia/constants/app_colors.dart';
import 'package:recipedia/theme/app_theme.dart';
import 'package:recipedia/theme/app_tokens.dart';

/// These are deliberately narrow. They exist so `flutter test` has something
/// real to run from day one, and because both cover code paths that fail
/// silently rather than loudly if they break.
void main() {
  group('placeholder slots', () {
    test('are stable for the same recipe id', () {
      const id = '9f1c0b6e-1a2b-4c3d-8e9f-0a1b2c3d4e5f';
      expect(AppColors.slotFor(id), AppColors.slotFor(id));
    });

    test('never fall outside the tint ramp', () {
      // An out-of-range slot would throw at paint time on one unlucky recipe
      // out of 1032 — the kind of crash that only shows up in production.
      for (final seed in ['', 'a', 'tomato', '0000', 'x' * 200]) {
        final slot = AppColors.slotFor(seed);
        expect(slot, greaterThanOrEqualTo(0));
        expect(slot, lessThan(AppColors.categoryTints.length));
      }
    });

    test('tint and glyph ramps stay the same length', () {
      expect(AppColors.categoryTints.length, AppColors.categoryGlyphs.length);
      expect(AppColors.categoryTintsDark.length, AppColors.categoryGlyphsDark.length);
      expect(AppColors.categoryTints.length, AppColors.categoryTintsDark.length);
    });
  });

  group('themes', () {
    test('light and dark both build and carry AppTokens', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final tokens = theme.extension<AppTokens>();
        expect(tokens, isNotNull,
            reason: 'context.tokens falls back to light if the extension is '
                'missing, so a dropped registration is invisible at runtime');
      }
    });

    test('brightness matches the token set', () {
      expect(AppTheme.light.brightness, Brightness.light);
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.dark.extension<AppTokens>()!.canvas,
          isNot(AppTheme.light.extension<AppTokens>()!.canvas));
    });
  });
}
