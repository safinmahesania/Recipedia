import 'package:shared_preferences/shared_preferences.dart';

/// The user's current pantry — the ingredient list Home matches against.
///
/// Stored locally rather than server-side on purpose: a pantry is volatile
/// (it changes every time you cook) and Home must render instantly and offline.
/// The durable, server-side list is `user_pantry_staples`, which is a different
/// thing: staples are what you ALWAYS have, this is what you have RIGHT NOW.
class PantryService {
  static const _key = 'pantry_items';

  Future<List<String>> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  Future<void> save(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, items);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
