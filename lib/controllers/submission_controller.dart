import 'package:get/get.dart';
import '../constants/app_strings.dart';
import '../services/auth_service.dart';
import '../services/recipe_service.dart';
import '../services/submission_service.dart';

/// State for submitting recipes and tracking their review status.
class SubmissionController extends GetxController {
  final SubmissionService _service = SubmissionService();
  final RecipeService _recipeService = RecipeService();
  final AuthService _auth = AuthService();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final mySubmissions = <Map<String, dynamic>>[].obs;
  final categories = <Map<String, dynamic>>[].obs;

  static const dietOptions = ['Vegetarian', 'Non Vegetarian', 'Vegan', 'Eggetarian'];

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    categories.value = await _recipeService.getCategories();
  }

  Future<void> loadMySubmissions() async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;
    try {
      isLoading.value = true;
      mySubmissions.value = await _service.getMySubmissions(userId);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submit({
    required String title,
    required String instructions,
    required String coreCsv,
    required String optionalCsv,
    String? imageUrl,
    String? cookTime,
    String? diet,
    String? categoryId,
    String? existingId,
  }) async {
    // guard: ignore taps while a save is already running
    if (isSaving.value) return false;

    final userId = _auth.currentUser?.id;
    if (userId == null) return false;

    try {
      isSaving.value = true;
      final data = {
        'title': title.trim(),
        'instructions': instructions.trim(),
        'image_url': imageUrl?.trim(),
        'cook_time': cookTime?.trim(),
        'diet': diet?.trim(),
        'category_id': categoryId,
      };

      String recipeId;
      final isNew = existingId == null;
      if (!isNew) {
        recipeId = existingId;
        await _service.updateSubmission(recipeId, data);
        await _service.clearIngredients(recipeId);
      } else {
        recipeId = await _service.submitRecipe(
          authorId: userId,
          title: data['title']!,
          instructions: data['instructions'],
          imageUrl: data['image_url'],
          cookTime: data['cook_time'],
          diet: data['diet'],
          categoryId: categoryId,
        );
      }

      try {
        await _link(recipeId, coreCsv, 'core');
        await _link(recipeId, optionalCsv, 'optional');
      } catch (e) {
        // ingredient step failed — roll back a newly created recipe so we don't
        // leave a half-saved, ingredient-less row behind.
        if (isNew) await _service.deleteSubmission(recipeId);
        rethrow;
      }

      await loadMySubmissions();
      return true;
    } catch (e) {
      Get.snackbar(AppStrings.error, 'Could not save: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _link(String recipeId, String csv, String role) async {
    for (final raw in csv.split(',')) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final id = await _service.ensureIngredient(name);
      await _service.linkIngredient(
          recipeId: recipeId, ingredientId: id, role: role);
    }
  }

  Future<void> delete(String recipeId) async {
    try {
      await _service.deleteSubmission(recipeId);
      Get.snackbar(AppStrings.appName, AppStrings.submissionDeleted);
      await loadMySubmissions();
    } catch (_) {
      Get.snackbar(AppStrings.error, AppStrings.somethingWentWrong);
    }
  }
}
