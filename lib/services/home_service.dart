import 'supabase_client.dart';

/// Queries that only Home needs. Kept separate from RecipeService so Home and
/// the Recipes tab never share state — sharing one controller between them is
/// exactly what made the two screens identical.
class HomeService {
  /// Scan matching that honours the signed-in user's pantry staples and flags
  /// their allergens (migration 20260725000009).
  Future<List<Map<String, dynamic>>> matchForUser(List<String> pantry) async {
    if (pantry.isEmpty) return [];
    final rows = await supabase
        .rpc('match_recipes_for_user', params: {'scanned': pantry});
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Most recently approved recipes — surfaces community submissions, which
  /// are the only original content in the catalogue.
  Future<List<Map<String, dynamic>>> newest({int limit = 6}) async {
    final rows = await supabase
        .from('recipes')
        .select('id, title, image_url, cook_time, cuisine, diet, created_at')
        .eq('status', 'approved')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
