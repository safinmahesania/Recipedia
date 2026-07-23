import 'package:get/get.dart';
import '../constants/app_strings.dart';
import '../services/admin_service.dart';

/// Admin state: recipes, pending queue, users, reviews, reports.
class AdminController extends GetxController {
  final AdminService _service = AdminService();

  final isLoading = false.obs;
  final recipes = <Map<String, dynamic>>[].obs;
  final pending = <Map<String, dynamic>>[].obs;
  final users = <Map<String, dynamic>>[].obs;
  final reviews = <Map<String, dynamic>>[].obs;
  final reports = <Map<String, dynamic>>[].obs;

  Future<void> loadRecipes() async {
    try {
      isLoading.value = true;
      recipes.value = await _service.getAllRecipes();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPending() async {
    try {
      isLoading.value = true;
      pending.value = await _service.getPendingRecipes();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      users.value = await _service.getUsers();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadReviews() async {
    try {
      isLoading.value = true;
      reviews.value = await _service.getReviews();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadReports() async {
    try {
      isLoading.value = true;
      reports.value = await _service.getReports();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approve(String recipeId) async {
    try {
      await _service.approveRecipe(recipeId);
      Get.snackbar(AppStrings.appName, AppStrings.recipeApproved);
      await loadPending();
    } catch (_) {
      Get.snackbar(AppStrings.error, AppStrings.somethingWentWrong);
    }
  }

  Future<void> reject(String recipeId, String reason) async {
    try {
      await _service.rejectRecipe(recipeId, reason);
      Get.snackbar(AppStrings.appName, AppStrings.recipeRejected);
      await loadPending();
    } catch (_) {
      Get.snackbar(AppStrings.error, AppStrings.somethingWentWrong);
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _service.deleteRecipe(recipeId);
      Get.snackbar(AppStrings.appName, AppStrings.recipeDeleted);
      await loadRecipes();
    } catch (_) {
      Get.snackbar(AppStrings.error, AppStrings.somethingWentWrong);
    }
  }

  Future<void> resolveReport(String reportId, String status) async {
    await _service.resolveReport(reportId, status);
    await loadReports();
  }
}
