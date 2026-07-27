import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_client.dart';

/// Name -> artwork lookup.
///
/// Most places that show an ingredient only have its NAME: pantry chips, scan
/// chips, autocomplete rows, the shopping list. They never carry the
/// `icon_key` / `category` columns, so without this every one of them would
/// fall through to a letter chip and the illustration system would look broken.
///
/// The whole ingredients table is ~157 rows, so it is fetched once, cached in
/// SharedPreferences, and read synchronously afterwards. Reads must be sync
/// because IngredientIcon resolves during build.
class IngredientArt {
  IngredientArt._();

  static const _key = 'ingredient_art_v1';
  static final Map<String, _Art> _byName = {};

  static bool get isReady => _byName.isNotEmpty;

  /// Cache first so the first frame already has artwork, then refresh in the
  /// background. Never throws — the letter chip is a perfectly good fallback
  /// and a cold cache must not block startup.
  static Future<void> warm() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_key);
      if (cached != null) _hydrate(jsonDecode(cached) as List);
      unawaited(_refresh(prefs));
    } catch (_) {
      // no artwork this session; icons degrade to letters
    }
  }

  static Future<void> _refresh(SharedPreferences prefs) async {
    try {
      final rows = await supabase
          .from('ingredients')
          .select('name, icon_key, category');
      final list = List<Map<String, dynamic>>.from(rows as List);
      _hydrate(list);
      await prefs.setString(_key, jsonEncode(list));
    } catch (_) {
      // offline — keep whatever the cache gave us
    }
  }

  static void _hydrate(List rows) {
    for (final r in rows) {
      final m = Map<String, dynamic>.from(r as Map);
      final name = (m['name'] ?? '').toString().toLowerCase().trim();
      if (name.isEmpty) continue;
      _byName[name] = _Art(m['icon_key'] as String?, m['category'] as String?);
    }
  }

  static String? iconKeyFor(String name) =>
      _byName[name.toLowerCase().trim()]?.iconKey;

  static String? categoryFor(String name) =>
      _byName[name.toLowerCase().trim()]?.category;
}

class _Art {
  final String? iconKey;
  final String? category;
  const _Art(this.iconKey, this.category);
}
