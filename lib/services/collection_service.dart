import 'supabase_client.dart';

/// Favorite collections — user-made groups like "Weeknight" or "Party".
/// Added in migration 20260725000009.
class CollectionService {
  Future<List<Map<String, dynamic>>> list(String userId) async {
    final rows = await supabase
        .from('collections')
        .select('id, name, sort_order')
        .eq('user_id', userId)
        .order('sort_order')
        .order('name');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> create(String userId, String name) async {
    await supabase.from('collections').insert({
      'user_id': userId,
      'name': name.trim(),
    });
  }

  Future<void> rename(String id, String name) async {
    await supabase.from('collections').update({'name': name.trim()}).eq('id', id);
  }

  Future<void> remove(String id) async {
    await supabase.from('collections').delete().eq('id', id);
  }

  /// Move a saved recipe into a collection (null puts it back in "All").
  Future<void> assign(String userId, String recipeId, String? collectionId) async {
    await supabase
        .from('favorites')
        .update({'collection_id': collectionId})
        .eq('user_id', userId)
        .eq('recipe_id', recipeId);
  }
}
