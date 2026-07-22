import 'package:get/get.dart';
import '../services/recipe_service.dart';

/// The "C": holds recipe list/search state, calls the service.
/// Views just read these observables.
class RecipeController extends GetxController {
  final RecipeService _service = RecipeService();

  final isLoading = false.obs;
  final recipes = <Map<String, dynamic>>[].obs;
  final categories = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    loadRecipes();
  }

  Future<void> loadRecipes({String? categoryId}) async {
    try {
      isLoading.value = true;
      recipes.value = await _service.getRecipes(categoryId: categoryId);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCategories() async {
    categories.value = await _service.getCategories();
  }

  Future<void> search(String term) async {
    if (term.trim().isEmpty) return loadRecipes();
    isLoading.value = true;
    recipes.value = await _service.searchRecipes(term);
    isLoading.value = false;
  }

  Future<void> loadFromScan(List<String> scannedNames) async {
    isLoading.value = true;
    recipes.value = await _service.getRecipesByScannedIngredients(scannedNames);
    isLoading.value = false;
  }
}
