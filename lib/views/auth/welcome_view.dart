import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_tokens.dart';
import 'login_view.dart';
import 'signup_view.dart';

/// First screen for anyone without a session.
///
/// Leads with what the app does rather than a login form: "cook what you
/// already have" is the whole proposition, and a bare email field explains
/// nothing to someone deciding whether to sign up.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.md),
              const _Hero(),
              const SizedBox(height: AppSizes.lg),
              Text('Cook what you\nalready have', style: text.headlineMedium),
              const SizedBox(height: AppSizes.sm),
              Text(
                "Tell us what's in your kitchen. We'll show you what you can "
                'make right now, and what you are one ingredient away from.',
                style: text.bodyMedium
                    ?.copyWith(color: t.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSizes.lg),
              const _Point(
                  icon: 'document_scanner_outlined',
                  label: 'Scan your pantry in seconds'),
              const _Point(
                  icon: 'menu_book_outlined',
                  label: '1032 recipes, ranked by what you own'),
              const _Point(
                  icon: 'eco', label: 'Filtered for your diet and allergies'),
              const Spacer(),
              PrimaryButton(
                label: 'Get started',
                onTap: () => Get.to(() => const SignupView()),
              ),
              const SizedBox(height: AppSizes.smd),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: text.bodySmall
                            ?.copyWith(color: t.textSecondary)),
                    GestureDetector(
                      onTap: () => Get.to(() => const LoginView()),
                      child: Text('Log in',
                          style: text.labelMedium
                              ?.copyWith(color: t.onBrandTint)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Layered composition rather than one flat tile — a single centred glyph on a
/// wash reads as a placeholder, not a hero.
class _Hero extends StatelessWidget {
  const _Hero();

  // Ingredient art that orbits the dish, matching the kit.
  static const _orbit = <_Orbit>[
    _Orbit('tomato', left: 18, top: 26, angle: -0.14),
    _Orbit('lemon', right: 20, top: 34, angle: 0.18),
    _Orbit('chilli_green', right: 34, bottom: 20, angle: -0.10),
    _Orbit('carrot', left: 30, bottom: 24, angle: 0.13),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: t.categoryTints[1],
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
          ),
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: t.canvas.withValues(alpha: isDark ? 0.18 : 0.55)),
            ),
          ),
          SvgPicture.asset(
            'assets/dish/d1_${isDark ? 'd' : 'l'}.svg',
            width: 76,
            height: 76,
          ),
          for (final o in _orbit)
            Positioned(
              left: o.left,
              right: o.right,
              top: o.top,
              bottom: o.bottom,
              child: Transform.rotate(
                angle: o.angle,
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    boxShadow: t.cardShadow,
                  ),
                  child: SvgPicture.asset('assets/ing/${o.name}.svg',
                      width: 26, height: 26),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Orbit {
  final String name;
  final double? left, right, top, bottom;
  final double angle;
  const _Orbit(this.name,
      {this.left, this.right, this.top, this.bottom, required this.angle});
}

class _Point extends StatelessWidget {
  final String icon;
  final String label;
  const _Point({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.smd),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.brandTint,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: AppIcon(icon,
              size: AppSizes.iconSm,
              color: t.onBrandTint),
        ),
        const SizedBox(width: AppSizes.smd),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ]),
    );
  }
}
