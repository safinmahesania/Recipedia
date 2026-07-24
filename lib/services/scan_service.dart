import 'dart:io';
import 'supabase_client.dart';

/// On-device ingredient detection (C5: self-trained TFLite, no paid API).
///
/// STATUS: the .tflite model is not trained yet, so [isModelAvailable] is
/// false and [detect] returns an empty list. The rest of the scan flow
/// (manual entry + recipe matching) works today; when the model is ready:
///   1. put the files in  assets/ml/model.tflite  and  assets/ml/labels.txt
///   2. declare assets/ml/ in pubspec.yaml
///   3. add the tflite_flutter dependency
///   4. implement _runModel below and flip isModelAvailable to true
class ScanService {
  /// Flip to true once the model asset ships with the app.
  bool get isModelAvailable => false;

  /// Returns detected ingredient names (lowercase) from an image.
  Future<List<String>> detect(File image) async {
    if (!isModelAvailable) return [];
    return _runModel(image);
  }

  /// Ingredient names that actually exist in the database, for autocomplete.
  /// Typing free text is unreliable — "potato" vs "aloo" — so the user picks
  /// from real names instead of guessing.
  Future<List<String>> suggestIngredients(String query) async {
    final q = query.toLowerCase().trim();
    if (q.length < 2) return [];
    final rows = await supabase
        .from('ingredients')
        .select('name')
        .ilike('name', '%$q%')
        .eq('is_pantry', false)
        .limit(10);
    return List<Map<String, dynamic>>.from(rows)
        .map((r) => r['name'] as String)
        .toList();
  }

  Future<List<String>> _runModel(File image) async {
    // TODO: load assets/ml/model.tflite via tflite_flutter, resize the image to
    // the model's input size, run inference, map output indices to labels.txt,
    // and return labels above the confidence threshold.
    throw UnimplementedError('TFLite model not wired yet');
  }
}
