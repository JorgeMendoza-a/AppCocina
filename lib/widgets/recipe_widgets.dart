import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../models/recipe.dart';
import '../screens/recipe_detail_screen.dart';
import '../state/user_data.dart';

/// Color pastel de fondo para cada receta, según la comida principal.
Color recipeTint(BuildContext context, Recipe recipe) =>
    switch (recipe.meals.first) {
      MealType.desayuno => AppColors.butter,
      MealType.almuerzo => AppColors.peach,
      MealType.cena => AppColors.lavender,
      MealType.snack => AppColors.mint,
    };

void openRecipe(BuildContext context, Recipe recipe) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)));
}

class RecipeEmoji extends StatelessWidget {
  const RecipeEmoji({super.key, required this.recipe, this.size = 64});

  final Recipe recipe;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    if (recipe.image != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          recipe.image!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: recipeTint(context, recipe),
        borderRadius: radius,
      ),
      child: Text(recipe.emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final isFav = context.select<UserData, bool>((u) => u.isFavorite(recipeId));
    return IconButton(
      tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
      onPressed: () => context.read<UserData>().toggleFavorite(recipeId),
      icon: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        color: isFav ? Theme.of(context).colorScheme.primary : null,
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Tarjeta de receta para listas.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    this.subtitle,
    this.trailing,
  });

  final Recipe recipe;

  /// Contenido extra bajo el título (por ejemplo, "Te falta: ajo").
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openRecipe(context, recipe),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              RecipeEmoji(recipe: recipe),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        InfoPill(
                          icon: Icons.schedule,
                          label: '${recipe.minutes} min',
                        ),
                        InfoPill(
                          icon: Icons.local_fire_department_outlined,
                          label: '${recipe.nutrition.kcal} kcal',
                        ),
                        if (recipe.isVegetarian)
                          const InfoPill(
                            icon: Icons.eco_outlined,
                            label: 'Veggie',
                          ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      subtitle!,
                    ],
                  ],
                ),
              ),
              trailing ?? FavoriteButton(recipeId: recipe.id),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje centrado para listas vacías.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.message,
    this.action,
  });

  final String emoji;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              title,
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
