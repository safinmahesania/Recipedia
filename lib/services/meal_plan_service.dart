import 'supabase_client.dart';

/// meal_plan_entries (migration 20260725000009).
class MealPlanService {
  static const slots = ['breakfast', 'lunch', 'dinner', 'snack'];

  Future<List<Map<String, dynamic>>> forWeek(
      String uid, DateTime monday) async {
    final start = _iso(monday);
    final end = _iso(monday.add(const Duration(days: 6)));
    final rows = await supabase
        .from('meal_plan_entries')
        .select('id, plan_date, slot, recipes(id, title, image_url, cook_time)')
        .eq('user_id', uid)
        .gte('plan_date', start)
        .lte('plan_date', end)
        .order('plan_date');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> add(
      String uid, String recipeId, DateTime date, String slot) async {
    await supabase.from('meal_plan_entries').insert({
      'user_id': uid,
      'recipe_id': recipeId,
      'plan_date': _iso(date),
      'slot': slot,
    });
  }

  Future<void> remove(String entryId) async {
    await supabase.from('meal_plan_entries').delete().eq('id', entryId);
  }

  /// Recipes to choose from: saved first, because a planner is mostly used to
  /// arrange things you already decided you like.
  Future<List<Map<String, dynamic>>> savedRecipes(String uid) async {
    final rows = await supabase
        .from('favorites')
        .select('recipes(id, title, image_url, cook_time)')
        .eq('user_id', uid)
        .limit(60);
    return [
      for (final r in (rows as List))
        if ((r as Map)['recipes'] != null)
          Map<String, dynamic>.from(r['recipes'] as Map)
    ];
  }

  Future<List<Map<String, dynamic>>> searchRecipes(String q) async {
    final term = q.trim();
    if (term.length < 2) return [];
    final rows = await supabase
        .from('recipes')
        .select('id, title, image_url, cook_time')
        .eq('status', 'approved')
        .ilike('title', '%$term%')
        .limit(20);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Every core ingredient across the week's plan that the user does not
  /// already have. Pantry staples and globally-flagged staples are excluded,
  /// so the result is a shopping list rather than a stock take.
  Future<List<String>> missingForWeek(
      String uid, List<String> recipeIds, Set<String> pantryNames) async {
    if (recipeIds.isEmpty) return [];

    final rows = await supabase
        .from('recipe_ingredients')
        .select('ingredients(id, name, is_pantry)')
        .inFilter('recipe_id', recipeIds)
        .eq('role', 'core');

    final staples = await supabase
        .from('user_pantry_staples')
        .select('ingredient_id')
        .eq('user_id', uid);
    final stapleIds = {
      for (final s in (staples as List)) (s as Map)['ingredient_id'] as String
    };

    final out = <String>{};
    for (final r in (rows as List)) {
      final ing = (r as Map)['ingredients'] as Map?;
      if (ing == null) continue;
      if (ing['is_pantry'] == true) continue;
      if (stapleIds.contains(ing['id'])) continue;
      final name = (ing['name'] ?? '').toString();
      if (name.isEmpty) continue;
      if (pantryNames.contains(name.toLowerCase())) continue;
      out.add(name);
    }
    return out.toList()..sort();
  }

  /// Exposed because the controller compares plan_date strings coming back
  /// from Postgres, and a second copy of this formatter would eventually
  /// disagree with this one.
  static String isoDate(DateTime d) => _iso(d);

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
