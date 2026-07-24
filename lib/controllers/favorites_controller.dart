import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../services/recipe_service.dart';

/// Favorites list state, with an offline fallback (FR19).
class FavoritesController extends GetxController {
  final RecipeService _service = RecipeService();
  final AuthService _auth = AuthService();
  final CacheService _cache = CacheService();

  final isLoading = false.obs;
  final isOffline = false.obs;
  final favorites = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;
    try {
      isLoading.value = true;
      final rows = await _service.getFavorites(userId);
      favorites.value = rows
          .map((r) => (r['recipes'] as Map<String, dynamic>?) ?? {})
          .where((r) => r.isNotEmpty)
          .toList();
      isOffline.value = false;
      await _cache.saveFavorites(favorites);
    } catch (_) {
      // network failed — fall back to whatever was cached
      final cached = await _cache.getFavorites();
      favorites.value = cached;
      isOffline.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  bool isFavorite(String recipeId) => favorites.any((r) => r['id'] == recipeId);

  Future<void> toggleFavorite(String recipeId) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;
    try {
      if (isFavorite(recipeId)) {
        await _service.removeFavorite(userId, recipeId);
      } else {
        await _service.addFavorite(userId, recipeId);
      }
      await loadFavorites();
      await _cache.pruneRecipes();
    } catch (_) {
      Get.snackbar('Offline', 'Could not update favorites right now.');
    }
  }
}
