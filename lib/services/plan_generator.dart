import 'dart:math';

import '../data/recipe_repository.dart';
import '../models/diet_plan.dart';
import '../models/recipe.dart';

const weekDays = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Arma menús semanales a partir del catálogo de recetas.
///
/// Es determinista: la misma semilla genera el mismo menú, así el plan
/// guardado se puede reconstruir sin almacenar cada receta.
/// Parte aproximada de las calorías del día para cada comida.
const mealShare = {
  MealType.desayuno: 0.25,
  MealType.almuerzo: 0.35,
  MealType.cena: 0.27,
  MealType.snack: 0.13,
};

/// Cuántas recetas de la cola se comparan para cada comida.
const _lookahead = 4;

class PlanGenerator {
  const PlanGenerator(this.repository);

  final RecipeRepository repository;

  List<Recipe> candidates(DietGoal goal, MealType meal) {
    final strict = repository.recipes
        .where((r) => goal.accepts(r, meal))
        .toList();
    if (strict.isNotEmpty) return strict;
    // Si las reglas son demasiado estrictas para una comida, relajamos los
    // límites de calorías/proteína pero mantenemos las etiquetas (p. ej.
    // vegetariano), que no se pueden ignorar.
    return repository.recipes
        .where(
          (r) =>
              r.meals.contains(meal) && r.tags.containsAll(goal.requiredTags),
        )
        .toList();
  }

  WeeklyPlan generate(DietGoal goal, {required int seed, int people = 1}) {
    final random = Random(seed);
    final pools = {
      for (final meal in MealType.values) meal: candidates(goal, meal),
    };
    // Barajamos cada lista y la recorremos en orden para repetir lo menos
    // posible durante la semana.
    final queues = <MealType, List<Recipe>>{};
    final cursors = <MealType, int>{};
    for (final entry in pools.entries) {
      queues[entry.key] = [...entry.value]..shuffle(random);
      cursors[entry.key] = 0;
    }

    final days = <PlanDay>[];
    for (final dayName in weekDays) {
      final meals = <MealType, Recipe>{};
      final usedToday = <String>{};
      for (final meal in MealType.values) {
        final queue = queues[meal]!;
        if (queue.isEmpty) continue;
        // Entre las próximas opciones de la cola elegimos la que más se
        // acerca a la parte de calorías que le toca a esta comida, sin
        // repetir receta el mismo día (p. ej. en almuerzo y cena).
        final target = goal.dailyKcalTarget * mealShare[meal]!;
        final window = min(_lookahead, queue.length);
        final start = cursors[meal]!;
        var bestOffset = -1;
        var bestDiff = double.infinity;
        for (var offset = 0; offset < window; offset++) {
          final candidate = queue[(start + offset) % queue.length];
          if (usedToday.contains(candidate.id)) continue;
          final diff = (candidate.nutrition.kcal - target).abs();
          if (diff < bestDiff) {
            bestDiff = diff;
            bestOffset = offset;
          }
        }
        if (bestOffset < 0) bestOffset = 0;
        final chosenIndex = (start + bestOffset) % queue.length;
        final chosen = queue[chosenIndex];
        // Movemos la elegida al frente y avanzamos el cursor, así las que
        // no se eligieron siguen disponibles para los días siguientes.
        final frontIndex = start % queue.length;
        queue[chosenIndex] = queue[frontIndex];
        queue[frontIndex] = chosen;
        cursors[meal] = start + 1;
        meals[meal] = chosen;
        usedToday.add(chosen.id);
      }
      days.add(PlanDay(name: dayName, meals: meals));
    }
    return WeeklyPlan(
      goal: goal,
      days: days,
      seed: seed,
      people: people,
      portionsPerPerson: portionsFor(goal, days),
    );
  }

  /// Calcula cuántas porciones por persona (entre 1 y 1½, en cuartos) hacen
  /// falta para acercarse a la referencia de calorías del objetivo. En los
  /// planes con límite de calorías redondeamos hacia abajo para no pasarnos.
  static double portionsFor(DietGoal goal, List<PlanDay> days) {
    if (days.isEmpty) return 1;
    final rawAverage = days.fold(0, (sum, d) => sum + d.kcal) / days.length;
    if (rawAverage <= 0) return 1;
    final ideal = goal.dailyKcalTarget / rawAverage;
    var quarters = goal.maxKcalPerMeal.isNotEmpty
        ? (ideal * 4).floor()
        : (ideal * 4).round();
    // Pero ningún día puede quedar por debajo del mínimo saludable.
    final minDaily = goal.minDailyKcal;
    if (minDaily != null) {
      final lowestDay = days.map((d) => d.kcal).reduce(min);
      if (lowestDay > 0) {
        quarters = max(quarters, (minDaily / lowestDay * 4).ceil());
      }
    }
    return (quarters / 4).clamp(1.0, 1.5);
  }
}
