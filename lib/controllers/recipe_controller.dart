import 'dart:async';
import 'package:get/get.dart';
import '../services/recipe_service.dart';

/// Recipe list state: combined filters, pagination, debounced search.
class RecipeController extends GetxController {
  final RecipeService _service = RecipeService();

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final recipes = <Map<String, dynamic>>[].obs;

  // filter options
  final categories = <Map<String, dynamic>>[].obs;
  final cuisines = <Map<String, dynamic>>[].obs;
  final diets = <Map<String, dynamic>>[].obs;

  // active filters
  final categoryId = RxnString();
  final categoryName = RxnString();
  final cuisine = RxnString();
  final diet = RxnString();
  final searchTerm = ''.obs;

  int _page = 0;
  Timer? _debounce;

  /// How many filters are currently applied — drives the badge on the button.
  int get activeFilterCount =>
      (categoryId.value != null ? 1 : 0) +
      (cuisine.value != null ? 1 : 0) +
      (diet.value != null ? 1 : 0);

  @override
  void onInit() {
    super.onInit();
    loadFilterOptions();
    loadRecipes();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> loadFilterOptions() async {
    categories.value = await _service.getCategories();
    cuisines.value = await _service.getCuisines();
    diets.value = await _service.getDiets();
  }

  /// Reload from page 0 with the current filters.
  Future<void> loadRecipes() async {
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

  Future<List<Map<String, dynamic>>> _fetchPage(int page) => _service.getFilteredRecipes(
        categoryId: categoryId.value,
        cuisine: cuisine.value,
        diet: diet.value,
        term: searchTerm.value,
        page: page,
      );

  // ---------- filter actions ----------
  void setCategory(String? id, String? name) {
    categoryId.value = id;
    categoryName.value = name;
    loadRecipes();
  }

  void setCuisine(String? value) {
    cuisine.value = value;
    loadRecipes();
  }

  void setDiet(String? value) {
    diet.value = value;
    loadRecipes();
  }

  void clearFilters() {
    categoryId.value = null;
    categoryName.value = null;
    cuisine.value = null;
    diet.value = null;
    loadRecipes();
  }

  /// Debounced so typing doesn't fire a query per keystroke.
  void search(String term) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      searchTerm.value = term.trim();
      loadRecipes();
    });
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
