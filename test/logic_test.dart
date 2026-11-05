import 'dart:io';

import 'package:appcocina/models/diet_plan.dart';
import 'package:appcocina/models/recipe.dart';
import 'package:appcocina/services/plan_generator.dart';
import 'package:appcocina/services/recipe_matcher.dart';
import 'package:appcocina/services/shopping_list_builder.dart';
import 'package:appcocina/utils/quantity_format.dart';
import 'package:appcocina/utils/text_search.dart';
import 'package:appcocina/widgets/step_illustration.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  final repo = loadRealRepository();

  group('Datos de recetas', () {
    test('hay suficientes recetas para cada comida', () {
      for (final meal in MealType.values) {
        final count = repo.recipes.where((r) => r.meals.contains(meal)).length;
        expect(count, greaterThanOrEqualTo(5), reason: meal.label);
      }
    });

    test('las fotos existen y tienen crédito', () {
      for (final r in repo.recipes.where((r) => r.image != null)) {
        expect(File(r.image!).existsSync(), isTrue, reason: r.image);
        expect(r.imageCredit, isNotNull, reason: r.id);
        expect(r.imageCredit!.license, isNotEmpty, reason: r.id);
      }
      expect(repo.recipes.where((r) => r.image != null).length, 29);
    });

    test('hay al menos 10 recetas manabas', () {
      final manabas = repo.recipes.where((r) => r.origin.contains('Manabí'));
      expect(manabas.length, greaterThanOrEqualTo(10));
    });

    test('ids únicos e ingredientes conocidos', () {
      final ids = repo.recipes.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
      final ingredientIds = repo.ingredients.map((i) => i.id).toSet();
      for (final r in repo.recipes) {
        expect(r.steps, isNotEmpty, reason: r.id);
        expect(r.servings, greaterThan(0), reason: r.id);
        for (final i in r.ingredients) {
          expect(ingredientIds, contains(i.ingredientId), reason: r.id);
        }
      }
    });

    test('las recetas sin gluten no llevan ingredientes con gluten', () {
      const gluten = {'pan', 'fideo', 'salsa_soya', 'avena', 'granola'};
      for (final r in repo.recipes.where((r) => r.isGlutenFree)) {
        for (final i in r.ingredients) {
          expect(gluten, isNot(contains(i.ingredientId)), reason: r.id);
        }
      }
    });

    test('las recetas vegetarianas no llevan carne ni mariscos', () {
      final meat = repo.ingredients
          .where((i) => i.category == 'Carnes y mariscos')
          .map((i) => i.id)
          .toSet();
      for (final r in repo.recipes.where((r) => r.isVegetarian)) {
        for (final i in r.ingredients) {
          expect(meat, isNot(contains(i.ingredientId)), reason: r.id);
        }
      }
    });
  });

  group('Formato de cantidades', () {
    test('fracciones amigables', () {
      expect(formatNumber(0.5), '1/2');
      expect(formatNumber(0.25), '1/4');
      expect(formatNumber(1.5), '1 1/2');
      expect(formatNumber(2), '2');
      expect(formatNumber(0.333), '1/3');
      expect(formatNumber(1.95), '2');
      expect(formatNumber(250), '250');
    });

    test('plurales y "al gusto"', () {
      expect(formatQuantity(2, 'taza'), '2 tazas');
      expect(formatQuantity(1, 'taza'), '1 taza');
      expect(formatQuantity(0.5, 'unidad'), '1/2 unidad');
      expect(formatQuantity(null, null), 'al gusto');
      expect(formatQuantity(300, 'g'), '300 g');
    });

    test('lista de compras convierte a kg y l', () {
      expect(formatShoppingQuantity(1500, 'g'), '1.5 kg');
      expect(formatShoppingQuantity(2000, 'ml'), '2 l');
      expect(formatShoppingQuantity(400, 'g'), '400 g');
    });
  });

  test('búsqueda ignora tildes y mayúsculas', () {
    expect(normalizeForSearch('  Brócoli  CON Piña '), 'brocoli con pina');
  });

  group('¿Qué cocino?', () {
    final matcher = RecipeMatcher(repo);

    test('sin ingredientes no hay resultados', () {
      expect(matcher.match({}), isEmpty);
    });

    test('ingredientes básicos no cuentan como requeridos', () {
      final r = repo.recipe('huevos_pericos')!;
      expect(
        matcher.requiredIngredients(r),
        unorderedEquals(['huevo', 'tomate', 'cebolla_blanca']),
      );
    });

    test('si tienes todo, la receta aparece primero y lista', () {
      final results = matcher.match({'huevo', 'tomate', 'cebolla_blanca'});
      expect(results.first.canCookNow, isTrue);
      expect(results.map((m) => m.recipe.id), contains('huevos_pericos'));
    });

    test('muestra lo que falta', () {
      final results = matcher.match({'manzana'});
      final m = results.firstWhere((m) => m.recipe.id == 'manzana_mani');
      expect(m.missing, ['mani']);
    });
  });

  group('Plan semanal', () {
    final generator = PlanGenerator(repo);

    test('cada objetivo genera 7 días completos', () {
      for (final goal in dietGoals) {
        final plan = generator.generate(goal, seed: 42);
        expect(plan.days, hasLength(7), reason: goal.id);
        for (final day in plan.days) {
          expect(
            day.meals.keys.toSet(),
            MealType.values.toSet(),
            reason: '${goal.id} ${day.name}',
          );
        }
      }
    });

    test('la misma semilla genera el mismo plan', () {
      final goal = dietGoalById('saludable');
      final a = generator.generate(goal, seed: 7);
      final b = generator.generate(goal, seed: 7);
      expect(
        a.days.map((d) => d.meals.values.map((r) => r.id).join()).toList(),
        b.days.map((d) => d.meals.values.map((r) => r.id).join()).toList(),
      );
    });

    test('los planes respetan sus etiquetas', () {
      for (final id in ['vegetariano', 'sin_gluten', 'economico']) {
        final goal = dietGoalById(id);
        final plan = generator.generate(goal, seed: 1);
        for (final r in plan.days.expand((d) => d.meals.values)) {
          expect(r.tags, containsAll(goal.requiredTags), reason: r.id);
        }
      }
    });

    test('bajar de peso: cerca de la referencia y nunca un día muy bajo', () {
      final goal = dietGoalById('bajar_peso');
      for (var seed = 0; seed < 50; seed++) {
        final plan = generator.generate(goal, seed: seed);
        expect(
          plan.averageKcal,
          inInclusiveRange(1250, goal.dailyKcalTarget * 1.1),
          reason: 'seed $seed',
        );
        for (final day in plan.days) {
          expect(
            plan.dayKcal(day),
            greaterThanOrEqualTo(1200),
            reason: 'seed $seed ${day.name}',
          );
        }
      }
    });

    test('los demás planes quedan a ±20% de su referencia', () {
      for (final goal in dietGoals.where((g) => g.id != 'bajar_peso')) {
        for (var seed = 0; seed < 50; seed++) {
          final plan = generator.generate(goal, seed: seed);
          expect(
            plan.averageKcal / goal.dailyKcalTarget,
            inInclusiveRange(0.8, 1.2),
            reason: '${goal.id} seed $seed: ${plan.averageKcal}',
          );
        }
      }
    });

    test('porciones por persona entre 1 y 1 1/2', () {
      for (final goal in dietGoals) {
        final plan = generator.generate(goal, seed: 9, people: 2);
        expect(plan.portionsPerPerson, inInclusiveRange(1, 1.5));
        expect(plan.totalPortions, plan.portionsPerPerson * 2);
      }
    });

    test('no repite receta en el mismo día', () {
      final plan = generator.generate(dietGoalById('saludable'), seed: 3);
      for (final day in plan.days) {
        final ids = day.meals.values.map((r) => r.id).toList();
        expect(ids.toSet().length, ids.length, reason: day.name);
      }
    });
  });

  group('Lista de compras', () {
    final builder = ShoppingListBuilder(repo);

    test('escala las cantidades y omite básicos', () {
      final r = repo.recipe('huevos_pericos')!; // 2 porciones, 4 huevos
      final entries = builder.build([r], people: 4);
      final huevos = entries.firstWhere((e) => e.ingredientId == 'huevo');
      expect(huevos.amount, '8 unidades');
      expect(
        entries.map((e) => e.ingredientId),
        isNot(anyOf(contains('sal'), contains('aceite'))),
      );
    });

    test(
      'suma el mismo ingrediente de varias recetas y convierte unidades',
      () {
        final encebollado = repo.recipe('encebollado')!; // 1 kg yuca, 6 porc.
        final entries = builder.build([encebollado, encebollado], people: 6);
        final yuca = entries.firstWhere((e) => e.ingredientId == 'yuca');
        expect(yuca.amount, '2 kg');
        expect(entries.where((e) => e.ingredientId == 'yuca'), hasLength(1));
      },
    );

    test('condimentos aparecen sin cantidad', () {
      final entries = builder.build([repo.recipe('encebollado')!], people: 6);
      final comino = entries.firstWhere((e) => e.ingredientId == 'comino');
      expect(comino.label, 'Comino');
    });
  });

  group('Ilustraciones de pasos', () {
    test('detecta la acción de cada paso', () {
      expect(actionForStep('Pela los verdes y córtalos').label, 'Cortar');
      expect(actionForStep('Licúa todo con la leche').label, 'Licuar');
      expect(actionForStep('Precalienta el horno a 200 °C.').label, 'Hornear');
      expect(actionForStep('Sofríe la cebolla y el ajo').label, 'Sofreír');
      expect(actionForStep('Sirve con cilantro picado').label, 'Cortar');
      expect(actionForStep('Sirve caliente').label, 'Servir');
      expect(
        actionForStep('En cada hoja pon arroz. Envuelve y amarra.').label,
        'Envolver',
      );
      expect(actionForStep('Ralla los verdes crudos').label, 'Cortar');
      expect(actionForStep('Forma bolitas y rellénalas').label, 'Mezclar');
    });

    test('todas las recetas tienen una acción para cada paso', () {
      for (final r in repo.recipes) {
        for (final step in r.steps) {
          expect(actionForStep(step.text).emoji, isNotEmpty);
        }
      }
    });

    test('encuentra los ingredientes mencionados en el paso', () {
      final r = repo.recipe('bolon_verde')!;
      final emojis = ingredientEmojisForStep(
        repo,
        r,
        'Mezcla el queso desmenuzado con la masa',
      );
      expect(emojis, ['🧀']);
    });
  });
}
