import 'supabase_client.dart';

/// Admin-only data operations. RLS enforces that only admins can write —
/// this class is just the client-side surface.
class AdminService {
  // ---------- recipes ----------
  Future<List<Map<String, dynamic>>> getAllRecipes() async {
    return await supabase
        .from('recipes')
        .select('*, categories(name), profiles(name)')
        .order('created_at', ascending: false);
  }

  /// Submissions waiting for review (FR35).
  Future<List<Map<String, dynamic>>> getPendingRecipes() async {
    return await supabase
        .from('recipes')
        .select('*, categories(name), profiles(name)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
  }

  Future<void> approveRecipe(String recipeId) async {
    await supabase.from('recipes')
        .update({'status': 'approved', 'rejection_reason': null})
        .eq('id', recipeId);
  }

  Future<void> rejectRecipe(String recipeId, String reason) async {
    await supabase.from('recipes')
        .update({'status': 'rejected', 'rejection_reason': reason})
        .eq('id', recipeId);
  }

  Future<String> addRecipe(Map<String, dynamic> data) async {
    final row = await supabase.from('recipes').insert(data).select('id').single();
    return row['id'] as String;
  }

  Future<void> updateRecipe(String recipeId, Map<String, dynamic> data) async {
    await supabase.from('recipes').update(data).eq('id', recipeId);
  }

  Future<void> deleteRecipe(String recipeId) async {
    await supabase.from('recipes').delete().eq('id', recipeId);
  }

  // ---------- ingredients on a recipe ----------
  Future<List<Map<String, dynamic>>> getIngredients() async {
    return await supabase.from('ingredients').select().order('name');
  }

  Future<String> ensureIngredient(String name, {bool isPantry = false}) async {
    final clean = name.toLowerCase().trim();
    final existing = await supabase
        .from('ingredients').select('id').eq('name', clean).maybeSingle();
    if (existing != null) return existing['id'] as String;
    final row = await supabase
        .from('ingredients').insert({'name': clean, 'is_pantry': isPantry})
        .select('id').single();
    return row['id'] as String;
  }

  Future<void> setRecipeIngredient({
    required String recipeId,
    required String ingredientId,
    String role = 'core',
    String? quantity,
  }) async {
    await supabase.from('recipe_ingredients').upsert({
      'recipe_id': recipeId,
      'ingredient_id': ingredientId,
      'role': role,
      'quantity': quantity,
    });
  }

  Future<void> clearRecipeIngredients(String recipeId) async {
    await supabase.from('recipe_ingredients').delete().eq('recipe_id', recipeId);
  }

  // ---------- users ----------
  Future<List<Map<String, dynamic>>> getUsers() async {
    return await supabase.from('profiles').select().order('created_at', ascending: false);
  }

  // ---------- reviews / reports ----------
  Future<List<Map<String, dynamic>>> getReviews() async {
    return await supabase
        .from('reviews')
        .select('*, profiles(name), recipes(title)')
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getReports() async {
    return await supabase
        .from('reports')
        .select('*, profiles(name)')
        .order('created_at', ascending: false);
  }

  Future<void> resolveReport(String reportId, String status) async {
    await supabase.from('reports').update({'status': status}).eq('id', reportId);
  }
}
