import 'supabase_client.dart';

/// Reviews (rating + comment) and reports.
class ReviewService {
  Future<List<Map<String, dynamic>>> getReviews(String recipeId) async {
    return await supabase
        .from('reviews')
        .select('*, profiles(name)')
        .eq('recipe_id', recipeId)
        .order('created_at', ascending: false);
  }

  /// One review per user per recipe — upsert so re-rating updates.
  Future<void> submitReview({
    required String userId,
    required String recipeId,
    required int rating,
    String? comment,
  }) async {
    await supabase.from('reviews').upsert({
      'user_id': userId,
      'recipe_id': recipeId,
      'rating': rating,
      'comment': comment,
    }, onConflict: 'user_id,recipe_id');
  }

  Future<double> getAverageRating(String recipeId) async {
    final rows = await supabase.from('reviews').select('rating').eq('recipe_id', recipeId);
    final list = List<Map<String, dynamic>>.from(rows);
    if (list.isEmpty) return 0;
    final total = list.fold<int>(0, (sum, r) => sum + (r['rating'] as int? ?? 0));
    return total / list.length;
  }

  /// FR15 — report a recipe, review, or user.
  Future<void> submitReport({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String reason,
  }) async {
    await supabase.from('reports').insert({
      'reporter_id': reporterId,
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
    });
  }
}
