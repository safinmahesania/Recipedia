import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../services/collection_service.dart';
import '../services/recipe_service.dart';

enum FavoriteSort { recent, title, cookTime }

/// Favorites is an ORGANISER, not a third recipe list: search within saved,
/// sort, and group into user-made collections.
class FavoritesController extends GetxController {
  final RecipeService _service = RecipeService();
  final CollectionService _collections = CollectionService();
  final AuthService _auth = AuthService();
  final CacheService _cache = CacheService();

  final isLoading = false.obs;
  final isOffline = false.obs;

  /// Everything saved, unfiltered. `visible` derives from this.
  final favorites = <Map<String, dynamic>>[].obs;
  final collections = <Map<String, dynamic>>[].obs;

  final query = ''.obs;
  final activeCollectionId = Rxn<String>();
  final sort = FavoriteSort.recent.obs;

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
      favorites.value = rows.map((r) {
        final recipe =
            Map<String, dynamic>.from((r['recipes'] as Map?) ?? const {});
        // carry the collection down onto the recipe map so filtering is local
        recipe['collection_id'] = r['collection_id'];
        return recipe;
      }).where((r) => r['id'] != null).toList();
      isOffline.value = false;
      await _cache.saveFavorites(favorites);
      collections.value = await _collections.list(userId);
    } catch (_) {
      favorites.value = await _cache.getFavorites();
      isOffline.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// What the list actually renders: collection filter, then search, then sort.
  List<Map<String, dynamic>> get visible {
    var list = favorites.toList();

    final cid = activeCollectionId.value;
    if (cid != null) {
      list = list.where((r) => r['collection_id'] == cid).toList();
    }

    final q = query.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((r) => (r['title'] ?? '').toString().toLowerCase().contains(q))
          .toList();
    }

    switch (sort.value) {
      case FavoriteSort.title:
        list.sort((a, b) => (a['title'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo((b['title'] ?? '').toString().toLowerCase()));
        break;
      case FavoriteSort.cookTime:
        list.sort((a, b) => _minutes(a['cook_time']).compareTo(_minutes(b['cook_time'])));
        break;
      case FavoriteSort.recent:
        break; // server already returns newest-first
    }
    return list;
  }

  /// cook_time is free text ("35 min", "1 hr 10 min"), so sorting has to parse
  /// it. Unparseable values sort last rather than crashing the list.
  int _minutes(dynamic raw) {
    final s = (raw ?? '').toString().toLowerCase();
    if (s.isEmpty) return 1 << 30;
    final hours = RegExp(r'(\d+)\s*(h|hr|hour)').firstMatch(s);
    final mins = RegExp(r'(\d+)\s*(m|min)').firstMatch(s);
    if (hours == null && mins == null) {
      final bare = RegExp(r'(\d+)').firstMatch(s);
      return bare == null ? 1 << 30 : int.parse(bare.group(1)!);
    }
    return (int.tryParse(hours?.group(1) ?? '0') ?? 0) * 60 +
        (int.tryParse(mins?.group(1) ?? '0') ?? 0);
  }

  int countIn(String? collectionId) => collectionId == null
      ? favorites.length
      : favorites.where((r) => r['collection_id'] == collectionId).length;

  void setQuery(String v) => query.value = v;
  void setCollection(String? id) => activeCollectionId.value = id;
  void setSort(FavoriteSort s) => sort.value = s;

  Future<void> createCollection(String name) async {
    final userId = _auth.currentUser?.id;
    if (userId == null || name.trim().isEmpty) return;
    await _collections.create(userId, name);
    collections.value = await _collections.list(userId);
  }

  Future<void> moveToCollection(String recipeId, String? collectionId) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;
    await _collections.assign(userId, recipeId, collectionId);
    await loadFavorites();
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
      Get.snackbar('Offline', 'Could not update your saved list right now.');
    }
  }
}
