import 'package:get/get.dart';
import '../constants/app_strings.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';

/// Reviews for one recipe + report submission.
class ReviewController extends GetxController {
  final ReviewService _service = ReviewService();
  final AuthService _auth = AuthService();

  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final reviews = <Map<String, dynamic>>[].obs;
  final average = 0.0.obs;

  Future<void> load(String recipeId) async {
    try {
      isLoading.value = true;
      reviews.value = await _service.getReviews(recipeId);
      average.value = await _service.getAverageRating(recipeId);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submit(String recipeId, int rating, String comment) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;
    if (rating < 1) {
      Get.snackbar(AppStrings.error, 'Please pick a rating');
      return;
    }
    try {
      isSubmitting.value = true;
      await _service.submitReview(
          userId: userId, recipeId: recipeId, rating: rating, comment: comment.trim());
      Get.snackbar(AppStrings.appName, AppStrings.reviewSaved);
      await load(recipeId);
    } catch (_) {
      Get.snackbar(AppStrings.error, AppStrings.somethingWentWrong);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> report(String targetType, String targetId, String reason) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _service.submitReport(
          reporterId: userId, targetType: targetType, targetId: targetId, reason: reason);
      Get.snackbar(AppStrings.appName, AppStrings.reportSent);
    } catch (_) {
      Get.snackbar(AppStrings.error, AppStrings.somethingWentWrong);
    }
  }
}
