import 'package:flutter/material.dart';

/// SPACING, RADII, ELEVATION, MOTION.
/// Never hardcode a number in a screen — pull from here.
class AppSizes {
  AppSizes._();

  // ---------- spacing: 4pt base ----------
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const smd = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Standard horizontal screen inset. One value, every screen.
  static const screenPad = 20.0;

  // ---------- radii ----------
  static const radiusXs = 6.0;
  static const radiusSm = 10.0;
  static const radiusMd = 14.0;
  static const radiusLg = 20.0;
  static const radiusXl = 28.0;
  static const radiusPill = 999.0;

  // ---------- components ----------
  static const buttonHeight = 52.0;
  static const buttonHeightSm = 40.0;
  static const inputHeight = 52.0;
  static const thumbSize = 72.0;
  static const avatarRadius = 44.0;
  static const chipHeight = 30.0;
  static const navBarHeight = 64.0;
  static const rowHeightAdmin = 44.0; // denser than user-facing rows

  // ---------- icons ----------
  static const iconXs = 12.0;
  static const iconSm = 16.0;
  static const iconMd = 20.0;
  static const iconLg = 28.0;
  static const iconXl = 40.0;

  // ---------- image slots ----------
  /// Image boxes are FIXED ratio. Layout must never depend on the photo, so
  /// that when real photography lands it drops into the same box and nothing
  /// reflows. This is the single most important rule in the system.
  static const ratioCard = 4 / 3;
  static const ratioHero = 3 / 2;
  static const ratioThumb = 1.0;

  // ---------- match meter (signature element) ----------
  static const pipSize = 7.0;
  static const pipGap = 3.0;
  static const pipMaxVisible = 8;

  // ---------- motion ----------
  static const durFast = Duration(milliseconds: 120);
  static const durBase = Duration(milliseconds: 200);
  static const durSlow = Duration(milliseconds: 320);
  static const curveStd = Curves.easeOutCubic;

  // ---------- responsive ----------
  /// Phone below this, tablet/web above. Admin tables switch from stacked
  /// cards to real columns at the tablet breakpoint.
  static const bpTablet = 600.0;
  static const bpDesktop = 1024.0;
  static const contentMaxWidth = 720.0;
}

/// Elevation as shadow recipes rather than Material elevation numbers, so light
/// and dark can differ. Dark mode uses lighter surfaces instead of shadows,
/// because shadows are close to invisible on a near-black canvas.
class AppShadows {
  AppShadows._();

  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0D0F0F14), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A0F0F14), blurRadius: 8, offset: Offset(0, 4)),
  ];

  static const raised = <BoxShadow>[
    BoxShadow(color: Color(0x140F0F14), blurRadius: 16, offset: Offset(0, 8)),
  ];

  static const sheet = <BoxShadow>[
    BoxShadow(color: Color(0x1F0F0F14), blurRadius: 32, offset: Offset(0, -4)),
  ];

  static const none = <BoxShadow>[];
}
