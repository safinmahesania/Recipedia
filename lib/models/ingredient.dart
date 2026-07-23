/// Plain data model for an ingredient, plus its role on a recipe.
/// role: 'core' | 'optional'   isPantry: common at-home item (salt, oil).
class Ingredient {
  final String id;
  final String name;
  final bool isPantry;
  final String? role;
  final String? quantity;

  const Ingredient({
    required this.id,
    required this.name,
    this.isPantry = false,
    this.role,
    this.quantity,
  });

  /// From a plain ingredients row.
  factory Ingredient.fromMap(Map<String, dynamic> map) => Ingredient(
        id: map['id'] as String,
        name: map['name'] ?? '',
        isPantry: map['is_pantry'] ?? false,
      );

  /// From a recipe_ingredients row that nests ingredients(...).
  factory Ingredient.fromRecipeIngredient(Map<String, dynamic> map) {
    final ing = (map['ingredients'] as Map<String, dynamic>?) ?? {};
    return Ingredient(
      id: ing['id'] ?? '',
      name: ing['name'] ?? '',
      isPantry: ing['is_pantry'] ?? false,
      role: map['role'],
      quantity: map['quantity'],
    );
  }

  bool get isCore => role == 'core';
}
