import 'package:get/get.dart';
import '../constants/app_strings.dart';
import '../services/auth_service.dart';
import '../services/submission_service.dart';

/// State for submitting recipes and tracking their review status.
class SubmissionController extends GetxController {
  final SubmissionService _service = SubmissionService();
  final AuthService _auth = AuthService();

  final isLoading = false.obs;
  final isSaving = false.obs;
  final mySubmissions = <Map<String, dynamic>>[].obs;

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
    String? existingId,
  }) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return false;
    if (title.trim().isEmpty) {
      Get.snackbar(AppStrings.error, 'Title is required');
      return false;
    }
    if (coreCsv.trim().isEmpty) {
      Get.snackbar(AppStrings.error, 'Add at least one main ingredient');
      return false;
    }

    try {
      isSaving.value = true;
      final data = {
        'title': title.trim(),
        'instructions': instructions.trim(),
        'image_url': imageUrl?.trim(),
        'cook_time': cookTime?.trim(),
        'diet': diet?.trim(),
      };

      String recipeId;
      if (existingId != null) {
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
        );
      }

      await _link(recipeId, coreCsv, 'core');
      await _link(recipeId, optionalCsv, 'optional');

      Get.snackbar(AppStrings.appName, AppStrings.submissionSent);
      await loadMySubmissions();
      return true;
    } catch (_) {
      Get.snackbar(AppStrings.error, AppStrings.somethingWentWrong);
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
