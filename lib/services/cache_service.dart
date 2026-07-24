import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache so favorites and recently-viewed recipes stay readable with a
/// bad connection (FR19) — the app is used in kitchens, where wifi is weakest.
///
/// Strategy: write on every successful fetch, read only when the network call
/// fails. No separate connectivity check needed.
class CacheService {
  static const _favoritesKey = 'cache_favorites';
  static const _recentKey = 'cache_recent';
  static const _recipeKeyPrefix = 'cache_recipe_';
  static const maxRecent = 20;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---------- favorites ----------
  Future<void> saveFavorites(List<Map<String, dynamic>> recipes) async {
    final p = await _prefs;
    await p.setString(_favoritesKey, jsonEncode(recipes));
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final p = await _prefs;
    return _decodeList(p.getString(_favoritesKey));
  }

  // ---------- recently viewed ----------
  /// Adds a recipe to the front of the recent list, de-duplicated.
  Future<void> addRecent(Map<String, dynamic> recipe) async {
    final p = await _prefs;
    final list = _decodeList(p.getString(_recentKey))
      ..removeWhere((r) => r['id'] == recipe['id']);
    list.insert(0, _slim(recipe));
    if (list.length > maxRecent) list.removeRange(maxRecent, list.length);
    await p.setString(_recentKey, jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>> getRecent() async {
    final p = await _prefs;
    return _decodeList(p.getString(_recentKey));
  }

  Future<void> clearRecent() async {
    final p = await _prefs;
    await p.remove(_recentKey);
  }

  // ---------- full recipe (for offline detail view) ----------
  Future<void> saveRecipe(String id, Map<String, dynamic> recipe) async {
    final p = await _prefs;
    await p.setString('$_recipeKeyPrefix$id', jsonEncode(recipe));
  }

  Future<Map<String, dynamic>?> getRecipe(String id) async {
    final p = await _prefs;
    final raw = p.getString('$_recipeKeyPrefix$id');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Drops cached recipe bodies that are no longer favorited or recent,
  /// so storage does not grow without bound.
  Future<void> pruneRecipes() async {
    final p = await _prefs;
    final keep = <String>{
      ...(await getFavorites()).map((r) => '$_recipeKeyPrefix${r['id']}'),
      ...(await getRecent()).map((r) => '$_recipeKeyPrefix${r['id']}'),
    };
    for (final key in p.getKeys()) {
      if (key.startsWith(_recipeKeyPrefix) && !keep.contains(key)) {
        await p.remove(key);
      }
    }
  }

  Future<void> clearAll() async {
    final p = await _prefs;
    for (final key in p.getKeys()) {
      if (key.startsWith('cache_')) await p.remove(key);
    }
  }

  // ---------- helpers ----------
  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)));
    } catch (_) {
      return [];
    }
  }

  /// Only the fields a recipe card needs — keeps the cache small.
  Map<String, dynamic> _slim(Map<String, dynamic> r) => {
        'id': r['id'],
        'title': r['title'],
        'image_url': r['image_url'],
        'cook_time': r['cook_time'],
        'diet': r['diet'],
        'cuisine': r['cuisine'],
        'categories': r['categories'],
      };
}
