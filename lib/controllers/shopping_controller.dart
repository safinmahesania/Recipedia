import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/pantry_service.dart';
import '../services/shopping_service.dart';

class ShoppingController extends GetxController {
  final ShoppingService _service = ShoppingService();
  final PantryService _pantry = PantryService();
  final AuthService _auth = AuthService();

  final isLoading = false.obs;
  final items = <Map<String, dynamic>>[].obs;

  String? get _uid => _auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      isLoading.value = true;
      items.value = await _service.list(uid);
    } catch (_) {
      Get.snackbar('Offline', 'Could not load your list right now.');
    } finally {
      isLoading.value = false;
    }
  }

  String labelOf(Map<String, dynamic> item) {
    final ing = item['ingredients'] as Map<String, dynamic>?;
    return ((ing?['name'] ?? item['custom_name'] ?? '') as String);
  }

  int get openCount => items.where((i) => i['checked'] != true).length;
  int get doneCount => items.where((i) => i['checked'] == true).length;

  /// Grouped by the recipe each item came from, with loose items last. Seeing
  /// "for palak paneer" is what makes a list of eight things make sense.
  Map<String, List<Map<String, dynamic>>> get grouped {
    final out = <String, List<Map<String, dynamic>>>{};
    for (final i in items) {
      final r = i['recipes'] as Map<String, dynamic>?;
      final key = (r?['title'] ?? '') as String;
      out.putIfAbsent(key, () => []).add(i);
    }
    final loose = out.remove('');
    if (loose != null) out[''] = loose;
    return out;
  }

  Future<void> toggle(Map<String, dynamic> item) async {
    final next = item['checked'] != true;
    HapticFeedback.selectionClick();
    item['checked'] = next; // optimistic — a tick should feel instant
    items.refresh();
    try {
      await _service.setChecked(item['id'] as String, next);
    } catch (_) {
      item['checked'] = !next;
      items.refresh();
    }
  }

  Future<void> remove(Map<String, dynamic> item) async {
    items.remove(item);
    try {
      await _service.remove(item['id'] as String);
    } catch (_) {
      await load();
    }
  }

  Future<void> addCustom(String name) async {
    final uid = _uid;
    if (uid == null || name.trim().isEmpty) return;
    await _service.addCustom(uid, name);
    await load();
  }

  Future<int> addMissing(List<String> names, {String? recipeId}) async {
    final uid = _uid;
    if (uid == null) return 0;
    final n = await _service.addMissing(uid, names, recipeId: recipeId);
    await load();
    return n;
  }

  /// The step that closes the loop: what you just bought becomes what you have,
  /// so the next scan is accurate without re-entering anything.
  Future<int> moveCheckedToPantry() async {
    final uid = _uid;
    if (uid == null) return 0;
    final done = items.where((i) => i['checked'] == true).toList();
    if (done.isEmpty) return 0;

    final pantry = await _pantry.get();
    for (final i in done) {
      final name = labelOf(i).toLowerCase().trim();
      if (name.isNotEmpty && !pantry.contains(name)) pantry.add(name);
    }
    await _pantry.save(pantry);
    await _service.clearChecked(uid);
    await load();
    return done.length;
  }
}
