/// Plain data model for a review row (rating + comment).
class Review {
  final String id;
  final String userId;
  final String recipeId;
  final int rating;
  final String? comment;
  final String? userName;

  const Review({
    required this.id,
    required this.userId,
    required this.recipeId,
    required this.rating,
    this.comment,
    this.userName,
  });

  factory Review.fromMap(Map<String, dynamic> map) => Review(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        recipeId: map['recipe_id'] as String,
        rating: map['rating'] ?? 0,
        comment: map['comment'],
        userName: (map['profiles'] as Map<String, dynamic>?)?['name'],
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'recipe_id': recipeId,
        'rating': rating,
        'comment': comment,
      };
}
