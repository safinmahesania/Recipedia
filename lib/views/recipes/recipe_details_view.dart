import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/recipe_service.dart';

/// Recipe detail screen — image, meta, ingredients, instructions.
/// UI only; pulls one recipe (with ingredients) from RecipeService.
class RecipeDetailsView extends StatelessWidget {
  final String recipeId;
  const RecipeDetailsView({Key? key, required this.recipeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: RecipeService().getRecipeDetails(recipeId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final r = snap.data!;
          final ingredients = (r['recipe_ingredients'] as List?) ?? [];
          final imageUrl = r['image_url'] as String?;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: (imageUrl != null && imageUrl.isNotEmpty)
                      ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.primaryTint,
                          child: const Icon(Icons.restaurant_menu,
                              size: 48, color: AppColors.primary)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['title'] ?? '',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        if (r['cook_time'] != null)
                          _chip(Icons.schedule, r['cook_time']),
                        if (r['diet'] != null) _chip(Icons.eco, r['diet']),
                      ]),
                      const SizedBox(height: 20),
                      const Text('Ingredients',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      ...ingredients.map((ri) {
                        final ing = ri['ingredients'] as Map<String, dynamic>?;
                        final name = ing?['name'] ?? '';
                        final qty = ri['quantity'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            const Icon(Icons.circle,
                                size: 6, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text('$name  $qty',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary))),
                          ]),
                        );
                      }),
                      const SizedBox(height: 20),
                      const Text('Instructions',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Text(r['instructions'] ?? '',
                          style: const TextStyle(
                              color: AppColors.textSecondary, height: 1.5)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      );
}
