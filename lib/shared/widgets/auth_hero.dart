import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';
import 'app_icon.dart';

/// The illustrated header used across the auth screens.
///
/// Built to the kit's composition rather than improvised per screen: a tinted
/// rounded panel, two dashed halos, a large rotated tile holding the subject
/// icon, a smaller rotated badge, and two dots for asymmetry. Only the icons
/// and the tint slot change between screens, which is what makes login,
/// signup and password reset read as one family.
class AuthHero extends StatelessWidget {
  /// Tabler name for the large tile.
  final String icon;

  /// Tabler name for the small offset badge.
  final String badge;

  /// Index into the category tint ramp — picks the panel and icon colours.
  final int slot;

  /// Shorter on screens that also carry a form, so the fields stay above the
  /// fold. The kit uses 150 where the screen is mostly hero.
  final double height;

  const AuthHero({
    super.key,
    required this.icon,
    required this.badge,
    this.slot = 0,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = height / 150;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.categoryTints[slot],
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Halo(size: 112 * scale, dark: isDark),
          _Halo(size: 162 * scale, dark: isDark, opacity: 0.5),

          // Two small dots break the symmetry the halos create.
          Positioned(
            left: 44 * scale,
            top: 24 * scale,
            child: _Dot(size: 7 * scale, dark: isDark),
          ),
          Positioned(
            left: 64 * scale,
            bottom: 22 * scale,
            child: _Dot(size: 5 * scale, dark: isDark),
          ),

          Transform.rotate(
            angle: -6 * math.pi / 180,
            child: _Float(
              size: 74 * scale,
              radius: 24 * scale,
              child: AppIcon(icon,
                  fallback: Icons.circle_outlined,
                  size: 34 * scale,
                  color: t.categoryGlyphs[slot]),
            ),
          ),
          Positioned(
            right: 30 * scale,
            bottom: 20 * scale,
            child: Transform.rotate(
              angle: 14 * math.pi / 180,
              child: _Float(
                size: 44 * scale,
                radius: 16 * scale,
                child: AppIcon(badge,
                    fallback: Icons.circle_outlined,
                    size: 21 * scale,
                    color: t.onWarningTint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed ring. Flutter has no dashed border, so it is painted.
class _Halo extends StatelessWidget {
  final double size;
  final bool dark;
  final double opacity;

  const _Halo({required this.size, required this.dark, this.opacity = 1});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DashedCirclePainter(
            color: (dark ? Colors.white : Colors.black)
                .withValues(alpha: (dark ? 0.11 : 0.09) * opacity),
          ),
        ),
      );
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final r = size.width / 2;
    final centre = Offset(r, r);
    // ~6px dash with a 5px gap, converted to radians so the pattern stays even
    // whatever the radius.
    const dash = 6.0, gap = 5.0;
    final step = (dash + gap) / r;
    for (var a = 0.0; a < math.pi * 2; a += step) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: r),
        a,
        dash / r,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => old.color != color;
}

class _Dot extends StatelessWidget {
  final double size;
  final bool dark;
  const _Dot({required this.size, required this.dark});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: dark ? 0.18 : 0.6),
        ),
      );
}

class _Float extends StatelessWidget {
  final double size;
  final double radius;
  final Widget child;

  const _Float({
    required this.size,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.55)
                : const Color(0xFF2B2724).withValues(alpha: 0.14),
            offset: const Offset(0, 8),
            blurRadius: isDark ? 22 : 20,
          ),
        ],
      ),
      child: child,
    );
  }
}
