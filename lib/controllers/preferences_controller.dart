import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import 'home_controller.dart';
import 'profile_controller.dart';

/// Editing for what onboarding set once. Saves immediately on change rather
/// than behind a Save button — every one of these settings changes what the
/// scan returns, so the feedback should be instant.
class PreferencesController extends GetxController {
  final OnboardingService _service = OnboardingService();
  final AuthService _auth = AuthService();

  final isLoading = false.obs;
  final isSaving = false.obs;

  final diets = <Map<String, dynamic>>[].obs;
  final allergenOptions = <Map<String, dynamic>>[].obs;
  final stapleOptions = <Map<String, dynamic>>[].obs;
  final searchResults = <Map<String, dynamic>>[].obs;

  final diet = Rxn<String>();
  final hideUnsafe = true.obs;
  final allergies = <Map<String, dynamic>>[].obs;
  final staples = <String>{}.obs;

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
      final results = await Future.wait([
        _service.dietsWithCounts(),
        _service.allergenCandidates(),
        _service.stapleCandidates(),
        _service.loadPreferences(uid),
      ]);
      diets.value = List<Map<String, dynamic>>.from(results[0] as List);
      allergenOptions.value = List<Map<String, dynamic>>.from(results[1] as List);
      stapleOptions.value = List<Map<String, dynamic>>.from(results[2] as List);

      final prefs = results[3] as Map<String, dynamic>;
      diet.value = prefs['diet'] as String?;
      hideUnsafe.value = prefs['hide_unsafe'] == true;
      allergies.value = List<Map<String, dynamic>>.from(prefs['allergies'] as List);
      staples.value = Set<String>.from(prefs['staples'] as List);
    } catch (_) {
      Get.snackbar('Offline', 'Could not load your preferences.');
    } finally {
      isLoading.value = false;
    }
  }

  bool isAllergy(String id) => allergies.any((a) => a['id'] == id);

  Future<void> setDiet(String value) async {
    diet.value = value;
    await _saveDiet();
  }

  Future<void> setHideUnsafe(bool value) async {
    hideUnsafe.value = value;
    await _saveDiet();
  }

  Future<void> toggleAllergy(Map<String, dynamic> ing) async {
    final id = ing['id'] as String;
    final i = allergies.indexWhere((a) => a['id'] == id);
    i >= 0 ? allergies.removeAt(i) : allergies.add(ing);
    await _save(() => _service.saveAllergies(
        _uid!, allergies.map((a) => a['id'] as String).toList()));
  }

  Future<void> toggleStaple(String id) async {
    staples.contains(id) ? staples.remove(id) : staples.add(id);
    await _save(() => _service.saveStaples(_uid!, staples.toList()));
  }

  Future<void> search(String q) async {
    if (q.trim().length < 2) {
      searchResults.clear();
      return;
    }
    searchResults.value = await _service.searchIngredients(q);
  }

  Future<void> _saveDiet() =>
      _save(() => _service.saveDiet(_uid!, diet.value ?? 'any', hideUnsafe.value));

  Future<void> _save(Future<void> Function() action) async {
    if (_uid == null) return;
    try {
      isSaving.value = true;
      await action();
      // These feed the scan RPC directly, so anything already on screen is now
      // stale. Refresh rather than leaving the user looking at old matches.
      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().loadProfile();
      }
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().load();
      }
    } catch (_) {
      Get.snackbar('Not saved', 'Could not save that change.');
      await load();
    } finally {
      isSaving.value = false;
    }
  }
}
