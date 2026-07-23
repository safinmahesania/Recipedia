/// Plain data model for a recipe row (maps Supabase JSON -> Dart object).
/// No database code here — that lives in services/recipe_service.dart.
class Recipe {
  final String id;
  final String title;
  final String? instructions;
  final String? imageUrl;
  final String? cookTime;
  final String? diet;
  final String? categoryId;
  final String? categoryName;
  final String? authorId;
  final String status;
  final String? rejectionReason;

  const Recipe({
    required this.id,
    required this.title,
    this.instructions,
    this.imageUrl,
    this.cookTime,
    this.diet,
    this.categoryId,
    this.categoryName,
    this.authorId,
    this.status = 'pending',
    this.rejectionReason,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) => Recipe(
        id: map['id'] as String,
        title: map['title'] ?? '',
        instructions: map['instructions'],
        imageUrl: map['image_url'],
        cookTime: map['cook_time'],
        diet: map['diet'],
        categoryId: map['category_id'],
        categoryName: (map['categories'] as Map<String, dynamic>?)?['name'],
        authorId: map['author_id'],
        status: map['status'] ?? 'pending',
        rejectionReason: map['rejection_reason'],
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'instructions': instructions,
        'image_url': imageUrl,
        'cook_time': cookTime,
        'diet': diet,
        'category_id': categoryId,
        'author_id': authorId,
        'status': status,
        'rejection_reason': rejectionReason,
      };

  bool get isApproved => status == 'approved';
  bool get isPending  => status == 'pending';
}
