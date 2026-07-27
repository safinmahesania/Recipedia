import 'package:flutter/material.dart';

/// RAW PALETTE — brand-invariant hex values only.
///
/// Widgets read semantic roles from `context.tokens` (AppTokens), not from
/// here. The only exception is the splash lockup.
///
/// Light is warm and borderless: an off-white canvas with oat surfaces, depth
/// from soft shadows rather than outlines. Dark is charcoal with a gold second
/// accent, depth from raised panels — shadows are invisible on near-black.
///
/// Three values were adjusted from the design kit because they failed WCAG:
///   fill      #E8434F + white label = 3.93:1  ->  #D93B46 = 4.50:1
///   secondary #7B736C on oat        = 4.14:1  ->  #6F675F = 4.94:1
///   tertiary  #A8A099               = 2.51:1  ->  #8E867E = 3.50:1
/// All measured, not estimated.
class AppColors {
  AppColors._();

  // ---------- brand ----------
  /// Identity colour: icons, indicators, active states, large text.
  /// 3.14:1 on canvas — never put small text on it.
  static const primary = Color(0xFFFF4F5A);

  /// Text-bearing fill. White label = 4.50:1, the only coral in this family
  /// that passes AA. Used in BOTH modes so buttons never drift.
  static const primaryPressed = Color(0xFFD93B46);
  static const primaryTint = Color(0xFFFFE8E9);
  static const onPrimaryTint = Color(0xFFB3323C); // 5.23:1 on tint

  /// Lifted coral for dark surfaces. 6.53:1 on the dark panel.
  static const primaryLight = Color(0xFFFF6B73);
  static const primaryTintDark = Color(0xFF34181C);
  static const onPrimaryTintDark = Color(0xFFFF9AA1); // 8.03:1

  // ---------- accent: mint by day, gold by night ----------
  static const accent = Color(0xFF22B894);
  static const accentTint = Color(0xFFD7F5EC);
  static const accentDark = Color(0xFF0E6A52); // 5.67:1 on tint

  static const accentGold = Color(0xFFE8B45C); // 9.54:1 on dark panel
  static const accentTintDark = Color(0xFF2E2413);

  // ---------- light neutrals ----------
  static const canvas = Color(0xFFFDFCFB);
  static const surface = Color(0xFFF4F1EE);
  static const surfaceRaised = Color(0xFFFFFFFF);
  /// Hairline dividers only. Deliberately near-invisible (1.15:1) — in a
  /// borderless design, separation comes from shadow and spacing.
  static const border = Color(0xFFF0ECE8);
  static const borderStrong = Color(0xFFDDD6CF);
  static const textPrimary = Color(0xFF2B2724); // 14.45:1
  static const textSecondary = Color(0xFF6F675F); //  4.94:1 on oat
  static const textTertiary = Color(0xFF8E867E); //  3.50:1, large/UI only

  // ---------- dark neutrals ----------
  static const canvasDark = Color(0xFF0D0D10);
  static const surfaceDark = Color(0xFF16161B);
  static const surfaceRaisedDark = Color(0xFF1E1E25);
  static const borderDark = Color(0xFF26262F);
  static const borderStrongDark = Color(0xFF3A3A46);
  static const textPrimaryDark = Color(0xFFF2F2F5); // 16.14:1
  static const textSecondaryDark = Color(0xFF9E9EA8); //  6.79:1
  static const textTertiaryDark = Color(0xFF7E7E8A); //  4.50:1

  // ---------- semantic ----------
  static const success = Color(0xFF3EC5A0);
  static const successTint = Color(0xFFDAF3E4);
  static const successDark = Color(0xFF12734C); // 5.00:1 on tint
  static const successTintDark = Color(0xFF12301F);
  static const onSuccessTintDark = Color(0xFF4CD68C); // 7.70:1

  static const warning = Color(0xFFF0A93B);
  static const warningTint = Color(0xFFFDECCF);
  static const warningDark = Color(0xFF8A5A05); // 5.10:1 on tint
  static const warningTintDark = Color(0xFF33280F);
  static const onWarningTintDark = Color(0xFFEFC069); // 8.55:1

  static const error = Color(0xFFC0392B);
  static const errorTint = Color(0xFFFDE2DE);
  static const errorDark = Color(0xFFA93226); // 5.40:1 on tint
  static const errorLight = Color(0xFFF97066); // 5.62:1 on dark tint
  static const errorTintDark = Color(0xFF3A1A17);

  static const info = Color(0xFF3A4C8F);
  static const infoTint = Color(0xFFE6EBF9);
  static const infoDark = Color(0xFF2C3B73);
  static const infoTintDark = Color(0xFF1A2338);
  static const onInfoTintDark = Color(0xFF9FB0EC);

  static const star = Color(0xFFF0A93B);
  static const starDark = Color(0xFFE8B45C);

  // ---------- category placeholder ramp ----------
  /// Photos are unavailable, so every image slot takes a tint from this ramp,
  /// chosen deterministically from the recipe id. A scrolling grid becomes a
  /// varied mosaic instead of 1032 identical empty boxes.
  static const categoryTints = <Color>[
    Color(0xFFFFE4E6), Color(0xFFDDF5EC), Color(0xFFFCEFD6), Color(0xFFE6EBF9),
    Color(0xFFF2E7F8), Color(0xFFE8F1E2), Color(0xFFFBE8DC), Color(0xFFE3F0F6),
  ];
  static const categoryGlyphs = <Color>[
    Color(0xFFB3323C), Color(0xFF12735A), Color(0xFF8A5A05), Color(0xFF3A4C8F),
    Color(0xFF6B3E86), Color(0xFF44652F), Color(0xFF9A4A1E), Color(0xFF1F5C77),
  ];
  static const categoryTintsDark = <Color>[
    Color(0xFF34181C), Color(0xFF12301F), Color(0xFF33280F), Color(0xFF1A2338),
    Color(0xFF2C1F35), Color(0xFF1F2A1A), Color(0xFF35231A), Color(0xFF152B36),
  ];
  static const categoryGlyphsDark = <Color>[
    Color(0xFFFF9AA1), Color(0xFF5FE0BC), Color(0xFFEFC069), Color(0xFF9FB0EC),
    Color(0xFFC79BDD), Color(0xFFA8C88E), Color(0xFFE8A87C), Color(0xFF83C2DC),
  ];

  /// Stable per-recipe slot. Seed with the id — titles get edited, ids don't.
  static int slotFor(String seed) {
    if (seed.isEmpty) return 0;
    var h = 0;
    for (final unit in seed.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h % categoryTints.length;
  }
}
