import 'package:flutter/material.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../theme/app_tokens.dart';
import '../../shared/widgets/app_icon.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('About us')),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: t.brandTint,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: AppIcon('restaurant_menu', fallback: Icons.restaurant_menu,
                  size: 30, color: t.onBrandTint),
            ),
            const SizedBox(height: AppSizes.md),
            Text(AppStrings.appName, style: text.headlineMedium),
            const SizedBox(height: AppSizes.smd),
            Text(
              'Recipedia helps you find recipes from the ingredients you '
              'already have at home. Scan what is in your kitchen and get '
              'matching recipes ranked by how much you already own, save your '
              'favourites, and share what you cook.',
              style: text.bodyLarge?.copyWith(color: t.textSecondary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
