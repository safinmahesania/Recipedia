import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/recipe_service.dart';
import '../services/scan_service.dart';

/// Scan flow state: pick image -> detect -> user confirms/edits the
/// ingredient list -> match recipes on CORE ingredients.
class ScanController extends GetxController {
  final ScanService _scan = ScanService();
  final RecipeService _recipes = RecipeService();
  final ImagePicker _picker = ImagePicker();

  final isDetecting = false.obs;
  final isSearching = false.obs;
  final image = Rxn<File>();

  /// Confirmed ingredient list — detected items land here, and the user can
  /// add or remove before searching. Every correction is a better match.
  final ingredients = <String>[].obs;
  final results = <Map<String, dynamic>>[].obs;
  final searched = false.obs;

  bool get modelReady => _scan.isModelAvailable;

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

  void addIngredient(String name) {
    final clean = name.toLowerCase().trim();
    if (clean.isEmpty || ingredients.contains(clean)) return;
    ingredients.add(clean);
  }

  void removeIngredient(String name) => ingredients.remove(name);

  void reset() {
    image.value = null;
    ingredients.clear();
    results.clear();
    searched.value = false;
  }

  Future<void> findRecipes() async {
    if (ingredients.isEmpty) return;
    try {
      isSearching.value = true;
      results.value = await _recipes.getRecipesByScannedIngredients(ingredients);
      searched.value = true;
    } finally {
      isSearching.value = false;
    }
  }
}
