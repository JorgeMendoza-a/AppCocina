import '../data/recipe_repository.dart';
import '../models/recipe.dart';

/// Resultado de comparar una receta con los ingredientes que tiene el usuario.
class RecipeMatch {
  const RecipeMatch({
    required this.recipe,
    required this.have,
    required this.missing,
  });

  final Recipe recipe;
  final List<String> have;
  final List<String> missing;

  bool get canCookNow => missing.isEmpty;
  int get total => have.length + missing.length;
  double get ratio => total == 0 ? 0 : have.length / total;
}

/// Busca recetas según los ingredientes disponibles ("¿Qué cocino?").
class RecipeMatcher {
  const RecipeMatcher(this.repository);

  final RecipeRepository repository;

  /// Ingredientes que hacen falta (sin contar básicos como sal o aceite).
  List<String> requiredIngredients(Recipe recipe) => recipe.ingredients
      .map((i) => i.ingredientId)
      .where((id) => !repository.ingredient(id).basic)
      .toSet()
      .toList();

  /// Devuelve las recetas que usan al menos uno de los ingredientes
  /// disponibles, ordenadas por lo que falta (menos primero).
  List<RecipeMatch> match(Set<String> available, {int maxMissing = 3}) {
    if (available.isEmpty) return const [];
    final results = <RecipeMatch>[];
    for (final recipe in repository.recipes) {
      final required = requiredIngredients(recipe);
      final have = required.where(available.contains).toList();
      if (have.isEmpty) continue;
      final missing = required.where((id) => !available.contains(id)).toList();
      if (missing.length > maxMissing) continue;
      results.add(RecipeMatch(recipe: recipe, have: have, missing: missing));
    }
    results.sort((a, b) {
      final byMissing = a.missing.length.compareTo(b.missing.length);
      if (byMissing != 0) return byMissing;
      final byRatio = b.ratio.compareTo(a.ratio);
      if (byRatio != 0) return byRatio;
      return a.recipe.minutes.compareTo(b.recipe.minutes);
    });
    return results;
  }
}
