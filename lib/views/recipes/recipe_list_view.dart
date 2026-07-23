import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/recipe_controller.dart';
import '../../shared/widgets/active_filters_bar.dart';
import '../../shared/widgets/recipe_card.dart';
import 'recipe_details_view.dart';

/// Recipe browser: search, filters, paginated rows.
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ActiveFiltersBar(),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (c.recipes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 40, color: AppColors.border),
                        const SizedBox(height: 10),
                        const Text('No recipes match',
                            style: TextStyle(color: AppColors.textSecondary)),
                        if (c.activeFilterCount > 0)
                          TextButton(
                            onPressed: c.clearFilters,
                            child: const Text('Clear filters',
                                style: TextStyle(color: AppColors.primary)),
                          ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }
}
