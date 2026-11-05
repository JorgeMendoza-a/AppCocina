import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/recipe_repository.dart';
import '../models/recipe.dart';
import '../utils/text_search.dart';
import '../widgets/recipe_widgets.dart';
import 'about_screen.dart';

enum QuickFilter {
  rapido('Rápido (≤30 min)'),
  vegetariano('Vegetariano'),
  sinGluten('Sin gluten'),
  economico('Económico'),
  proteina('Alto en proteína'),
  ligero('Ligero (≤350 kcal)');

  const QuickFilter(this.label);
  final String label;

  bool matches(Recipe r) => switch (this) {
    QuickFilter.rapido => r.isQuick,
    QuickFilter.vegetariano => r.isVegetarian,
    QuickFilter.sinGluten => r.isGlutenFree,
    QuickFilter.economico => r.isBudget,
    QuickFilter.proteina => r.isHighProtein,
    QuickFilter.ligero => r.nutrition.kcal <= 350,
  };
}

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  MealType? _meal;
  final Set<QuickFilter> _filters = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _filtered(RecipeRepository repo) {
    final query = normalizeForSearch(_query);
    return repo.recipes.where((r) {
      if (_meal != null && !r.meals.contains(_meal)) return false;
      if (!_filters.every((f) => f.matches(r))) return false;
      if (query.isEmpty) return true;
      final haystack = normalizeForSearch(
        [
          r.name,
          r.description,
          r.origin,
          ...r.ingredients.map((i) => repo.ingredient(i.ingredientId).name),
        ].join(' '),
      );
      return query.split(' ').every(haystack.contains);
    }).toList();
  }

  void _clearFilters() => setState(() {
    _searchController.clear();
    _query = '';
    _meal = null;
    _filters.clear();
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RecipeRepository>();
    final recipes = _filtered(repo);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AppCocina'),
        actions: [
          IconButton(
            tooltip: 'Acerca de',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Qué quieres cocinar hoy?',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar receta o ingrediente',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Borrar búsqueda',
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _query = '';
                              }),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _MealChip(
                    label: 'Todas',
                    selected: _meal == null,
                    onTap: () => setState(() => _meal = null),
                  ),
                  for (final meal in MealType.values)
                    _MealChip(
                      emoji: meal.emoji,
                      label: meal.label,
                      selected: _meal == meal,
                      onTap: () =>
                          setState(() => _meal = _meal == meal ? null : meal),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final f in QuickFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f.label),
                        selected: _filters.contains(f),
                        onSelected: (on) => setState(
                          () => on ? _filters.add(f) : _filters.remove(f),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${recipes.length} ${recipes.length == 1 ? 'receta' : 'recetas'}',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          if (recipes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                emoji: '🔍',
                title: 'No encontramos recetas',
                message: 'Prueba con otra palabra o quita algunos filtros.',
                action: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Quitar filtros'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.separated(
                itemCount: recipes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => RecipeCard(recipe: recipes[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _MealChip extends StatelessWidget {
  const _MealChip({
    this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String? emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: emoji == null || selected ? null : Text(emoji!),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
