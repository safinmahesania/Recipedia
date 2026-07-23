import 'dart:async';
import 'package:get/get.dart';
import '../services/recipe_service.dart';

/// Recipe list state with pagination and debounced search.
class RecipeController extends GetxController {
  final RecipeService _service = RecipeService();

  final isLoading = false.obs;      // first page
  final isLoadingMore = false.obs;  // subsequent pages
  final hasMore = true.obs;
  final recipes = <Map<String, dynamic>>[].obs;
  final categories = <Map<String, dynamic>>[].obs;
  final cuisines = <String>[].obs;

  String? _categoryId;
  String? _cuisine;
  String _term = '';
  int _page = 0;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    loadCuisines();
    loadRecipes();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> loadCategories() async {
    categories.value = await _service.getCategories();
  }

  Future<void> loadCuisines() async {
    cuisines.value = await _service.getCuisines();
  }

  /// Loads page 0 for the current filters.
  Future<void> loadRecipes({String? categoryId, String? cuisine}) async {
    _categoryId = categoryId;
    _cuisine = cuisine;
    _term = '';
    _page = 0;
    hasMore.value = true;
    try {
      isLoading.value = true;
      recipes.value = await _fetchPage(0);
      hasMore.value = recipes.length >= RecipeService.pageSize;
    } finally {
      isLoading.value = false;
    }
  }

  /// Call when the list nears its end.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
    try {
      isLoadingMore.value = true;
      final next = await _fetchPage(_page + 1);
      if (next.isEmpty) {
        hasMore.value = false;
      } else {
        _page++;
        recipes.addAll(next);
        hasMore.value = next.length >= RecipeService.pageSize;
      }
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int page) {
    if (_term.isNotEmpty) return _service.searchRecipes(_term, page: page);
    if (_cuisine != null) return _service.getRecipesByCuisine(_cuisine!, page: page);
    return _service.getRecipes(categoryId: _categoryId, page: page);
  }

  /// Debounced so typing doesn't fire a query per keystroke.
  void search(String term) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(term));
  }

  Future<void> _runSearch(String term) async {
    _term = term.trim();
    _page = 0;
    hasMore.value = true;
    if (_term.isEmpty) return loadRecipes(categoryId: _categoryId, cuisine: _cuisine);
    try {
      isLoading.value = true;
      recipes.value = await _service.searchRecipes(_term);
      hasMore.value = recipes.length >= RecipeService.pageSize;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadFromScan(List<String> scannedNames) async {
    try {
      isLoading.value = true;
      hasMore.value = false;
      recipes.value = await _service.getRecipesByScannedIngredients(scannedNames);
    } finally {
      isLoading.value = false;
    }
  }
}
