import 'supabase_client.dart';

/// User-submitted recipes (FR34/36).
/// RLS enforces the rules: a user may insert their own recipe, and may
/// edit/delete it only while it is not yet approved.
class SubmissionService {
  Future<String> submitRecipe({
    required String authorId,
    required String title,
    String? instructions,
    String? imageUrl,
    String? cookTime,
    String? diet,
    String? categoryId,
  }) async {
    final row = await supabase.from('recipes').insert({
      'title': title,
      'instructions': instructions,
      'image_url': imageUrl,
      'cook_time': cookTime,
      'diet': diet,
      'category_id': categoryId,
      'author_id': authorId,
      'status': 'pending',
    }).select('id').single();
    return row['id'] as String;
  }

  Future<List<Map<String, dynamic>>> getMySubmissions(String authorId) async {
    return await supabase
        .from('recipes')
        .select('*, categories(name)')
        .eq('author_id', authorId)
        .order('created_at', ascending: false);
  }

  /// Editing an approved recipe sends it back for review.
  Future<void> updateSubmission(String recipeId, Map<String, dynamic> data) async {
    await supabase
        .from('recipes')
        .update({...data, 'status': 'pending', 'rejection_reason': null})
        .eq('id', recipeId);
  }

  Future<void> deleteSubmission(String recipeId) async {
    await supabase.from('recipes').delete().eq('id', recipeId);
  }

  Future<String> ensureIngredient(String name) async {
    final clean = name.toLowerCase().trim();
    final existing = await supabase
        .from('ingredients').select('id').eq('name', clean).maybeSingle();
    if (existing != null) return existing['id'] as String;
    final row = await supabase
        .from('ingredients').insert({'name': clean}).select('id').single();
    return row['id'] as String;
  }

  Future<void> linkIngredient({
    required String recipeId,
    required String ingredientId,
    String role = 'core',
  }) async {
    await supabase.from('recipe_ingredients').upsert({
      'recipe_id': recipeId,
      'ingredient_id': ingredientId,
      'role': role,
    });
  }

  Future<void> clearIngredients(String recipeId) async {
    await supabase.from('recipe_ingredients').delete().eq('recipe_id', recipeId);
  }
}
