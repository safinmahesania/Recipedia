import 'supabase_client.dart';

/// Reads and writes for the onboarding flow.
///
/// Every column and table this touches already exists (migration
/// 20260725000009), so onboarding is UI over a schema that was built for it.
class OnboardingService {
  /// Diet options with live recipe counts, so each choice shows what it costs
  /// — "Vegetarian · 712 recipes" is a very different decision from a bare
  /// radio button.
  Future<List<Map<String, dynamic>>> dietsWithCounts() async {
    final rows = await supabase.rpc('distinct_diets');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Curated allergen shortlist, resolved against real rows so the ids are
  /// valid for user_allergies. Anything not covered here is reachable through
  /// search.
  static const _allergenNames = [
    'peanuts', 'cashew nuts', 'almonds', 'walnuts', 'pistachios',
    'sesame seeds', 'egg', 'milk', 'curd', 'paneer', 'cheese',
    'fish', 'prawns', 'soy sauce', 'whole wheat flour',
  ];

  Future<List<Map<String, dynamic>>> allergenCandidates() =>
      _byNames(_allergenNames);

  /// The sixteen most-used ingredients in the catalogue. Marking these is what
  /// makes the biggest difference to scan results, because they appear in
  /// hundreds of recipes each.
  static const _stapleNames = [
    'salt', 'oil', 'turmeric powder', 'cumin seeds', 'mustard seeds',
    'ginger', 'garlic', 'onion', 'tomato', 'green chilli',
    'curry leaves', 'coriander leaves', 'ghee', 'sugar',
    'red chilli powder', 'garam masala',
  ];

  Future<List<Map<String, dynamic>>> stapleCandidates() =>
      _byNames(_stapleNames);

  Future<List<Map<String, dynamic>>> _byNames(List<String> names) async {
    final rows = await supabase
        .from('ingredients')
        .select('id, name, icon_key, category')
        .inFilter('name', names);
    final found = List<Map<String, dynamic>>.from(rows as List);
    // Preserve the curated order rather than whatever Postgres returns.
    final order = {for (var i = 0; i < names.length; i++) names[i]: i};
    found.sort((a, b) => (order[(a['name'] as String).toLowerCase()] ?? 99)
        .compareTo(order[(b['name'] as String).toLowerCase()] ?? 99));
    return found;
  }

  Future<List<Map<String, dynamic>>> searchIngredients(String q) async {
    final term = q.toLowerCase().trim();
    if (term.length < 2) return [];
    final rows = await supabase
        .from('ingredients')
        .select('id, name, icon_key, category')
        .ilike('name', '%$term%')
        .limit(12);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> saveDiet(String uid, String diet, bool hideUnsafe) async {
    await supabase.from('profiles').update({
      'diet_preference': diet,
      'hide_unsafe': hideUnsafe,
    }).eq('id', uid);
  }

  Future<void> saveAllergies(String uid, List<String> ingredientIds) async {
    await supabase.from('user_allergies').delete().eq('user_id', uid);
    if (ingredientIds.isEmpty) return;
    await supabase.from('user_allergies').insert([
      for (final id in ingredientIds) {'user_id': uid, 'ingredient_id': id}
    ]);
  }

  Future<void> saveStaples(String uid, List<String> ingredientIds) async {
    await supabase.from('user_pantry_staples').delete().eq('user_id', uid);
    if (ingredientIds.isEmpty) return;
    await supabase.from('user_pantry_staples').insert([
      for (final id in ingredientIds) {'user_id': uid, 'ingredient_id': id}
    ]);
  }

  /// Current values, for the editable screen in Profile. Onboarding writes
  /// these once; without a read path there is no way to change them later.
  Future<Map<String, dynamic>> loadPreferences(String uid) async {
    final profile = await supabase
        .from('profiles')
        .select('diet_preference, hide_unsafe')
        .eq('id', uid)
        .single();
    final allergies = await supabase
        .from('user_allergies')
        .select('ingredients(id, name, icon_key, category)')
        .eq('user_id', uid);
    final staples = await supabase
        .from('user_pantry_staples')
        .select('ingredient_id')
        .eq('user_id', uid);
    return {
      'diet': profile['diet_preference'],
      'hide_unsafe': profile['hide_unsafe'] ?? true,
      'allergies': [
        for (final a in (allergies as List))
          if ((a as Map)['ingredients'] != null)
            Map<String, dynamic>.from(a['ingredients'] as Map)
      ],
      'staples': [
        for (final s in (staples as List)) (s as Map)['ingredient_id'] as String
      ],
    };
  }

  /// A finished profile always has a diet set — the diet step cannot be
  /// skipped, and "no preference" is stored as 'any'. So a null here means the
  /// user has never been through the flow, which avoids adding a column.
  Future<bool> needsOnboarding(String uid) async {
    try {
      final row = await supabase
          .from('profiles')
          .select('diet_preference')
          .eq('id', uid)
          .single();
      return row['diet_preference'] == null;
    } catch (_) {
      return false; // never trap someone in onboarding because of a bad network
    }
  }
}
