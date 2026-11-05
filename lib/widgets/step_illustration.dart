import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../data/recipe_repository.dart';
import '../models/recipe.dart';
import '../utils/text_search.dart';

/// Tipo de acción de un paso, detectada por palabras clave del texto.
class StepAction {
  const StepAction(this.emoji, this.label, this.color);

  final String emoji;
  final String label;
  final Color color;
}

const _actions = <(List<String>, StepAction)>[
  (
    ['envuelve', 'hojas de platano', 'hoja de platano'],
    StepAction('🍃', 'Envolver', AppColors.mint),
  ),
  (['licua', 'licuadora'], StepAction('🥤', 'Licuar', AppColors.lavender)),
  (
    ['horno', 'hornea', 'asa los'],
    StepAction('🔥', 'Hornear', AppColors.peach),
  ),
  (
    ['corta', 'pica', 'pela', 'rodajas', 'en cubos', 'ralla ', 'rallala'],
    StepAction('🔪', 'Cortar', AppColors.mint),
  ),
  (
    ['refrigera', 'hielo', 'frio'],
    StepAction('🧊', 'Enfriar', AppColors.lavender),
  ),
  (
    ['sofrie', 'refrito', 'frie', 'dora', 'saltea', 'plancha', 'sarten'],
    StepAction('🍳', 'Sofreír', AppColors.butter),
  ),
  (
    ['hierv', 'cocina', 'caldo', 'olla', 'agua'],
    StepAction('🍲', 'Cocinar', AppColors.peach),
  ),
  (
    [
      'bate',
      'mezcla',
      'maja',
      'aplasta',
      'adoba',
      'unta',
      'arma',
      'rellena',
      'forma',
      'amasa',
    ],
    StepAction('🥣', 'Mezclar', AppColors.butter),
  ),
  (
    ['sirve', 'decora', 'acompana', 'termina'],
    StepAction('🍽️', 'Servir', AppColors.mint),
  ),
];

const _defaultAction = StepAction('👩‍🍳', 'Preparar', AppColors.peach);

StepAction actionForStep(String text) {
  final normalized = normalizeForSearch(text);
  for (final (keywords, action) in _actions) {
    if (keywords.any(normalized.contains)) return action;
  }
  return _defaultAction;
}

/// Palabras para detectar cada ingrediente dentro del texto de un paso.
List<String> _keywordsFor(Ingredient ingredient) {
  final name = normalizeForSearch(ingredient.name);
  final first = name.split(RegExp(r'[ (]')).first;
  final words = <String>{first, ingredient.id.split('_').first};
  if (ingredient.id == 'verde') words.add('verde');
  if (ingredient.id == 'maduro') words.add('maduro');
  if (ingredient.id == 'pechuga' || ingredient.id == 'pollo') {
    words.add('pollo');
  }
  if (ingredient.id == 'albacora') words.add('pescado');
  return words.where((w) => w.length >= 3).toList();
}

/// Emojis de los ingredientes de la receta mencionados en el paso.
List<String> ingredientEmojisForStep(
  RecipeRepository repo,
  Recipe recipe,
  String text,
) {
  final normalized = normalizeForSearch(text);
  final emojis = <String>[];
  for (final item in recipe.ingredients) {
    final ingredient = repo.ingredient(item.ingredientId);
    if (ingredient.basic) continue;
    final found = _keywordsFor(ingredient).any((k) {
      final stem = k.endsWith('s') ? k.substring(0, k.length - 1) : k;
      return normalized.contains(stem);
    });
    if (found && !emojis.contains(ingredient.emoji)) {
      emojis.add(ingredient.emoji);
    }
    if (emojis.length == 4) break;
  }
  return emojis;
}

/// Imagen de un paso: la foto si existe, si no una ilustración con la acción
/// y los ingredientes que se usan en ese paso.
class StepIllustration extends StatelessWidget {
  const StepIllustration({
    super.key,
    required this.recipe,
    required this.step,
    this.compact = false,
  });

  final Recipe recipe;
  final RecipeStep step;

  /// Versión pequeña y cuadrada para listas.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 14 : 24);
    if (step.image != null) {
      return ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: compact ? 1 : 16 / 10,
          child: Image.asset(step.image!, fit: BoxFit.cover),
        ),
      );
    }

    final repo = context.read<RecipeRepository>();
    final action = actionForStep(step.text);
    final emojis = ingredientEmojisForStep(repo, recipe, step.text);

    if (compact) {
      return Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: action.color, borderRadius: radius),
        child: Text(action.emoji, style: const TextStyle(fontSize: 28)),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          color: action.color,
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            // Ingredientes del paso alrededor de la acción.
            for (var i = 0; i < emojis.length; i++)
              Align(
                alignment: const [
                  Alignment(-0.7, -0.55),
                  Alignment(0.72, -0.5),
                  Alignment(-0.65, 0.6),
                  Alignment(0.7, 0.62),
                ][i],
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  child: Text(emojis[i], style: const TextStyle(fontSize: 34)),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      action.emoji,
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      action.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onButton,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
