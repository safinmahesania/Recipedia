import 'supabase_client.dart';

/// cooked_history (migration 20260725000009). Recording a cook is what turns
/// "recipes I looked at" into "recipes I actually make".
class CookedService {
  Future<void> record(String uid, String recipeId, {String? note}) async {
    await supabase.from('cooked_history').insert({
      'user_id': uid,
      'recipe_id': recipeId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  /// Times cooked and when it was last made, in one round trip. Both numbers
  /// are shown together everywhere, so fetching them separately would mean two
  /// queries for one line of text.
  Future<({int count, DateTime? last})> statsFor(
      String uid, String recipeId) async {
    final rows = await supabase
        .from('cooked_history')
        .select('cooked_at')
        .eq('user_id', uid)
        .eq('recipe_id', recipeId)
        .order('cooked_at', ascending: false);
    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) return (count: 0, last: null);
    return (
      count: list.length,
      last: DateTime.tryParse(list.first['cooked_at'].toString()),
    );
  }

  /// Everything the user has cooked, newest first, with enough of the recipe
  /// joined to render a row.
  Future<List<Map<String, dynamic>>> history(String uid, {int limit = 100}) async {
    final rows = await supabase
        .from('cooked_history')
        .select('id, cooked_at, note, '
            'recipes(id, title, image_url, cook_time, cuisine)')
        .eq('user_id', uid)
        .order('cooked_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> remove(String entryId) async {
    await supabase.from('cooked_history').delete().eq('id', entryId);
  }
}
