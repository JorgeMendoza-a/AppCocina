import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/recipe.dart';

/// Acceso de solo lectura al catálogo de recetas e ingredientes.
///
/// Los datos viven en `assets/data/recipes.json`, así la app funciona sin
/// internet. Para agregar recetas basta con editar ese archivo.
class RecipeRepository {
  RecipeRepository({
    required List<Ingredient> ingredients,
    required List<Recipe> recipes,
  }) : ingredients = List.unmodifiable(ingredients),
       recipes = List.unmodifiable(recipes),
       _ingredientsById = {for (final i in ingredients) i.id: i},
       _recipesById = {for (final r in recipes) r.id: r};

  final List<Ingredient> ingredients;
  final List<Recipe> recipes;
  final Map<String, Ingredient> _ingredientsById;
  final Map<String, Recipe> _recipesById;

  static const assetPath = 'assets/data/recipes.json';

  static Future<RecipeRepository> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return RecipeRepository.fromJsonString(raw);
  }

  factory RecipeRepository.fromJsonString(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final ingredients = (json['ingredients'] as List)
        .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
        .toList();
    final recipes = (json['recipes'] as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
    return RecipeRepository(ingredients: ingredients, recipes: recipes);
  }

  Ingredient ingredient(String id) =>
      _ingredientsById[id] ??
      Ingredient(id: id, name: id, category: 'Otros', emoji: '•');

  Recipe? recipe(String id) => _recipesById[id];

  /// Ingredientes que el usuario puede marcar en "¿Qué cocino?".
  List<Ingredient> get selectableIngredients =>
      ingredients.where((i) => !i.basic).toList();

  /// Ingredientes agrupados por categoría, en el orden del archivo.
  Map<String, List<Ingredient>> get selectableByCategory {
    final map = <String, List<Ingredient>>{};
    for (final i in selectableIngredients) {
      map.putIfAbsent(i.category, () => []).add(i);
    }
    return map;
  }
}
