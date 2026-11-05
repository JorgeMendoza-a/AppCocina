import 'recipe.dart';

/// Un objetivo de alimentación (bajar de peso, vegetariano, etc.)
/// y las reglas para elegir recetas que encajen con él.
class DietGoal {
  const DietGoal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.dailyKcalTarget,
    this.requiredTags = const {},
    this.maxKcalPerMeal = const {},
    this.minProteinPerMeal = const {},
    this.minDailyKcal,
  });

  final String id;
  final String name;
  final String emoji;
  final String description;

  /// Referencia orientativa para un adulto promedio.
  final int dailyKcalTarget;

  /// La receta debe tener todas estas etiquetas.
  final Set<String> requiredTags;
  final Map<MealType, int> maxKcalPerMeal;
  final Map<MealType, int> minProteinPerMeal;

  /// Ningún día del plan debe quedar por debajo de esto (por persona).
  final int? minDailyKcal;

  bool accepts(Recipe recipe, MealType meal) {
    if (!recipe.meals.contains(meal)) return false;
    if (!recipe.tags.containsAll(requiredTags)) return false;
    final maxKcal = maxKcalPerMeal[meal];
    if (maxKcal != null && recipe.nutrition.kcal > maxKcal) return false;
    final minProtein = minProteinPerMeal[meal];
    if (minProtein != null && recipe.nutrition.protein < minProtein) {
      return false;
    }
    return true;
  }
}

class PlanDay {
  const PlanDay({required this.name, required this.meals});

  final String name;
  final Map<MealType, Recipe> meals;

  int get kcal => meals.values.fold(0, (sum, r) => sum + r.nutrition.kcal);
  int get protein =>
      meals.values.fold(0, (sum, r) => sum + r.nutrition.protein);
}

class WeeklyPlan {
  const WeeklyPlan({
    required this.goal,
    required this.days,
    required this.seed,
    required this.people,
    this.portionsPerPerson = 1,
  });

  final DietGoal goal;
  final List<PlanDay> days;
  final int seed;
  final int people;

  /// Porciones de cada receta que come una persona (1, 1¼, 1½), para que el
  /// total del día se acerque a la referencia del objetivo.
  final double portionsPerPerson;

  /// Total de porciones a cocinar de cada receta.
  double get totalPortions => people * portionsPerPerson;

  /// Calorías de un día para una persona, ya con sus porciones.
  int dayKcal(PlanDay day) => (day.kcal * portionsPerPerson).round();

  int get averageKcal => days.isEmpty
      ? 0
      : (days.fold(0, (sum, d) => sum + d.kcal) /
                days.length *
                portionsPerPerson)
            .round();

  int get averageProtein => days.isEmpty
      ? 0
      : (days.fold(0, (sum, d) => sum + d.protein) /
                days.length *
                portionsPerPerson)
            .round();
}

/// Objetivos disponibles en la app.
const dietGoals = <DietGoal>[
  DietGoal(
    id: 'saludable',
    name: 'Comer saludable',
    emoji: '🥗',
    description: 'Menú equilibrado y variado para toda la familia.',
    dailyKcalTarget: 2000,
  ),
  DietGoal(
    id: 'bajar_peso',
    name: 'Bajar de peso',
    emoji: '⚖️',
    description: 'Comidas ligeras y saciantes, alrededor de 1500 kcal al día.',
    dailyKcalTarget: 1500,
    minDailyKcal: 1200,
    maxKcalPerMeal: {
      MealType.desayuno: 400,
      MealType.almuerzo: 550,
      MealType.cena: 400,
      MealType.snack: 220,
    },
  ),
  DietGoal(
    id: 'ganar_musculo',
    name: 'Ganar músculo',
    emoji: '💪',
    description: 'Más proteína en cada comida para acompañar el ejercicio.',
    dailyKcalTarget: 2400,
    minProteinPerMeal: {
      MealType.desayuno: 12,
      MealType.almuerzo: 28,
      MealType.cena: 20,
      MealType.snack: 8,
    },
  ),
  DietGoal(
    id: 'vegetariano',
    name: 'Vegetariano',
    emoji: '🌱',
    description: 'Sin carne ni pescado. Incluye huevos y lácteos.',
    dailyKcalTarget: 2000,
    requiredTags: {RecipeTags.vegetariano},
  ),
  DietGoal(
    id: 'sin_gluten',
    name: 'Sin gluten',
    emoji: '🌾',
    description: 'Sin trigo, avena ni salsa de soya común.',
    dailyKcalTarget: 2000,
    requiredTags: {RecipeTags.sinGluten},
  ),
  DietGoal(
    id: 'economico',
    name: 'Económico',
    emoji: '💰',
    description: 'Ingredientes baratos y fáciles de conseguir.',
    dailyKcalTarget: 2000,
    requiredTags: {RecipeTags.economico},
  ),
];

DietGoal dietGoalById(String id) =>
    dietGoals.firstWhere((g) => g.id == id, orElse: () => dietGoals.first);
