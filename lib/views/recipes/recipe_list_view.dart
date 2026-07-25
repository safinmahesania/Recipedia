import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/recipe_controller.dart';
import '../../shared/widgets/active_filters_bar.dart';
import '../../shared/widgets/recipe_grid_card.dart';
import '../../theme/app_tokens.dart';
import 'recipe_details_view.dart';

/// Recipe browser: search, category rail, filters, and a two-column grid.
///
/// Search and filters stay pinned above the grid rather than scrolling away —
/// with 1032 recipes, having to scroll back up to change a filter is the most
/// common annoyance in a long catalogue.
class RecipeListView extends StatefulWidget {
  /// When embedded in MainShell the shell owns the chrome, so the
  /// screen-level AppBar is suppressed and an inline header is used instead.
  final bool showAppBar;
  const RecipeListView({super.key, this.showAppBar = true});

  @override
  State<RecipeListView> createState() => _RecipeListViewState();
}

class _RecipeListViewState extends State<RecipeListView> {
  final RecipeController c = Get.put(RecipeController());
  final FavoritesController fav = Get.put(FavoritesController());
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();

  /// Drives the back-to-top button. 1032 recipes is a long way back.
  final _showToTop = false.obs;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
        c.loadMore();
      }
      _showToTop.value = _scroll.position.pixels > 1200;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    c.search('');
    FocusScope.of(context).unfocus();
  }

  /// Three columns on tablets, two on phones.
  int _columns(double width) => width >= AppSizes.bpTablet ? 3 : 2;

  /// Tile height = image (fixed ratio) + title, meta and gaps. Derived from
  /// the real tile width so it never overflows on a wider screen.
  double _tileExtent(double gridWidth, int columns) {
    final spacing = AppSizes.smd * (columns - 1);
    final tileWidth = (gridWidth - spacing) / columns;
    return tileWidth / AppSizes.ratioCard + 62;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: widget.showAppBar ? AppBar(title: const Text('Recipes')) : null,
      floatingActionButton: Obx(() => _showToTop.value
          ? FloatingActionButton.small(
              onPressed: () => _scroll.animateTo(0,
                  duration: AppSizes.durSlow, curve: AppSizes.curveStd),
              backgroundColor: t.surfaceRaised,
              foregroundColor: t.textPrimary,
              elevation: 2,
              tooltip: 'Back to top',
              child: const Icon(Icons.arrow_upward),
            )
          : const SizedBox.shrink()),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.showAppBar)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.screenPad, AppSizes.md, AppSizes.screenPad, 0),
                child: Text('Recipes', style: text.headlineMedium),
              ),

            // ---------- search ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.screenPad,
                  AppSizes.smd, AppSizes.screenPad, AppSizes.sm),
              child: TextField(
                controller: _searchCtrl,
                onChanged: c.search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search recipes',
                  prefixIcon: const Icon(Icons.search, size: AppSizes.iconMd),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchCtrl,
                    builder: (_, value, __) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.close,
                                size: AppSizes.iconMd),
                            tooltip: 'Clear search',
                            onPressed: _clearSearch,
                          ),
                  ),
                ),
              ),
            ),

            // ---------- category rail ----------
            Obx(() {
              if (c.categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: AppSizes.chipHeight + AppSizes.sm,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenPad),
                  itemCount: c.categories.length + 1,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSizes.sm),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _CategoryChip(
                        label: 'All',
                        selected: c.categoryId.value == null,
                        onTap: () => c.setCategory(null, null),
                      );
                    }
                    final cat = c.categories[i - 1];
                    final id = cat['id'] as String;
                    return _CategoryChip(
                      label: (cat['name'] ?? '') as String,
                      selected: c.categoryId.value == id,
                      onTap: () => c.setCategory(id, cat['name'] as String?),
                    );
                  },
                ),
              );
            }),

            // ---------- filters ----------
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPad),
              child: ActiveFiltersBar(),
            ),

            // ---------- result count ----------
            Obx(() {
              if (c.isLoading.value || c.recipes.isEmpty) {
                return const SizedBox(height: AppSizes.sm);
              }
              final term = c.searchTerm.value;
              final n = '${c.recipes.length}${c.hasMore.value ? '+' : ''}';
              return Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.screenPad,
                    AppSizes.sm, AppSizes.screenPad, AppSizes.sm),
                child: Text(
                  term.isEmpty ? '$n recipes' : '$n results for "$term"',
                  style: text.labelSmall?.copyWith(color: t.textSecondary),
                ),
              );
            }),

            // ---------- grid ----------
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gridWidth =
                      constraints.maxWidth - (AppSizes.screenPad * 2);
                  final columns = _columns(constraints.maxWidth);
                  final delegate =
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppSizes.md,
                    crossAxisSpacing: AppSizes.smd,
                    mainAxisExtent: _tileExtent(gridWidth, columns),
                  );

                  return Obx(() {
                    if (c.isLoading.value) {
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(AppSizes.screenPad,
                            0, AppSizes.screenPad, AppSizes.xl),
                        gridDelegate: delegate,
                        itemCount: columns * 3,
                        itemBuilder: (_, __) => const RecipeGridSkeleton(),
                      );
                    }

                    if (c.recipes.isEmpty) return _Empty(controller: c);

                    return RefreshIndicator(
                      color: t.brand,
                      onRefresh: c.loadRecipes,
                      child: CustomScrollView(
                        controller: _scroll,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.screenPad),
                            sliver: SliverGrid(
                              gridDelegate: delegate,
                              delegate: SliverChildBuilderDelegate(
                                (_, i) {
                                  final recipe = c.recipes[i];
                                  final id = recipe['id'] as String;
                                  return Obx(() => RecipeGridCard(
                                        recipe: recipe,
                                        isFavorite: fav.favorites
                                            .any((r) => r['id'] == id),
                                        onToggleFavorite: () =>
                                            fav.toggleFavorite(id),
                                        onTap: () => Get.to(() =>
                                            RecipeDetailsView(recipeId: id)),
                                      ));
                                },
                                childCount: c.recipes.length,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(child: _Footer(controller: c)),
                        ],
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppSizes.durFast,
        height: AppSizes.chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.smd),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? t.brandTint : t.surfaceRaised,
          border: Border.all(color: selected ? t.brandTint : t.border),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? t.onBrandTint : t.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

/// End of grid: next-page spinner, or a quiet full stop.
class _Footer extends StatelessWidget {
  final RecipeController controller;
  const _Footer({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Obx(() {
      if (controller.hasMore.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, AppSizes.lg, 0, AppSizes.xl),
        child: Center(
          child: Text("That's every recipe",
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: t.textTertiary)),
        ),
      );
    });
  }
}

class _Empty extends StatelessWidget {
  final RecipeController controller;
  const _Empty({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final filtered = controller.activeFilterCount > 0;
    final term = controller.searchTerm.value;

    return ListView(
      // Stays scrollable so pull-to-refresh still works when empty.
      padding: const EdgeInsets.all(AppSizes.xl),
      children: [
        const SizedBox(height: AppSizes.xl),
        Icon(Icons.search_off, size: AppSizes.iconXl, color: t.borderStrong),
        const SizedBox(height: AppSizes.smd),
        Text(
          term.isNotEmpty ? 'Nothing matches "$term"' : 'No recipes match',
          textAlign: TextAlign.center,
          style: text.titleLarge,
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          filtered
              ? 'Try removing a filter or searching a different ingredient.'
              : 'Try a different search term.',
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: t.textSecondary),
        ),
        if (filtered) ...[
          const SizedBox(height: AppSizes.md),
          Center(
            child: OutlinedButton(
              onPressed: controller.clearFilters,
              child: const Text('Clear filters'),
            ),
          ),
        ],
      ],
    );
  }
}
