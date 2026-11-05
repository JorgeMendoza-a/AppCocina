import '../data/recipe_repository.dart';
import '../models/recipe.dart';
import '../utils/quantity_format.dart';

/// Un ingrediente calculado para la lista de compras.
class ShoppingEntry {
  const ShoppingEntry({
    required this.ingredientId,
    required this.name,
    required this.category,
    required this.amount,
  });

  final String ingredientId;
  final String name;
  final String category;

  /// Texto de la cantidad, por ejemplo "1.5 kg + 2 unidades". Vacío si la
  /// cantidad no es relevante (condimentos, "al gusto").
  final String amount;

  String get label => amount.isEmpty ? name : '$name — $amount';
}

/// Unidades tan pequeñas que no tiene sentido sumarlas en la lista.
const _negligibleUnits = {'cda', 'cdta', 'pizca'};

class ShoppingListBuilder {
  const ShoppingListBuilder(this.repository);

  final RecipeRepository repository;

  /// Suma los ingredientes de varias recetas, escalando cada una a
  /// [people] porciones. Omite ingredientes básicos (sal, aceite, agua).
  List<ShoppingEntry> build(Iterable<Recipe> recipes, {required num people}) {
    final totals = <String, Map<String, double>>{};
    final order = <String>[];
    for (final recipe in recipes) {
      final factor = people / recipe.servings;
      for (final item in recipe.ingredients) {
        final ingredient = repository.ingredient(item.ingredientId);
        if (ingredient.basic) continue;
        if (!totals.containsKey(ingredient.id)) {
          totals[ingredient.id] = {};
          order.add(ingredient.id);
        }
        final qty = item.quantity;
        final unit = item.unit;
        if (qty == null || unit == null || _negligibleUnits.contains(unit)) {
          continue;
        }
        final (baseQty, baseUnit) = normalizeUnit(qty * factor, unit);
        final byUnit = totals[ingredient.id]!;
        byUnit[baseUnit] = (byUnit[baseUnit] ?? 0) + baseQty;
      }
    }

    final entries = order.map((id) {
      final ingredient = repository.ingredient(id);
      final amount = totals[id]!.entries
          .map((e) => formatShoppingQuantity(_roundUp(e.value, e.key), e.key))
          .join(' + ');
      return ShoppingEntry(
        ingredientId: id,
        name: ingredient.name,
        category: ingredient.category,
        amount: amount,
      );
    }).toList();

    final categoryOrder = <String>[];
    for (final i in repository.ingredients) {
      if (!categoryOrder.contains(i.category)) categoryOrder.add(i.category);
    }
    entries.sort(
      (a, b) => categoryOrder
          .indexOf(a.category)
          .compareTo(categoryOrder.indexOf(b.category)),
    );
    return entries;
  }

  /// En la tienda se compran unidades enteras: 2.3 tomates -> 3 tomates.
  double _roundUp(double value, String unit) {
    if (unit == 'g' || unit == 'ml') return (value / 50).ceil() * 50;
    if (unit == 'taza') return (value * 4).ceil() / 4;
    return value.ceilToDouble();
  }
}
