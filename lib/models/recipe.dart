/// Modelos de datos de recetas e ingredientes.
library;

enum MealType {
  desayuno('Desayuno', '☀️'),
  almuerzo('Almuerzo', '🍽️'),
  cena('Cena', '🌙'),
  snack('Snack', '🍎');

  const MealType(this.label, this.emoji);
  final String label;
  final String emoji;

  static MealType fromName(String name) =>
      MealType.values.firstWhere((m) => m.name == name);
}

/// Etiquetas que vienen en los datos de cada receta.
abstract final class RecipeTags {
  static const vegetariano = 'vegetariano';
  static const sinGluten = 'sin_gluten';
  static const economico = 'economico';
}

class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    this.basic = false,
    this.substitute,
  });

  final String id;
  final String name;
  final String category;
  final String emoji;

  /// Ingredientes que casi todas las cocinas tienen (sal, aceite, agua...).
  /// No cuentan para "¿qué cocino?" ni se agregan a la lista de compras.
  final bool basic;

  /// Sugerencia para reemplazar este ingrediente si no lo tienes.
  final String? substitute;

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    emoji: json['emoji'] as String,
    basic: json['basic'] as bool? ?? false,
    substitute: json['substitute'] as String?,
  );
}

class RecipeIngredient {
  const RecipeIngredient({
    required this.ingredientId,
    this.quantity,
    this.unit,
    this.note,
  });

  final String ingredientId;

  /// `null` significa "al gusto".
  final double? quantity;
  final String? unit;
  final String? note;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        ingredientId: json['id'] as String,
        quantity: (json['qty'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        note: json['note'] as String?,
      );
}

class RecipeStep {
  const RecipeStep({required this.text, this.timerMinutes, this.image});

  final String text;
  final int? timerMinutes;

  /// Foto opcional del paso (ruta dentro de assets). Si no hay, la app
  /// muestra una ilustración automática según la acción del paso.
  final String? image;

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
    text: json['text'] as String,
    timerMinutes: json['timerMinutes'] as int?,
    image: json['image'] as String?,
  );
}

/// Autoría y licencia de una foto (necesario para fotos con licencia
/// Creative Commons).
class ImageCredit {
  const ImageCredit({
    required this.author,
    required this.license,
    required this.source,
  });

  final String author;
  final String license;
  final String source;

  factory ImageCredit.fromJson(Map<String, dynamic> json) => ImageCredit(
    author: json['author'] as String,
    license: json['license'] as String,
    source: json['source'] as String,
  );
}

class Nutrition {
  const Nutrition({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Valores aproximados por porción.
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  factory Nutrition.fromJson(Map<String, dynamic> json) => Nutrition(
    kcal: json['kcal'] as int,
    protein: json['protein'] as int,
    carbs: json['carbs'] as int,
    fat: json['fat'] as int,
  );
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.meals,
    required this.origin,
    required this.minutes,
    required this.difficulty,
    required this.servings,
    required this.tags,
    required this.nutrition,
    required this.ingredients,
    required this.steps,
    this.tip,
    this.image,
    this.imageCredit,
  });

  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<MealType> meals;
  final String origin;
  final int minutes;
  final String difficulty;
  final int servings;
  final Set<String> tags;
  final Nutrition nutrition;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final String? tip;

  /// Foto del plato (ruta dentro de assets), opcional.
  final String? image;
  final ImageCredit? imageCredit;

  bool get isVegetarian => tags.contains(RecipeTags.vegetariano);
  bool get isGlutenFree => tags.contains(RecipeTags.sinGluten);
  bool get isBudget => tags.contains(RecipeTags.economico);
  bool get isQuick => minutes <= 30;
  bool get isHighProtein => nutrition.protein >= 25;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    description: json['description'] as String,
    meals: (json['meals'] as List)
        .map((m) => MealType.fromName(m as String))
        .toList(),
    origin: json['origin'] as String,
    minutes: json['minutes'] as int,
    difficulty: json['difficulty'] as String,
    servings: json['servings'] as int,
    tags: (json['tags'] as List).cast<String>().toSet(),
    nutrition: Nutrition.fromJson(json['nutrition'] as Map<String, dynamic>),
    ingredients: (json['ingredients'] as List)
        .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
        .toList(),
    steps: (json['steps'] as List)
        .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
        .toList(),
    tip: json['tip'] as String?,
    image: json['image'] as String?,
    imageCredit: json['imageCredit'] == null
        ? null
        : ImageCredit.fromJson(json['imageCredit'] as Map<String, dynamic>),
  );
}
