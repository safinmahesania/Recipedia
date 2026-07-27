import 'ingredient_art_service.dart';
import 'supabase_client.dart';

/// Shopping list backed by shopping_list_items (migration 20260725000009).
class ShoppingService {
  /// Items with their ingredient and the recipe they came from, so the list
  /// can be grouped by recipe rather than shown as one undifferentiated pile.
  Future<List<Map<String, dynamic>>> list(String uid) async {
    final rows = await supabase
        .from('shopping_list_items')
        .select('id, custom_name, quantity, checked, created_at, '
            'ingredients(id, name, icon_key, category), recipes(id, title)')
        .eq('user_id', uid)
        .order('checked')
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<int> openCount(String uid) async {
    final rows = await supabase
        .from('shopping_list_items')
        .select('id')
        .eq('user_id', uid)
        .eq('checked', false);
    return (rows as List).length;
  }

  /// Adds the missing ingredients of one recipe.
  ///
  /// The scan RPC hands back names; ids come from the cached name lookup. A
  /// name with no matching row still gets added as free text rather than being
  /// silently dropped — the schema allows either, and a shopper would rather
  /// see "kokum" than nothing.
  Future<int> addMissing(
      String uid, List<String> names, {String? recipeId}) async {
    if (names.isEmpty) return 0;
    final existing = await list(uid);
    bool already(String n) => existing.any((e) {
          final ing = e['ingredients'] as Map<String, dynamic>?;
          final label = (ing?['name'] ?? e['custom_name'] ?? '').toString();
          return label.toLowerCase() == n.toLowerCase() && e['checked'] != true;
        });

    final rows = <Map<String, dynamic>>[];
    for (final n in names) {
      if (already(n)) continue;
      final id = IngredientArt.idFor(n);
      rows.add({
        'user_id': uid,
        if (id != null) 'ingredient_id': id,
        if (id == null) 'custom_name': n,
        if (recipeId != null) 'recipe_id': recipeId,
      });
    }
    if (rows.isEmpty) return 0;
    await supabase.from('shopping_list_items').insert(rows);
    return rows.length;
  }

  Future<void> addCustom(String uid, String name, {String? quantity}) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final id = IngredientArt.idFor(clean);
    await supabase.from('shopping_list_items').insert({
      'user_id': uid,
      if (id != null) 'ingredient_id': id,
      if (id == null) 'custom_name': clean,
      if (quantity != null && quantity.trim().isNotEmpty) 'quantity': quantity.trim(),
    });
  }

  Future<void> setChecked(String itemId, bool checked) async {
    await supabase
        .from('shopping_list_items')
        .update({'checked': checked}).eq('id', itemId);
  }

  Future<void> remove(String itemId) async {
    await supabase.from('shopping_list_items').delete().eq('id', itemId);
  }

  Future<void> clearChecked(String uid) async {
    await supabase
        .from('shopping_list_items')
        .delete()
        .eq('user_id', uid)
        .eq('checked', true);
  }
}
