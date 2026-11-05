import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/recipe_repository.dart';
import '../models/diet_plan.dart';
import '../models/recipe.dart';
import '../services/plan_generator.dart';
import '../services/shopping_list_builder.dart';
import '../state/user_data.dart';
import '../utils/quantity_format.dart';
import '../widgets/recipe_widgets.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<UserData>().plan;
    return saved == null ? const _GoalPicker() : _PlanView(saved: saved);
  }
}

// ---------------------------------------------------------------------------
// Elegir objetivo
// ---------------------------------------------------------------------------

class _GoalPicker extends StatefulWidget {
  const _GoalPicker();

  @override
  State<_GoalPicker> createState() => _GoalPickerState();
}

class _GoalPickerState extends State<_GoalPicker> {
  String _goalId = dietGoals.first.id;
  int _people = 1;

  void _create() {
    context.read<UserData>().savePlan(
      SavedPlan(
        goalId: _goalId,
        seed: Random().nextInt(1 << 31),
        people: _people,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi plan semanal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'Elige un objetivo y armamos tu menú de la semana con '
            'desayuno, almuerzo, cena y snack, más la lista de compras.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (final goal in dietGoals)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GoalTile(
                goal: goal,
                selected: goal.id == _goalId,
                onTap: () => setState(() => _goalId = goal.id),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            '¿Para cuántas personas?',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              for (final n in [1, 2, 3, 4, 6])
                ButtonSegment(value: n, label: Text('$n')),
            ],
            selected: {_people},
            onSelectionChanged: (s) => setState(() => _people = s.first),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Crear mi plan'),
          ),
          const SizedBox(height: 16),
          const _Disclaimer(),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  final DietGoal goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: selected ? scheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Text(goal.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goal.description,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ver plan
// ---------------------------------------------------------------------------

class _PlanView extends StatelessWidget {
  const _PlanView({required this.saved});

  final SavedPlan saved;

  void _regenerate(BuildContext context) {
    context.read<UserData>().savePlan(
      SavedPlan(
        goalId: saved.goalId,
        seed: Random().nextInt(1 << 31),
        people: saved.people,
      ),
    );
  }

  Future<void> _changeGoal(BuildContext context) async {
    final userData = context.read<UserData>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cambiar de plan?'),
        content: const Text('Se reemplazará el menú de esta semana.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
    if (ok == true) userData.clearPlan();
  }

  void _addToShopping(BuildContext context, WeeklyPlan plan) {
    final repo = context.read<RecipeRepository>();
    final recipes = plan.days.expand((d) => d.meals.values);
    final entries = ShoppingListBuilder(repo)
        .build(recipes, people: plan.totalPortions);
    final added = context.read<UserData>().addShoppingItems(
      entries.map((e) => (text: e.label, category: e.category)),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'La lista ya tenía estos ingredientes'
                : 'Se agregaron $added ingredientes a tu lista de compras',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RecipeRepository>();
    final goal = dietGoalById(saved.goalId);
    final plan = PlanGenerator(repo)
        .generate(goal, seed: saved.seed, people: saved.people);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi plan semanal'),
        actions: [
          IconButton(
            tooltip: 'Generar otro menú',
            icon: const Icon(Icons.refresh),
            onPressed: () => _regenerate(context),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'change') _changeGoal(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'change', child: Text('Cambiar objetivo')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(goal.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name,
                              style: text.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              'Para ${plan.people} ${plan.people == 1 ? 'persona' : 'personas'}',
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cada persona come ${formatPortions(plan.portionsPerPerson)} '
                    'de cada receta.',
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Promedio por persona: ~${plan.averageKcal} kcal y '
                    '${plan.averageProtein} g de proteína al día '
                    '(referencia: ${goal.dailyKcalTarget} kcal).',
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _addToShopping(context, plan),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Lista de compras de la semana'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final day in plan.days) ...[
            _DayCard(day: day, plan: plan),
            const SizedBox(height: 12),
          ],
          const _Disclaimer(),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.plan});

  final PlanDay day;
  final WeeklyPlan plan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    day.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(
                  '~${plan.dayKcal(day)} kcal',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          for (final meal in MealType.values)
            if (day.meals[meal] case final recipe?)
              ListTile(
                leading: RecipeEmoji(recipe: recipe, size: 40),
                title: Text(recipe.name),
                subtitle: Text(
                  '${meal.label} · ${recipe.minutes} min · ${(recipe.nutrition.kcal * plan.portionsPerPerson).round()} kcal',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openRecipe(context, recipe),
              ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Los planes y las calorías son orientativos para adultos sanos. '
            'No reemplazan la consulta con un médico o nutricionista.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
