import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';

/// Section title for Home. Optional count badge and trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? count;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.count,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.smd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleLarge?.copyWith(fontSize: 17)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        style: text.bodySmall?.copyWith(color: t.textSecondary)),
                  ),
              ],
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm, vertical: AppSizes.xxs),
              decoration: BoxDecoration(
                color: t.successTint,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: Text('$count',
                  style: text.labelSmall?.copyWith(
                      color: t.onSuccessTint, fontWeight: FontWeight.w600)),
            ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSizes.sm),
                child: Text('See all',
                    style: text.labelMedium?.copyWith(color: t.onBrandTint)),
              ),
            ),
        ],
      ),
    );
  }
}
