import 'package:share_plus/share_plus.dart';

/// Sharing recipes to WhatsApp and other apps (FR11).
///
/// Text-only for now. Once the web build is deployed we add a link here so a
/// shared recipe opens in the app (or the site) instead of being plain text.
class ShareService {
  /// Builds a readable message from a recipe row plus its ingredients.
  String buildMessage(Map<String, dynamic> recipe) {
    final title = recipe['title'] ?? 'Recipe';
    final cookTime = recipe['cook_time'];
    final diet = recipe['diet'];
    final cuisine = recipe['cuisine'];
    final instructions = recipe['instructions'] as String?;

    final ingredients = <String>[];
    for (final ri in (recipe['recipe_ingredients'] as List?) ?? []) {
      final ing = ri['ingredients'] as Map<String, dynamic>?;
      if (ing == null) continue;
      final qty = (ri['quantity'] ?? '').toString().trim();
      ingredients.add(qty.isEmpty ? '• ${ing['name']}' : '• ${ing['name']} — $qty');
    }

    final meta = [
      if (cookTime != null && '$cookTime'.isNotEmpty) '$cookTime',
      if (diet != null && '$diet'.isNotEmpty) '$diet',
      if (cuisine != null && '$cuisine'.isNotEmpty) '$cuisine',
    ].join(' · ');

    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln();
    if (meta.isNotEmpty) buffer..writeln(meta)..writeln();
    if (ingredients.isNotEmpty) {
      buffer
        ..writeln('Ingredients:')
        ..writeln(ingredients.join('\n'))
        ..writeln();
    }
    if (instructions != null && instructions.trim().isNotEmpty) {
      final steps = instructions.trim();
      // keep the message short enough for messaging apps
      buffer
        ..writeln('Method:')
        ..writeln(steps.length > 600 ? '${steps.substring(0, 600)}…' : steps)
        ..writeln();
    }
    buffer.write('Shared from Recipedia');
    return buffer.toString();
  }

  Future<void> shareRecipe(Map<String, dynamic> recipe) async {
    final title = recipe['title'] ?? 'Recipe';
    // share_plus 13+: the old static Share.share() is deprecated.
    await SharePlus.instance.share(
      ShareParams(
        text: buildMessage(recipe),
        subject: '$title — Recipedia',
      ),
    );
  }
}
