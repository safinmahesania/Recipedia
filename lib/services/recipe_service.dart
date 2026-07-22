import 'supabase_client.dart';

/// All recipe data goes through here — no UI, no navigation.
/// Replaces the old sqflite databaseHelper: queries hit Supabase directly.
class RecipeService {
  /// Approved recipes, newest first. Optional category filter.
  Future<List<Map<String, dynamic>>> getRecipes({String? categoryId}) async {
    var query = supabase
        .from('recipes')
        .select('*, categories(name)')
        .eq('status', 'approved');
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    return await query.order('created_at', ascending: false);
  }

  /// One recipe with its ingredients (name + role + quantity).
  Future<Map<String, dynamic>> getRecipeDetails(String recipeId) async {
    return await supabase
        .from('recipes')
        .select('*, categories(name), recipe_ingredients(role, quantity, ingredients(name, is_pantry))')
        .eq('id', recipeId)
        .single();
  }

  /// Text search over approved recipe titles.
  Future<List<Map<String, dynamic>>> searchRecipes(String term) async {
    return await supabase
        .from('recipes')
        .select('*, categories(name)')
        .eq('status', 'approved')
        .ilike('title', '%$term%')
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    return await supabase.from('categories').select().order('name');
  }

  // ---------- SCAN MATCHING ----------
  // Rule: a recipe matches if every one of its CORE ingredients was scanned.
  // Pantry (is_pantry) and optional ingredients never block a match.
  // So aloo + palak scanned -> "aloo palak" shows even if optional tomato wasn't.
  Future<List<Map<String, dynamic>>> getRecipesByScannedIngredients(
      List<String> scannedNames) async {
    if (scannedNames.isEmpty) return [];
    final scanned = scannedNames.map((e) => e.toLowerCase().trim()).toSet();

    // Pull approved recipes + their non-pantry ingredients, then filter in Dart.
    final rows = await supabase
        .from('recipes')
        .select('*, categories(name), recipe_ingredients(role, ingredients(name, is_pantry))')
        .eq('status', 'approved');

    return List<Map<String, dynamic>>.from(rows).where((recipe) {
      final ris = (recipe['recipe_ingredients'] as List?) ?? [];
      final core = ris.where((ri) {
        final ing = ri['ingredients'] as Map<String, dynamic>?;
        return ri['role'] == 'core' && ing != null && ing['is_pantry'] != true;
      });
      if (core.isEmpty) return false;
      // every core ingredient must be in the scanned set
      return core.every((ri) {
        final name = (ri['ingredients']['name'] as String).toLowerCase().trim();
        return scanned.contains(name);
      });
    }).toList();
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
