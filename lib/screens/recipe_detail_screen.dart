import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/recipe_repository.dart';
import '../models/recipe.dart';
import '../services/shopping_list_builder.dart';
import '../state/user_data.dart';
import '../utils/quantity_format.dart';
import '../widgets/recipe_widgets.dart';
import 'cooking_mode_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late int _servings = widget.recipe.servings;

  Recipe get recipe => widget.recipe;
  double get _factor => _servings / recipe.servings;

  void _addToShoppingList() {
    final repo = context.read<RecipeRepository>();
    final entries = ShoppingListBuilder(repo)
        .build([recipe], people: _servings);
    final added = context.read<UserData>().addShoppingItems(
      entries.map((e) => (text: e.label, category: e.category)),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'Esos ingredientes ya estaban en tu lista'
                : 'Se agregaron $added ingredientes a tu lista de compras',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RecipeRepository>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: recipeTint(context, recipe),
            actions: [FavoriteButton(recipeId: recipe.id)],
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1.35,
              titlePadding: const EdgeInsetsDirectional.fromSTEB(56, 0, 56, 16),
              title: Text(
                recipe.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                color: recipeTint(context, recipe),
                alignment: const Alignment(0, -0.2),
                child: Text(recipe.emoji, style: const TextStyle(fontSize: 88)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverList.list(
              children: [
                Text(recipe.description, style: text.bodyLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    InfoPill(
                      icon: Icons.schedule,
                      label: '${recipe.minutes} min',
                    ),
                    InfoPill(
                      icon: Icons.signal_cellular_alt,
                      label: recipe.difficulty,
                    ),
                    InfoPill(icon: Icons.public, label: recipe.origin),
                    InfoPill(
                      icon: Icons.restaurant,
                      label: recipe.meals.map((m) => m.label).join(' · '),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (recipe.isVegetarian) const _Tag('🌱 Vegetariano'),
                    if (recipe.isGlutenFree) const _Tag('🌾 Sin gluten'),
                    if (recipe.isBudget) const _Tag('💰 Económico'),
                    if (recipe.isHighProtein) const _Tag('💪 Alto en proteína'),
                  ],
                ),
                const SizedBox(height: 20),
                _NutritionCard(nutrition: recipe.nutrition),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ingredientes',
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _ServingsStepper(
                      servings: _servings,
                      onChanged: (v) => setState(() => _servings = v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final item in recipe.ingredients)
                        _IngredientTile(
                          ingredient: repo.ingredient(item.ingredientId),
                          item: item,
                          factor: _factor,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addToShoppingList,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Agregar a la lista de compras'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparación',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < recipe.steps.length; i++)
                  _StepTile(number: i + 1, step: recipe.steps[i]),
                if (recipe.tip != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: scheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recipe.tip!,
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CookingModeScreen(recipe: recipe),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Empezar a cocinar'),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.nutrition});
  final Nutrition nutrition;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget cell(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label, style: text.bodySmall?.copyWith(color: muted)),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
        child: Column(
          children: [
            Row(
              children: [
                cell('${nutrition.kcal}', 'kcal'),
                cell('${nutrition.protein} g', 'proteína'),
                cell('${nutrition.carbs} g', 'carbohidratos'),
                cell('${nutrition.fat} g', 'grasas'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Valores aproximados por porción',
              style: text.labelSmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  const _ServingsStepper({required this.servings, required this.onChanged});

  final int servings;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Menos porciones',
            onPressed: servings > 1 ? () => onChanged(servings - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Text(
            '$servings ${servings == 1 ? 'porción' : 'porciones'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            tooltip: 'Más porciones',
            onPressed: servings < 20 ? () => onChanged(servings + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({
    required this.ingredient,
    required this.item,
    required this.factor,
  });

  final Ingredient ingredient;
  final RecipeIngredient item;
  final double factor;

  void _showSubstitute(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿No tienes ${ingredient.name.toLowerCase()}?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Puedes usar: ${ingredient.substitute}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qty = item.quantity == null ? null : item.quantity! * factor;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      leading: Text(ingredient.emoji, style: const TextStyle(fontSize: 24)),
      title: Text(ingredient.name),
      subtitle: item.note == null ? null : Text(item.note!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatQuantity(qty, item.unit),
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600, color: muted),
          ),
          if (ingredient.substitute != null)
            IconButton(
              tooltip: 'Ver sustituto',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () => _showSubstitute(context),
            ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.step});

  final int number;
  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    step.text,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                if (step.timerMinutes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: InfoPill(
                      icon: Icons.timer_outlined,
                      label: '${step.timerMinutes} min',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
