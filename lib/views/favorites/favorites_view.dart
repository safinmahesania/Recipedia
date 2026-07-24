import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/favorites_controller.dart';
import '../../shared/widgets/recipe_card.dart';
import '../recipes/recipe_details_view.dart';

/// Favorites tab.
class FavoritesView extends StatelessWidget {
  const FavoritesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FavoritesController c = Get.put(FavoritesController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Favorites',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: Column(children: [
        // shown when the list came from cache instead of the network
        Obx(() => c.isOffline.value
            ? Container(
                width: double.infinity,
                color: AppColors.primaryTint,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: const Text('Offline — showing saved recipes',
                    style: TextStyle(fontSize: 12, color: AppColors.primary)),
              )
            : const SizedBox.shrink()),
        Expanded(child: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (c.favorites.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border, size: 44, color: AppColors.border),
                SizedBox(height: 10),
                Text('No favorites yet', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: c.favorites.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (_, i) {
            final r = c.favorites[i];
            return RecipeCard(
              recipe: r,
              onTap: () => Get.to(() => RecipeDetailsView(recipeId: r['id'])),
            );
          },
        );
        })),
      ]),
    );
  }
}
