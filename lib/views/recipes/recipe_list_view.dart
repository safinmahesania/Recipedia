import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/recipe_controller.dart';
import '../../shared/widgets/recipe_card.dart';
import 'recipe_details_view.dart';

/// List-style recipe screen: search on top, paginated rows below.
/// UI only — all data/state comes from RecipeController.
class RecipeListView extends StatefulWidget {
  /// When embedded in MainShell the shell owns the chrome, so the
  /// screen-level AppBar is suppressed.
  final bool showAppBar;
  const RecipeListView({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<RecipeListView> createState() => _RecipeListViewState();
}

class _RecipeListViewState extends State<RecipeListView> {
  final RecipeController c = Get.put(RecipeController());
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
        c.loadMore();
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
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Recipes',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
              backgroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
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
              Expanded(
                child: Obx(() {
                  if (c.isLoading.value) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (c.recipes.isEmpty) {
                    return const Center(
                      child: Text('No recipes found',
                          style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  return ListView.separated(
                    controller: _scroll,
                    // one extra row for the "loading more" spinner
                    itemCount: c.recipes.length + (c.hasMore.value ? 1 : 0),
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      if (i >= c.recipes.length) {
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
                      final recipe = c.recipes[i];
                      return RecipeCard(
                        recipe: recipe,
                        onTap: () =>
                            Get.to(() => RecipeDetailsView(recipeId: recipe['id'])),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
