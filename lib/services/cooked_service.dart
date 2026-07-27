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

  Future<int> countFor(String uid, String recipeId) async {
    final rows = await supabase
        .from('cooked_history')
        .select('id')
        .eq('user_id', uid)
        .eq('recipe_id', recipeId);
    return (rows as List).length;
  }
}
