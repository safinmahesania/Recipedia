import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/favorites_controller.dart';
import '../../shared/widgets/recipe_card.dart';
import '../../theme/app_tokens.dart';
import '../recipes/recipe_details_view.dart';
import '../../shared/widgets/skeletons.dart';

/// Saved — an organiser, not a third recipe list.
class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoritesController c = Get.put(FavoritesController());
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: Obx(() {
          final items = c.visible;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.screenPad,
                    AppSizes.md, AppSizes.screenPad, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved', style: text.headlineMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${c.favorites.length} recipes · ${c.collections.length} collections',
                      style: text.bodySmall?.copyWith(color: t.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.smd),
                    TextField(
                      onChanged: c.setQuery,
                      decoration: const InputDecoration(
                        hintText: 'Search saved',
                        prefixIcon: Icon(Icons.search, size: AppSizes.iconMd),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: AppSizes.smd),
                    _CollectionBar(controller: c),
                    const SizedBox(height: AppSizes.sm),
                    _SortRow(controller: c),
                  ],
                ),
              ),
              if (c.isOffline.value)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(
                      AppSizes.screenPad, AppSizes.sm, AppSizes.screenPad, 0),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.sm, horizontal: AppSizes.smd),
                  decoration: BoxDecoration(
                    color: t.warningTint,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Text('Offline — showing your saved copy',
                      style:
                          text.labelSmall?.copyWith(color: t.onWarningTint)),
                ),
              Expanded(
                child: c.isLoading.value
                    ? const ListSkeleton(thumb: 52, card: true)
                    : items.isEmpty
                        ? _Empty(hasAny: c.favorites.isNotEmpty)
                        : RefreshIndicator(
                            color: t.brand,
                            onRefresh: c.loadFavorites,
                            child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                                AppSizes.screenPad,
                                AppSizes.smd,
                                AppSizes.screenPad,
                                AppSizes.xl),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSizes.sm),
                            itemBuilder: (_, i) {
                              final r = items[i];
                              return RecipeCard(
                                recipe: r,
                                onTap: () => Get.to(
                                    () => RecipeDetailsView(recipeId: r['id'])),
                                trailing: IconButton(
                                  icon: Icon(Icons.favorite,
                                      color: t.brand, size: AppSizes.iconMd),
                                  tooltip: 'Remove from saved',
                                  onPressed: () =>
                                      c.toggleFavorite(r['id'] as String),
                                ),
                              );
                              },
                            ),
                          ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _CollectionBar extends StatelessWidget {
  final FavoritesController controller;
  const _CollectionBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    Widget chip(String label, bool active, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            height: AppSizes.chipHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.smd),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? t.brandTint : t.surfaceRaised,
              border: Border.all(color: active ? t.brandTint : t.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Text(label,
                style: text.labelSmall?.copyWith(
                    color: active ? t.onBrandTint : t.textPrimary)),
          ),
        );

    return Obx(() => SizedBox(
      height: AppSizes.chipHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip('All', controller.activeCollectionId.value == null,
              () => controller.setCollection(null)),
          ...controller.collections.map((col) {
            final id = col['id'] as String;
            return Padding(
              padding: const EdgeInsets.only(left: AppSizes.sm),
              child: chip(col['name'] as String,
                  controller.activeCollectionId.value == id,
                  () => controller.setCollection(id)),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(left: AppSizes.sm),
            child: GestureDetector(
              onTap: () => _newCollectionSheet(context, controller),
              child: Container(
                height: AppSizes.chipHeight,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.smd),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: t.borderStrong),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Text('+ New',
                    style: text.labelSmall?.copyWith(color: t.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  void _newCollectionSheet(BuildContext context, FavoritesController c) {
    final ctrl = TextEditingController();
    Get.bottomSheet(
      Padding(
        padding: EdgeInsets.only(
          left: AppSizes.screenPad,
          right: AppSizes.screenPad,
          top: AppSizes.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New collection',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSizes.smd),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Weeknight dinners'),
            ),
            const SizedBox(height: AppSizes.md),
            FilledButton(
              onPressed: () async {
                await c.createCollection(ctrl.text);
                Get.back();
              },
              child: const Text('Create collection'),
            ),
          ],
        ),
      ),
      backgroundColor: context.tokens.surfaceRaised,
    );
  }
}

class _SortRow extends StatelessWidget {
  final FavoritesController controller;
  const _SortRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    const labels = {
      FavoriteSort.recent: 'Recently added',
      FavoriteSort.title: 'A to Z',
      FavoriteSort.cookTime: 'Quickest first',
    };

    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(labels[controller.sort.value]!,
            style: text.labelSmall?.copyWith(color: t.textSecondary)),
        PopupMenuButton<FavoriteSort>(
          onSelected: controller.setSort,
          itemBuilder: (_) => labels.entries
              .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_vert,
                  size: AppSizes.iconSm, color: t.textSecondary),
              const SizedBox(width: 3),
              Text('Sort',
                  style: text.labelSmall?.copyWith(color: t.textSecondary)),
            ],
          ),
        ),
      ],
    ));
  }
}

class _Empty extends StatelessWidget {
  /// True when the user has saved recipes but the current filter hides them —
  /// a different problem from having saved nothing at all.
  final bool hasAny;
  const _Empty({required this.hasAny});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border,
                size: AppSizes.iconXl, color: t.borderStrong),
            const SizedBox(height: AppSizes.smd),
            Text(hasAny ? 'Nothing here yet' : 'Start your collection',
                style: text.titleLarge?.copyWith(fontSize: 16)),
            const SizedBox(height: AppSizes.xs),
            Text(
              hasAny
                  ? 'Move a saved recipe into this collection to see it here.'
                  : 'Tap the heart on any recipe to keep it here.',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
