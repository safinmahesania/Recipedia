import 'supabase_client.dart';

/// Admin-only data operations. RLS enforces that only admins can write —
/// this class is just the client-side surface.
class AdminService {
  /// Counts for the dashboard. Head requests return the row count without
  /// transferring the rows, so this stays cheap even at 1032 recipes.
  Future<Map<String, int>> counts() async {
    Future<int> countOf(String table, {String? col, Object? eq}) async {
      var q = supabase.from(table).select('id');
      if (col != null) q = q.eq(col, eq!);
      final rows = await q;
      return (rows as List).length;
    }

    final results = await Future.wait([
      countOf('recipes', col: 'status', eq: 'pending'),
      countOf('reports', col: 'status', eq: 'open'),
      countOf('recipes', col: 'status', eq: 'approved'),
      countOf('profiles'),
    ]);
    return {
      'pending': results[0],
      'reports': results[1],
      'recipes': results[2],
      'users': results[3],
    };
  }

  // ---------- recipes ----------
  Future<List<Map<String, dynamic>>> getAllRecipes() async {
    return await supabase
        .from('recipes')
        .select('*, categories(name), profiles(name)')
        .order('created_at', ascending: false);
  }

  /// Submissions waiting for review (FR35). recipe_ingredients comes along so
  /// a reviewer can see "8 items" without opening each one.
  Future<List<Map<String, dynamic>>> getPendingRecipes() async {
    return await supabase
        .from('recipes')
        .select('*, categories(name), profiles(name), recipe_ingredients(id)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
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
  /// Profiles with how many recipes each has authored — the number that tells
  /// an admin who is actually contributing.
  Future<List<Map<String, dynamic>>> getUsers() async {
    final rows = await supabase
        .from('profiles')
        .select('*, recipes(id)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
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
        .select('*, profiles(name), recipes(id, title)')
        .order('created_at', ascending: false);
  }

  Future<void> resolveReport(String reportId, String status) async {
    await supabase.from('reports').update({'status': status}).eq('id', reportId);
  }
}
