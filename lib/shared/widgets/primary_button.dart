import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';

/// Brand button with a built-in loading state.
///
/// Fixed: this used to fill with AppColors.primary (#FF4F5A) and put white
/// text on it — 3.22:1, which fails WCAG AA for body text. It now defers
/// entirely to filledButtonTheme, which fills with brandFill (#D93B46, 4.50:1)
/// in light and full coral in dark. No colours are set here at all, so the
/// button is correct in both modes and can never drift from the theme again.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final onFill = Theme.of(context).colorScheme.onPrimary;

    return FilledButton(
      onPressed: loading ? null : onTap,
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: onFill, strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

/// Secondary action. Pairs with PrimaryButton in dialogs and forms.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SecondaryButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        child: Text(label),
      );
}

/// Compact variant for toolbars and cards.
class SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SmallButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizes.buttonHeightSm),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        ),
        child: Text(label),
      );
}
