import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/review_controller.dart';
import '../../controllers/recent_controller.dart';
import '../../services/cache_service.dart';
import '../../services/recipe_service.dart';
import '../../services/share_service.dart';
import 'review_rating_view.dart';

/// Recipe detail screen — image, meta, ingredients, instructions,
/// plus favorite, share, review and report actions.
class RecipeDetailsView extends StatelessWidget {
  final String recipeId;
  const RecipeDetailsView({Key? key, required this.recipeId}) : super(key: key);

  /// Fetch from network, cache on success; fall back to cache when offline.
  Future<Map<String, dynamic>> _load() async {
    final cache = CacheService();
    try {
      final r = await RecipeService().getRecipeDetails(recipeId);
      await cache.saveRecipe(recipeId, r);
      Get.put(RecentController()).track(r);
      return r;
    } catch (e) {
      final cached = await cache.getRecipe(recipeId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = Get.put(FavoritesController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('Could not load this recipe',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
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
                actions: [
                  Obx(() {
                    final isFav = favorites.favorites.any((f) => f['id'] == recipeId);
                    return IconButton(
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          color: Colors.white),
                      onPressed: () => favorites.toggleFavorite(recipeId),
                    );
                  }),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () => ShareService().shareRecipe(r),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: (imageUrl != null && imageUrl.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.primaryTint),
                          // many source images 404 or block hotlinking —
                          // fall back instead of showing a broken box
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primaryTint,
                            child: const Icon(Icons.restaurant_menu,
                                size: 48, color: AppColors.primary),
                          ),
                        )
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
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        if (r['cook_time'] != null)
                          _chip(Icons.schedule, '${r['cook_time']}'),
                        if (r['diet'] != null) _chip(Icons.eco, '${r['diet']}'),
                        if (r['cuisine'] != null)
                          _chip(Icons.public, '${r['cuisine']}'),
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
                            const Icon(Icons.circle, size: 6, color: AppColors.primary),
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
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Get.to(() => ReviewRatingView(
                                recipeId: recipeId, recipeTitle: r['title'] ?? '')),
                            icon: const Icon(Icons.star_border, size: 18),
                            label: const Text('Reviews'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => ShareService().shareRecipe(r),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _reportDialog(context, recipeId),
                          icon: const Icon(Icons.flag_outlined,
                              size: 16, color: AppColors.textSecondary),
                          label: const Text('Report this recipe',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 20),
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

  void _reportDialog(BuildContext context, String recipeId) {
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report recipe'),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: "What's wrong with this recipe?"),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.put(ReviewController()).report('recipe', recipeId, reason.text.trim());
            },
            child: const Text('Report', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
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
