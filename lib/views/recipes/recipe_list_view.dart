import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/recipe_controller.dart';
import '../../shared/widgets/recipe_card.dart';
import 'recipe_details_view.dart';

/// List-style recipe screen: search bar on top, tappable rows below.
/// UI only — all data/state comes from RecipeController.
class RecipeListView extends StatelessWidget {
  RecipeListView({Key? key}) : super(key: key);

  final RecipeController c = Get.put(RecipeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // search
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                onChanged: c.search,
                decoration: InputDecoration(
                  hintText: 'Search recipes',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // list
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (c.recipes.isEmpty) {
                  return const Center(
                    child: Text('No recipes found',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  itemCount: c.recipes.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, i) {
                    final recipe = c.recipes[i];
                    return RecipeCard(
                      recipe: recipe,
                      onTap: () => Get.to(() => RecipeDetailsView(recipeId: recipe['id'])),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
