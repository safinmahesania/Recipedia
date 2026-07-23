import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/recipe_service.dart';

/// Favorites list state for the signed-in user.
class FavoritesController extends GetxController {
  final RecipeService _service = RecipeService();
  final AuthService _auth = AuthService();

  final isLoading = false.obs;
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
      // rows come back as { recipes: {...} } — flatten to the recipe map
      favorites.value = rows
          .map((r) => (r['recipes'] as Map<String, dynamic>?) ?? {})
          .where((r) => r.isNotEmpty)
          .toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(String recipeId) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;
    final exists = favorites.any((r) => r['id'] == recipeId);
    if (exists) {
      await _service.removeFavorite(userId, recipeId);
    } else {
      await _service.addFavorite(userId, recipeId);
    }
    await loadFavorites();
  }
}
