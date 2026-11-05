import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/recipe_repository.dart';
import '../widgets/recipe_widgets.dart';

/// Autores y licencias de las fotos de los platos (Wikimedia Commons).
/// Las licencias CC BY y CC BY-SA exigen mostrar este crédito.
class PhotoCreditsScreen extends StatelessWidget {
  const PhotoCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipes = context
        .read<RecipeRepository>()
        .recipes
        .where((r) => r.imageCredit != null)
        .toList();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Créditos de fotos')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: recipes.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Las fotos de los platos provienen de Wikimedia Commons y se '
                'usan según sus licencias Creative Commons o de dominio '
                'público. Algunas fotos son de preparaciones similares y '
                'pueden variar respecto a la receta.',
                style: TextStyle(color: muted),
              ),
            );
          }
          final recipe = recipes[i - 1];
          final credit = recipe.imageCredit!;
          return Card(
            child: ListTile(
              leading: RecipeEmoji(recipe: recipe, size: 48),
              title: Text(recipe.name),
              subtitle: Text(
                '${credit.author} · ${credit.license}\n${credit.source}',
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
