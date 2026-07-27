import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';

/// Drives the four preference steps. Each step saves as it advances rather
/// than batching at the end, so a user who drops out after picking a diet
/// still gets that preference applied.
class OnboardingController extends GetxController {
  final OnboardingService _service = OnboardingService();
  final AuthService _auth = AuthService();

  final step = 0.obs;
  /// Diet, allergies, staples — steps 2 through 4. Account creation is step 1
  /// and lives on the signup screen, so the bar counts four throughout.
  static const totalSteps = 3;
  static const stepOffset = 1;
  static const totalWithAccount = totalSteps + stepOffset;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final done = false.obs;

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
    try {
      isLoading.value = true;
      final results = await Future.wait([
        _service.dietsWithCounts(),
        _service.allergenCandidates(),
        _service.stapleCandidates(),
      ]);
      diets.value = results[0];
      allergenOptions.value = results[1];
      stapleOptions.value = results[2];
    } catch (_) {
      // Onboarding must never dead-end on a bad connection; the user can
      // still advance and set preferences later from Profile.
    } finally {
      isLoading.value = false;
    }
  }

  void setDiet(String value) => diet.value = value;

  void toggleAllergy(Map<String, dynamic> ing) {
    final id = ing['id'] as String;
    final i = allergies.indexWhere((a) => a['id'] == id);
    i >= 0 ? allergies.removeAt(i) : allergies.add(ing);
  }

  bool isAllergy(String id) => allergies.any((a) => a['id'] == id);

  void toggleStaple(String id) {
    staples.contains(id) ? staples.remove(id) : staples.add(id);
    _recountPayoff();
  }

  Future<void> search(String q) async {
    if (q.trim().length < 2) {
      searchResults.clear();
      return;
    }
    searchResults.value = await _service.searchIngredients(q);
  }

  /// Recipes that become ready once these staples are marked. Counted against
  /// the real catalogue rather than estimated — a number invented to sell a
  /// setting is a promise the app cannot keep.
  final payoff = 0.obs;

  Future<void> _recountPayoff() async {
    if (staples.isEmpty) {
      payoff.value = 0;
      return;
    }
    payoff.value = await _service.staplePayoff(staples.toList());
  }

  Future<bool> saveCurrentStep() async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      isSaving.value = true;
      switch (step.value) {
        case 0:
          await _service.saveDiet(uid, diet.value ?? 'any', hideUnsafe.value);
          break;
        case 1:
          await _service.saveAllergies(
              uid, allergies.map((a) => a['id'] as String).toList());
          break;
        case 2:
          await _service.saveStaples(uid, staples.toList());
          break;
      }
      return true;
    } catch (_) {
      Get.snackbar('Not saved', 'Could not save that. Check your connection.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> next() async {
    final ok = await saveCurrentStep();
    if (!ok) return false;
    if (step.value < totalSteps - 1) {
      step.value++;
    } else {
      HapticFeedback.mediumImpact();
      done.value = true;
    }
    return true;
  }

  void back() {
    if (step.value > 0) step.value--;
  }
}
