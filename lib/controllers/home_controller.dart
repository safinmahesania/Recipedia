import 'package:get/get.dart';
import 'profile_controller.dart';
import '../services/cache_service.dart';
import '../services/home_service.dart';
import '../services/pantry_service.dart';

/// Home state. Deliberately owns NO filter state — filtering belongs to the
/// Recipes tab. Home answers one question: what can I cook tonight?
class HomeController extends GetxController {
  final HomeService _home = HomeService();
  final PantryService _pantry = PantryService();
  final CacheService _cache = CacheService();

  final isLoading = false.obs;
  final pantry = <String>[].obs;

  final readyToCook = <Map<String, dynamic>>[].obs;
  final almostThere = <Map<String, dynamic>>[].obs;
  final recentlyViewed = <Map<String, dynamic>>[].obs;
  final newest = <Map<String, dynamic>>[].obs;

  /// Mirrors profiles.hide_unsafe. Read from the profile rather than assumed,
  /// so the setting the user chose in onboarding is the one that applies.
  bool get hideUnsafe =>
      Get.put(ProfileController()).profile.value?.hideUnsafe ?? true;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      pantry.value = await _pantry.get();

      final results = await Future.wait([
        _home.matchForUser(pantry),
        _home.newest(),
        _cache.getRecent(),
      ]);

      final matches = results[0];
      final visible = hideUnsafe
          ? matches.where((r) => r['has_allergen'] != true).toList()
          : matches;

      readyToCook.value =
          visible.where((r) => (r['missing_count'] as num?) == 0).toList();
      almostThere.value = visible.where((r) {
        final m = (r['missing_count'] as num?)?.toInt() ?? 99;
        return m > 0 && m <= 2;
      }).take(6).toList();

      newest.value = results[1];
      recentlyViewed.value = results[2].take(6).toList();
    } catch (_) {
      // Offline or RPC unavailable — Home still renders whatever is cached.
      recentlyViewed.value = (await _cache.getRecent()).take(6).toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToPantry(String name) async {
    final clean = name.toLowerCase().trim();
    if (clean.isEmpty || pantry.contains(clean)) return;
    pantry.add(clean);
    await _pantry.save(pantry);
    await load();
  }

  Future<void> removeFromPantry(String name) async {
    pantry.remove(name);
    await _pantry.save(pantry);
    await load();
  }

  Future<void> clearPantry() async {
    pantry.clear();
    await _pantry.clear();
    await load();
  }

  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
