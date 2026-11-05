import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/recipe_repository.dart';
import '../models/recipe.dart';
import '../state/user_data.dart';
import '../widgets/recipe_widgets.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<RecipeRepository>();
    final favorites = context.watch<UserData>().favorites;
    final recipes = favorites.map(repo.recipe).whereType<Recipe>().toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: recipes.isEmpty
          ? const EmptyState(
              emoji: '❤️',
              title: 'Aún no tienes favoritos',
              message:
                  'Toca el corazón en cualquier receta para guardarla aquí.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: recipes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => RecipeCard(recipe: recipes[i]),
            ),
    );
  }
}
