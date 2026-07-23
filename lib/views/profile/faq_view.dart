import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class FaqView extends StatelessWidget {
  const FaqView({Key? key}) : super(key: key);

  static const _faqs = <List<String>>[
    ['How do I find a recipe from ingredients?',
     'Open the scan feature and photograph the vegetable or fruit. Recipes that use it will be shown.'],
    ['Why do some recipes appear without every ingredient I scanned?',
     'Matching uses the main ingredients. Common items like salt and oil, and optional extras, do not block a match.'],
    ['How do I save a recipe?',
     'Tap the heart icon on any recipe to add it to your favorites.'],
    ['Can I submit my own recipe?',
     'Yes. Submitted recipes are reviewed by an admin before they appear publicly.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('FAQs',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, i) => ExpansionTile(
          iconColor: AppColors.primary,
          title: Text(_faqs[i][0],
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(_faqs[i][1],
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
