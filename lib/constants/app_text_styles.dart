import 'package:flutter/material.dart';

/// TYPE SCALE — the piece the app was missing entirely.
///
/// Before this file, sizes were hardcoded inline (`fontSize: 15`, `12`, `11`
/// in recipe_card alone), which broke the project's own "never hardcode" rule.
///
/// Two families, one rule:
///   Bricolage Grotesque -> display only (screen titles, recipe titles, numbers
///                          that are the point of the screen). Used with
///                          restraint: it is the personality, and personality
///                          stops being personality when it is everywhere.
///   Inter               -> everything else. Body, labels, inputs, and every
///                          dense admin table, where character costs legibility.
///
/// All numerals use tabular figures so cook times, ratings, match counts and
/// admin table columns align vertically without manual width juggling.
class AppTextStyles {
  AppTextStyles._();

  static const display = 'Bricolage';
  static const body = 'Inter';

  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  // ---------- display: Bricolage, restrained ----------
  /// Screen-defining number or statement. One per screen, at most.
  static const displayLg = TextStyle(
    fontFamily: display,
    fontSize: 32,
    height: 38 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    fontFeatures: _tabular,
  );

  /// Screen title ("Your pantry", "Pending recipes").
  static const headline = TextStyle(
    fontFamily: display,
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    fontFeatures: _tabular,
  );

  /// Recipe title on the detail screen; section headers.
  static const title = TextStyle(
    fontFamily: display,
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  /// Recipe title inside a card.
  static const cardTitle = TextStyle(
    fontFamily: display,
    fontSize: 16,
    height: 21 / 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  // ---------- body: Inter ----------
  static const bodyLg = TextStyle(
    fontFamily: body,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  static const bodyMd = TextStyle(
    fontFamily: body,
    fontSize: 14,
    height: 21 / 14,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  static const bodySm = TextStyle(
    fontFamily: body,
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  /// Button labels, field labels, tab labels.
  static const label = TextStyle(
    fontFamily: body,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const labelSm = TextStyle(
    fontFamily: body,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// Meta rows: cook time, diet chip, "missing 2".
  static const caption = TextStyle(
    fontFamily: body,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  /// Section eyebrows. Uppercase is applied by the widget, not baked in here.
  static const overline = TextStyle(
    fontFamily: body,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
  );

  /// Admin tables — one notch tighter than bodySm, still tabular.
  static const dataCell = TextStyle(
    fontFamily: body,
    fontSize: 13,
    height: 17 / 13,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );

  static const dataHeader = TextStyle(
    fontFamily: body,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}
