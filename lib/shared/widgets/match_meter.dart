import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';

/// SIGNATURE ELEMENT — ingredient completeness at a glance.
///
/// Filled pip = an ingredient you have. Hollow pip = one you're missing.
/// This is the thing no other recipe app can show, because no other recipe app
/// knows what's in your kitchen. It also gives a card something to look at
/// while photos are missing, using real information rather than decoration.
class MatchMeter extends StatelessWidget {
  final int matched;
  final int missing;

  const MatchMeter({super.key, required this.matched, required this.missing});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final total = matched + missing;
    if (total == 0) return const SizedBox.shrink();

    // Long ingredient lists would produce an unreadable row of dots, so cap the
    // pips and let the label carry the exact numbers.
    final capped = total > AppSizes.pipMaxVisible;
    final shownMatched = capped
        ? (matched * AppSizes.pipMaxVisible / total).round()
        : matched;
    final shownTotal = capped ? AppSizes.pipMaxVisible : total;

    return Semantics(
      label: missing == 0
          ? 'Ready to cook, all $total ingredients'
          : '$matched of $total ingredients, missing $missing',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(shownTotal, (i) {
          return Padding(
            padding: EdgeInsets.only(
                right: i == shownTotal - 1 ? 0 : AppSizes.pipGap),
            child: Container(
              width: AppSizes.pipSize,
              height: AppSizes.pipSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < shownMatched ? t.pipFilled : t.pipEmpty,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The label that sits under the meter: "Ready to cook" or "Add paneer".
class MatchLabel extends StatelessWidget {
  final int missing;
  final List<String> missingNames;

  const MatchLabel({super.key, required this.missing, this.missingNames = const []});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final ready = missing == 0;

    String text;
    if (ready) {
      text = 'Ready to cook';
    } else if (missing == 1 && missingNames.isNotEmpty) {
      text = 'Add ${missingNames.first}';
    } else {
      text = 'Missing $missing';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.xxs),
      decoration: BoxDecoration(
        color: ready ? t.successTint : t.warningTint,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ready ? t.onSuccessTint : t.onWarningTint,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
