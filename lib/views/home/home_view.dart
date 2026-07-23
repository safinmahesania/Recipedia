import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/recipe_controller.dart';
import '../../shared/widgets/recipe_card.dart';
import '../recipes/recipe_details_view.dart';

/// Home tab: greeting, categories, recipe feed.
class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RecipeController rc = Get.put(RecipeController());
    final ProfileController pc = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => rc.loadRecipes(),
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const SizedBox(height: 8),
              Obx(() => Text(
                    'Hi, ${pc.profile.value?.name ?? 'there'}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  )),
              const Text('What are you cooking today?',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              // categories
              const Text('Categories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: Obx(() => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: rc.categories.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return _chip('All', true, () => rc.loadRecipes());
                        }
                        final cat = rc.categories[i - 1];
                        return _chip(cat['name'] ?? '', false,
                            () => rc.loadRecipes(categoryId: cat['id']));
                      },
                    )),
              ),
              const SizedBox(height: 20),

              // recipes
              const Text('Recipes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Obx(() {
                if (rc.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }
                if (rc.recipes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Text('No recipes yet',
                            style: TextStyle(color: AppColors.textSecondary))),
                  );
                }
                return Column(
                  children: rc.recipes
                      .map((r) => RecipeCard(
                            recipe: r,
                            onTap: () => Get.to(() => RecipeDetailsView(recipeId: r['id'])),
                          ))
                      .toList(),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: selected ? Colors.white : AppColors.textSecondary)),
        ),
      );
}
