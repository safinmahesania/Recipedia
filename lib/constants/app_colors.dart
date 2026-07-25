import 'package:flutter/material.dart';

/// RAW PALETTE — brand-invariant hex values only.
///
/// These do not change between light and dark. Widgets should read semantic
/// roles from `context.tokens` (see AppTokens) rather than reaching in here.
///
/// Contrast measured against WCAG 2.1, not estimated:
///   primary        #FF4F5A on white = 3.22:1  -> large text / icons / borders ONLY
///   primaryPressed #D93B46 on white = 4.50:1  -> passes AA, use for TEXT-BEARING fills
///   accent         #17B890 on white = 2.53:1  -> decorative fill only, never text
///   accentDark     #0F6E56 on white = 6.20:1  -> the accent you may put text on
///
/// The rule that follows: `primary` stays the identity colour, but any surface
/// carrying white label text uses `primaryPressed`. Brand unchanged, buttons
/// accessible.
class AppColors {
  AppColors._();

  // ---------- brand (unchanged) ----------
  static const primary = Color(0xFFFF4F5A);
  static const primaryPressed = Color(0xFFD93B46);
  static const primaryTint = Color(0xFFFFE5E7);

  static const accent = Color(0xFF17B890);
  static const accentTint = Color(0xFFDFF5EE);
  static const accentDark = Color(0xFF0F6E56);

  // ---------- added: accessible companions ----------
  /// Glyph/label colour for anything sitting ON primaryTint. 5.12:1.
  /// (`primary` on `primaryTint` is only 2.70:1 — it fails.)
  static const onPrimaryTint = Color(0xFFB3323C);

  /// Lifted coral for dark surfaces. 6.80:1 on #1C1C21.
  static const primaryLight = Color(0xFFFF7B84);
  static const primaryTintDark = Color(0xFF3A2024);

  /// Lifted teal for dark surfaces. 9.23:1 on #1C1C21.
  static const accentLight = Color(0xFF3DD6AD);
  static const accentTintDark = Color(0xFF12332B);

  // ---------- light neutrals ----------
  static const canvas = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F7F8);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const border = Color(0xFFE9E9EC);
  static const borderStrong = Color(0xFFD6D6DC);
  static const textPrimary = Color(0xFF1A1A1E); // 17.35:1
  static const textSecondary = Color(0xFF6B6B72); //  5.29:1
  static const textTertiary = Color(0xFF9A9AA2); //  hints / large only

  // ---------- dark neutrals ----------
  static const canvasDark = Color(0xFF121215);
  static const surfaceDark = Color(0xFF1C1C21);
  static const surfaceRaisedDark = Color(0xFF24242B);
  static const borderDark = Color(0xFF2C2C33);
  static const borderStrongDark = Color(0xFF3A3A43);
  static const textPrimaryDark = Color(0xFFEDEDF0); // 14.52:1
  static const textSecondaryDark = Color(0xFF9E9EA7); //  6.39:1
  static const textTertiaryDark = Color(0xFF6E6E78);

  // ---------- semantic: fill + accessible text companion + tint ----------
  // The bare hues FAIL on white and must never carry text.
  static const success = Color(0xFF2FBF71); // 2.38:1 — fill only
  static const successDark = Color(0xFF10704A); // 6.11:1 — text
  static const successTint = Color(0xFFE4F6EC);

  static const warning = Color(0xFFF5A623); // 2.03:1 — fill only
  static const warningDark = Color(0xFF8A5A05); // 5.92:1 — text
  static const warningTint = Color(0xFFFDF0D9);

  static const error = Color(0xFFD92D20); // 4.83:1 on white
  static const errorDark = Color(0xFFB42318); // for use on errorTint
  static const errorTint = Color(0xFFFDE7E5);

  static const info = Color(0xFF3B82F6);
  static const infoDark = Color(0xFF1D4FD8);
  static const infoTint = Color(0xFFE4EDFE);

  static const star = Color(0xFFF5A623);

  // ---------- category placeholder ramp ----------
  /// Photos are absent today and arrive later. Rather than 1032 identical
  /// broken-image boxes, each recipe gets a deterministic tint from this ramp,
  /// so a scrolling grid reads as designed rather than failed. Deliberately
  /// desaturated so they never compete with the coral CTA.
  static const categoryTints = <Color>[
    Color(0xFFFFE5E7), // coral      — main course
    Color(0xFFDFF5EE), // teal       — salad / veg
    Color(0xFFFDF0D9), // amber      — breakfast
    Color(0xFFE7EAF6), // periwinkle — beverage
    Color(0xFFF2E8F7), // lilac      — dessert
    Color(0xFFE9F1E4), // sage       — side dish
    Color(0xFFFCE9DF), // clay       — snack
    Color(0xFFE4F1F6), // sky        — soup
  ];

  /// Matching glyph colours, each >= 5:1 on its tint.
  static const categoryGlyphs = <Color>[
    Color(0xFFB3323C),
    Color(0xFF0F6E56),
    Color(0xFF8A5A05),
    Color(0xFF3A4C8F),
    Color(0xFF6B3E86),
    Color(0xFF44652F),
    Color(0xFF9A4A1E),
    Color(0xFF1F5C77),
  ];

  static const categoryTintsDark = <Color>[
    Color(0xFF3A2024),
    Color(0xFF12332B),
    Color(0xFF33280F),
    Color(0xFF1E2338),
    Color(0xFF2C1F35),
    Color(0xFF1F2A1A),
    Color(0xFF35231A),
    Color(0xFF152B36),
  ];

  static const categoryGlyphsDark = <Color>[
    Color(0xFFFF9AA2),
    Color(0xFF5FE0BC),
    Color(0xFFEFC069),
    Color(0xFF9FB0EC),
    Color(0xFFC79BDD),
    Color(0xFFA8C88E),
    Color(0xFFE8A87C),
    Color(0xFF83C2DC),
  ];

  /// Stable per-recipe slot so a recipe keeps the same placeholder forever.
  /// Seed with the recipe id (not the title — titles get edited).
  static int slotFor(String seed) {
    if (seed.isEmpty) return 0;
    var h = 0;
    for (final unit in seed.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h % categoryTints.length;
  }
}
