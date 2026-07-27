import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../theme/app_tokens.dart';

class FaqView extends StatelessWidget {
  const FaqView({super.key});

  static const _faqs = <List<String>>[
    [
      'How do I find a recipe from ingredients?',
      'Open Scan and add what you have. Recipes are ranked by how much of each '
          'one you already own, so the things you can cook right now come first.'
    ],
    [
      'Why do some recipes match without every ingredient I added?',
      'Matching uses the main ingredients only. Staples like salt and oil, and '
          'optional extras, never block a match.'
    ],
    [
      'How do I save a recipe?',
      'Tap the heart on any recipe. Saved recipes work offline and can be '
          'grouped into collections.'
    ],
    [
      'Can I submit my own recipe?',
      'Yes. Submitted recipes are reviewed by an admin before they appear '
          'publicly, and you can track the status in My submissions.'
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('FAQs')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.smd, vertical: AppSizes.sm),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
        itemBuilder: (_, i) => ExpansionTile(
          iconColor: t.brand,
          collapsedIconColor: t.textSecondary,
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(_faqs[i][0], style: text.bodyLarge),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, 0, AppSizes.md, AppSizes.md),
              child: Text(_faqs[i][1],
                  style: text.bodyMedium
                      ?.copyWith(color: t.textSecondary, height: 1.55)),
            ),
          ],
        ),
      ),
    );
  }
}
