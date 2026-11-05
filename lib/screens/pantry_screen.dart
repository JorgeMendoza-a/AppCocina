import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/recipe_repository.dart';
import '../models/recipe.dart';
import '../services/recipe_matcher.dart';
import '../state/user_data.dart';
import '../utils/text_search.dart';
import '../widgets/recipe_widgets.dart';

/// "¿Qué cocino?": el usuario marca lo que tiene y ve qué puede preparar.
class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RecipeRepository>();
    final userData = context.watch<UserData>();
    final pantry = userData.pantry;
    final matches = RecipeMatcher(repo).match(pantry);
    final query = normalizeForSearch(_query);
    final scheme = Theme.of(context).colorScheme;

    final groups = <String, List<Ingredient>>{};
    repo.selectableByCategory.forEach((category, items) {
      final visible = query.isEmpty
          ? items
          : items
                .where((i) => normalizeForSearch(i.name).contains(query))
                .toList();
      if (visible.isNotEmpty) groups[category] = visible;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Qué cocino?'),
        actions: [
          if (pantry.isNotEmpty)
            TextButton(
              onPressed: userData.clearPantry,
              child: const Text('Limpiar'),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marca lo que tienes en casa y te decimos qué puedes '
                    'preparar. La sal, el aceite y el agua ya se cuentan.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar ingrediente',
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
          for (final entry in groups.entries) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final ingredient in entry.value)
                      FilterChip(
                        avatar: Text(ingredient.emoji),
                        label: Text(ingredient.name),
                        selected: pantry.contains(ingredient.id),
                        showCheckmark: false,
                        onSelected: (_) => userData.togglePantry(ingredient.id),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (groups.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                emoji: '🥕',
                title: 'Sin resultados',
                message: 'No tenemos ese ingrediente todavía.',
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
      bottomSheet: pantry.isEmpty
          ? null
          : _ResultsBar(selected: pantry.length, matches: matches),
    );
  }
}

class _ResultsBar extends StatelessWidget {
  const _ResultsBar({required this.selected, required this.matches});

  final int selected;
  final List<RecipeMatch> matches;

  @override
  Widget build(BuildContext context) {
    final ready = matches.where((m) => m.canCookNow).length;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selected ${selected == 1 ? 'ingrediente' : 'ingredientes'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      ready > 0
                          ? '$ready listas para cocinar ya'
                          : '${matches.length} ideas con lo que tienes',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: matches.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PantryResultsScreen(),
                        ),
                      ),
                child: Text('Ver ${matches.length} recetas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PantryResultsScreen extends StatelessWidget {
  const PantryResultsScreen({super.key});

  void _addMissing(BuildContext context, RecipeMatch match) {
    final repo = context.read<RecipeRepository>();
    final added = context.read<UserData>().addShoppingItems(
      match.missing.map(
        (id) => (
          text: repo.ingredient(id).name,
          category: repo.ingredient(id).category,
        ),
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'Ya estaban en tu lista de compras'
                : 'Se agregaron $added ingredientes a tu lista',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RecipeRepository>();
    final pantry = context.watch<UserData>().pantry;
    final matches = RecipeMatcher(repo).match(pantry);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Puedes preparar')),
      body: matches.isEmpty
          ? const EmptyState(
              emoji: '🤔',
              title: 'Aún no hay ideas',
              message: 'Marca algunos ingredientes más.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final match = matches[i];
                return RecipeCard(
                  recipe: match.recipe,
                  subtitle: match.canCookNow
                      ? Text(
                          '✅ ¡Tienes todo!',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Text(
                          'Te falta: ${match.missing.map((id) => repo.ingredient(id).name.toLowerCase()).join(', ')}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                  trailing: match.canCookNow
                      ? null
                      : IconButton(
                          tooltip: 'Agregar lo que falta a la lista',
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () => _addMissing(context, match),
                        ),
                );
              },
            ),
    );
  }
}
