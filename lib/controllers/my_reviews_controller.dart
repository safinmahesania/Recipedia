import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';

class MyReviewsController extends GetxController {
  final ReviewService _service = ReviewService();
  final AuthService _auth = AuthService();

  final isLoading = false.obs;
  final reviews = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  double get average {
    if (reviews.isEmpty) return 0;
    final total = reviews.fold<int>(0, (sum, r) => sum + ((r['rating'] ?? 0) as int));
    return total / reviews.length;
  }

  Future<void> load() async {
    final uid = _auth.currentUser?.id;
    if (uid == null) return;
    try {
      isLoading.value = true;
      reviews.value = await _service.getMyReviews(uid);
    } catch (_) {
      Get.snackbar('Offline', 'Could not load your reviews.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> remove(Map<String, dynamic> review) async {
    reviews.remove(review);
    try {
      await _service.deleteReview(review['id'] as String);
    } catch (_) {
      await load();
    }
  }
}
