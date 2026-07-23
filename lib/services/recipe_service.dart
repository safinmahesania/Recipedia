import 'supabase_client.dart';

/// All recipe data goes through here — no UI, no navigation.
/// Lists are paginated: at 1000+ recipes, fetching everything at once is
/// slow and memory-hungry on device.
class RecipeService {
  static const pageSize = 20;

  /// One page of approved recipes with any combination of filters applied.
  /// Replaces the old separate getRecipes / searchRecipes / byCuisine methods.
  Future<List<Map<String, dynamic>>> getFilteredRecipes({
    String? categoryId,
    String? cuisine,
    String? diet,
    String? term,
    int page = 0,
  }) async {
    var query = supabase
        .from('recipes')
        .select('*, categories(name)')
        .eq('status', 'approved');

    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (cuisine != null) query = query.eq('cuisine', cuisine);
    if (diet != null) query = query.eq('diet', diet);
    if (term != null && term.trim().isNotEmpty) {
      query = query.ilike('title', '%${term.trim()}%');
    }

    return await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
  }

  /// One recipe with its ingredients (name + role + quantity).
  Future<Map<String, dynamic>> getRecipeDetails(String recipeId) async {
    return await supabase
        .from('recipes')
        .select(
            '*, categories(name), recipe_ingredients(role, quantity, ingredients(name, is_pantry))')
        .eq('id', recipeId)
        .single();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    return await supabase.from('categories').select().order('name');
  }

  /// Distinct cuisines with counts, computed in Postgres.
  Future<List<Map<String, dynamic>>> getCuisines() async {
    final rows = await supabase.rpc('distinct_cuisines');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Distinct diets with counts, computed in Postgres.
  Future<List<Map<String, dynamic>>> getDiets() async {
    final rows = await supabase.rpc('distinct_diets');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  // ---------- SCAN MATCHING ----------
  /// Runs in Postgres (see match_recipes_by_ingredients).
  /// A recipe matches when every CORE, non-pantry ingredient was scanned;
  /// pantry and optional ingredients never block a match.
  Future<List<Map<String, dynamic>>> getRecipesByScannedIngredients(
      List<String> scannedNames) async {
    if (scannedNames.isEmpty) return [];
    final scanned = scannedNames.map((e) => e.toLowerCase().trim()).toList();
    final rows = await supabase.rpc(
      'match_recipes_by_ingredients',
      params: {'scanned': scanned},
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }

  // ---------- FAVORITES ----------
  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    return await supabase
        .from('favorites')
        .select('recipes(*, categories(name))')
        .eq('user_id', userId);
  }

  Future<void> addFavorite(String userId, String recipeId) async {
    await supabase.from('favorites').insert({'user_id': userId, 'recipe_id': recipeId});
  }

  Future<void> removeFavorite(String userId, String recipeId) async {
    await supabase.from('favorites').delete().match({'user_id': userId, 'recipe_id': recipeId});
  }
}
