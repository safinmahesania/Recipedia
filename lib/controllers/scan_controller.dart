import 'dart:io';
import 'dart:async';

import 'package:get/get.dart';
import 'profile_controller.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/pantry_service.dart';
import '../services/recipe_service.dart';
import '../services/scan_service.dart';

/// Scan flow state: pick image -> detect -> user confirms/edits the
/// ingredient list -> match recipes on CORE ingredients.
class ScanController extends GetxController {
  final ScanService _scan = ScanService();
  final RecipeService _recipes = RecipeService();
  final ImagePicker _picker = ImagePicker();
  final PantryService _pantry = PantryService();
  final AuthService _auth = AuthService();

  final isDetecting = false.obs;
  final isSearching = false.obs;
  final image = Rxn<File>();

  /// Confirmed ingredient list — detected items land here, and the user can
  /// add or remove before searching. Every correction is a better match.
  final ingredients = <String>[].obs;
  final results = <Map<String, dynamic>>[].obs;
  final searched = false.obs;
  final suggestions = <Map<String, dynamic>>[].obs;

  /// Every keystroke used to fire a query. On a phone keyboard that is one
  /// round trip per character, and results arriving out of order meant the
  /// list could settle on a stale prefix.
  Timer? _debounce;
  int _requestId = 0;

  /// Pantry staples, shown separately so it is obvious why a recipe matched
  /// without them being entered.
  final staples = <Map<String, dynamic>>[].obs;

  bool get modelReady => _scan.isModelAvailable;

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    _restore();
  }

  /// Home and Scan were keeping two different lists both called "your pantry".
  /// They are one thing now: Scan reads and writes the same store Home does.
  Future<void> _restore() async {
    ingredients.value = await _pantry.get();
    final uid = _auth.currentUser?.id;
    if (uid == null) return;
    try {
      staples.value = await _scan.myStaples(uid);
    } catch (_) {
      staples.clear();
    }
  }

  Future<void> _persist() => _pantry.save(ingredients.toList());

  Future<void> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    image.value = File(picked.path);
    await _detect();
  }

  Future<void> _detect() async {
    final file = image.value;
    if (file == null) return;
    try {
      isDetecting.value = true;
      final found = await _scan.detect(file);
      for (final name in found) {
        if (!ingredients.contains(name)) ingredients.add(name);
      }
    } finally {
      isDetecting.value = false;
    }
  }

  /// Autocomplete against real ingredient names in the database.
  void suggest(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      suggestions.clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 220), () => _run(query));
  }

  Future<void> _run(String query) async {
    final id = ++_requestId;
    try {
      final rows = await _scan.suggestIngredients(query);
      // Drop anything that came back after a newer keystroke.
      if (id != _requestId) return;
      suggestions.value = rows;
    } catch (_) {
      if (id == _requestId) suggestions.clear();
    }
  }


  void clearSuggestions() => suggestions.clear();

  void addIngredient(String name) {
    final clean = name.toLowerCase().trim();
    if (clean.isEmpty || ingredients.contains(clean)) return;
    ingredients.add(clean);
    suggestions.clear();
    _persist();
  }

  void removeIngredient(String name) {
    ingredients.remove(name);
    _persist();
  }

  void reset() {
    image.value = null;
    ingredients.clear();
    results.clear();
    searched.value = false;
    _persist();
  }

  List<Map<String, dynamic>> get ready =>
      results.where((r) => (r['missing_count'] ?? 0) == 0).toList();

  List<Map<String, dynamic>> get almost =>
      results.where((r) => (r['missing_count'] ?? 0) > 0).toList();

  Future<void> findRecipes() async {
    if (ingredients.isEmpty) return;
    try {
      isSearching.value = true;
      final rows = await _recipes.getRecipesByScannedIngredients(ingredients);
      // Default to hiding: if the profile has not loaded we err toward not
      // showing someone a recipe containing their allergen.
      final hide = Get.put(ProfileController()).profile.value?.hideUnsafe ?? true;
      results.value =
          hide ? rows.where((r) => r['has_allergen'] != true).toList() : rows;
      searched.value = true;
    } finally {
      isSearching.value = false;
    }
  }
}
