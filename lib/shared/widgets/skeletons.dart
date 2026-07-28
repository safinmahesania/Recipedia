import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';
import '../../shared/widgets/app_icon.dart';

/// Shared loading placeholders.
///
/// A centred spinner tells the user nothing about what is coming and makes the
/// layout jump when data lands. Same-shape skeletons keep the page stable and
/// make the wait read as shorter than it is.
class Pulse extends StatefulWidget {
  final Widget child;
  const Pulse({super.key, required this.child});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.45, end: 1).animate(_c),
        child: widget.child,
      );
}

/// A grey block sized to whatever it is standing in for.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppSizes.radiusXs,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.tokens.surface,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Thumbnail + two lines. Matches the shape of most list rows in the app.
class ListRowSkeleton extends StatelessWidget {
  final double thumb;
  final bool card;

  const ListRowSkeleton({super.key, this.thumb = 48, this.card = false});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(
            width: thumb, height: thumb, radius: AppSizes.radiusSm),
        const SizedBox(width: AppSizes.smd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(height: 13),
              const SizedBox(height: AppSizes.sm),
              SkeletonBox(
                  width: MediaQuery.of(context).size.width * 0.28, height: 10),
            ],
          ),
        ),
      ],
    );

    return Pulse(
      child: card
          ? Container(
              padding: const EdgeInsets.all(AppSizes.smd),
              decoration: BoxDecoration(
                color: t.surfaceRaised,
                border: Border.all(color: t.cardBorder),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: t.cardShadow,
              ),
              child: row,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.smd),
              child: row,
            ),
    );
  }
}

/// Drop-in replacement for a centred spinner on any list screen.
class ListSkeleton extends StatelessWidget {
  final int count;
  final double thumb;
  final bool card;
  final EdgeInsets padding;

  const ListSkeleton({
    super.key,
    this.count = 6,
    this.thumb = 48,
    this.card = false,
    this.padding = const EdgeInsets.all(AppSizes.screenPad),
  });

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: padding,
        itemCount: count,
        separatorBuilder: (_, __) =>
            SizedBox(height: card ? AppSizes.smd : 0),
        itemBuilder: (_, __) => ListRowSkeleton(thumb: thumb, card: card),
      );
}

/// Stacked bars, for screens whose loading state is chips and labels rather
/// than rows — preferences, for example.
class BlockSkeleton extends StatelessWidget {
  const BlockSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Pulse(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.screenPad),
          children: const [
            SkeletonBox(width: 90, height: 11),
            SizedBox(height: AppSizes.smd),
            SkeletonBox(height: 38, radius: AppSizes.radiusPill),
            SizedBox(height: AppSizes.lg),
            SkeletonBox(width: 110, height: 11),
            SizedBox(height: AppSizes.smd),
            SkeletonBox(height: 50, radius: AppSizes.radiusMd),
            SizedBox(height: AppSizes.smd),
            SkeletonBox(height: 38, radius: AppSizes.radiusPill),
            SizedBox(height: AppSizes.lg),
            SkeletonBox(width: 130, height: 11),
            SizedBox(height: AppSizes.smd),
            SkeletonBox(height: 76, radius: AppSizes.radiusLg),
          ],
        ),
      );
}

/// Empty state with a consistent shape: glyph, headline, one line of guidance,
/// optional action. Every screen was rolling its own.
class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: AppSizes.iconXl, color: t.borderStrong),
            const SizedBox(height: AppSizes.smd),
            Text(title,
                textAlign: TextAlign.center,
                style: text.titleLarge?.copyWith(fontSize: 16)),
            const SizedBox(height: AppSizes.xs),
            Text(message,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: t.textSecondary)),
            if (action != null) ...[
              const SizedBox(height: AppSizes.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
