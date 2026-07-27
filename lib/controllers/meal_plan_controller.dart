import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/meal_plan_service.dart';
import '../services/pantry_service.dart';
import 'shopping_controller.dart';

class MealPlanController extends GetxController {
  final MealPlanService _service = MealPlanService();
  final PantryService _pantry = PantryService();
  final AuthService _auth = AuthService();

  final isLoading = false.obs;
  final entries = <Map<String, dynamic>>[].obs;
  final weekStart = DateTime.now().obs;
  final selectedDay = DateTime.now().obs;
  final saved = <Map<String, dynamic>>[].obs;
  final searchResults = <Map<String, dynamic>>[].obs;

  String? get _uid => _auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    weekStart.value = monday;
    selectedDay.value = DateTime(now.year, now.month, now.day);
    load();
  }

  List<DateTime> get week =>
      List.generate(7, (i) => weekStart.value.add(Duration(days: i)));

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      isLoading.value = true;
      final results = await Future.wait([
        _service.forWeek(uid, weekStart.value),
        _service.savedRecipes(uid),
      ]);
      entries.value = List<Map<String, dynamic>>.from(results[0]);
      saved.value = List<Map<String, dynamic>>.from(results[1]);
    } catch (_) {
      Get.snackbar('Offline', 'Could not load your plan.');
    } finally {
      isLoading.value = false;
    }
  }

  void shiftWeek(int weeks) {
    weekStart.value = weekStart.value.add(Duration(days: 7 * weeks));
    selectedDay.value = weekStart.value;
    load();
  }

  int countFor(DateTime day) => entries
      .where((e) => e['plan_date'] == MealPlanService.isoDate(day))
      .length;

  Map<String, dynamic>? entryFor(DateTime day, String slot) {
    for (final e in entries) {
      if (e['plan_date'] == MealPlanService.isoDate(day) &&
          e['slot'] == slot) {
        return e;
      }
    }
    return null;
  }

  Future<void> add(String recipeId, DateTime day, String slot) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _service.add(uid, recipeId, day, slot);
      await load();
    } catch (_) {
      Get.snackbar('Not added', 'That slot may already be taken.');
    }
  }

  Future<void> remove(Map<String, dynamic> entry) async {
    entries.remove(entry);
    try {
      await _service.remove(entry['id'] as String);
    } catch (_) {
      await load();
    }
  }

  Future<void> search(String q) async {
    searchResults.value = await _service.searchRecipes(q);
  }

  /// Plan the week, then buy for it in one tap. Anything already in the pantry
  /// or marked as a staple is left out.
  Future<int> addWeekToShoppingList() async {
    final uid = _uid;
    if (uid == null) return 0;
    final ids = <String>{
      for (final e in entries)
        if ((e['recipes'] as Map?)?['id'] != null)
          (e['recipes'] as Map)['id'] as String
    }.toList();
    if (ids.isEmpty) return 0;

    final pantry = (await _pantry.get()).map((e) => e.toLowerCase()).toSet();
    final missing = await _service.missingForWeek(uid, ids, pantry);
    if (missing.isEmpty) return 0;
    return Get.put(ShoppingController()).addMissing(missing);
  }
}
