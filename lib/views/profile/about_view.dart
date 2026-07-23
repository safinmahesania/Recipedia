import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';

class AboutView extends StatelessWidget {
  const AboutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('About Us',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.appName,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
            SizedBox(height: 12),
            Text(
              'Recipedia helps you find recipes from the ingredients you already '
              'have at home. Scan a vegetable or fruit and get matching recipes, '
              'save your favorites, and share what you cook.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
