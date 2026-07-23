import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/recipe_controller.dart';
import '../../shared/widgets/active_filters_bar.dart';
import '../../shared/widgets/recipe_card.dart';
import '../recipes/recipe_details_view.dart';

/// Home tab: greeting, quick diet filters, filtered recipe feed.
class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final RecipeController rc = Get.put(RecipeController());
  final ProfileController pc = Get.put(ProfileController());
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        rc.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => rc.loadRecipes(),
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                            'Hi, ${pc.profile.value?.name ?? 'there'}',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary),
                          )),
                      const Text('What are you cooking today?',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      const ActiveFiltersBar(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              Obx(() {
                if (rc.isLoading.value) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary)),
                    ),
                  );
                }
                if (rc.recipes.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            const Text('No recipes match',
                                style: TextStyle(color: AppColors.textSecondary)),
                            if (rc.activeFilterCount > 0)
                              TextButton(
                                onPressed: rc.clearFilters,
                                child: const Text('Clear filters',
                                    style: TextStyle(color: AppColors.primary)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        if (i >= rc.recipes.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.primary),
                              ),
                            ),
                          );
                        }
                        final r = rc.recipes[i];
                        return RecipeCard(
                          recipe: r,
                          onTap: () =>
                              Get.to(() => RecipeDetailsView(recipeId: r['id'])),
                        );
                      },
                      childCount: rc.recipes.length + (rc.hasMore.value ? 1 : 0),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
