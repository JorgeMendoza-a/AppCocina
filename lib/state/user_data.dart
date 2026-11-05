import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingItem {
  ShoppingItem({
    required this.id,
    required this.text,
    this.category = 'Otros',
    this.checked = false,
  });

  final String id;
  final String text;
  final String category;
  bool checked;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'category': category,
    'checked': checked,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: json['id'] as String,
    text: json['text'] as String,
    category: json['category'] as String? ?? 'Otros',
    checked: json['checked'] as bool? ?? false,
  );
}

class SavedPlan {
  const SavedPlan({
    required this.goalId,
    required this.seed,
    required this.people,
  });

  final String goalId;
  final int seed;
  final int people;

  Map<String, dynamic> toJson() => {
    'goalId': goalId,
    'seed': seed,
    'people': people,
  };

  factory SavedPlan.fromJson(Map<String, dynamic> json) => SavedPlan(
    goalId: json['goalId'] as String,
    seed: json['seed'] as int,
    people: json['people'] as int? ?? 1,
  );
}

/// Todo lo que el usuario guarda en su teléfono. No se envía a ningún
/// servidor: se almacena localmente con SharedPreferences.
class UserData extends ChangeNotifier {
  UserData(this._prefs) {
    _favorites.addAll(_prefs.getStringList(_kFavorites) ?? const []);
    _pantry.addAll(_prefs.getStringList(_kPantry) ?? const []);
    final rawList = _prefs.getString(_kShopping);
    if (rawList != null) {
      try {
        _shopping.addAll(
          (jsonDecode(rawList) as List).map(
            (e) => ShoppingItem.fromJson(e as Map<String, dynamic>),
          ),
        );
      } on FormatException {
        // Datos dañados: empezamos con la lista vacía.
      }
    }
    final rawPlan = _prefs.getString(_kPlan);
    if (rawPlan != null) {
      try {
        _plan = SavedPlan.fromJson(jsonDecode(rawPlan) as Map<String, dynamic>);
      } on FormatException {
        _plan = null;
      }
    }
  }

  static const _kFavorites = 'favorites';
  static const _kPantry = 'pantry';
  static const _kShopping = 'shopping_list';
  static const _kPlan = 'saved_plan';
  static const _kDisclaimer = 'accepted_disclaimer_v1';

  static Future<UserData> load() async =>
      UserData(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;
  final Set<String> _favorites = {};
  final Set<String> _pantry = {};
  final List<ShoppingItem> _shopping = [];
  SavedPlan? _plan;

  // ---------- Aviso inicial ----------
  bool get acceptedDisclaimer => _prefs.getBool(_kDisclaimer) ?? false;

  Future<void> acceptDisclaimer() async {
    await _prefs.setBool(_kDisclaimer, true);
    notifyListeners();
  }

  // ---------- Favoritos ----------
  Set<String> get favorites => Set.unmodifiable(_favorites);
  bool isFavorite(String recipeId) => _favorites.contains(recipeId);

  void toggleFavorite(String recipeId) {
    if (!_favorites.remove(recipeId)) _favorites.add(recipeId);
    _prefs.setStringList(_kFavorites, _favorites.toList());
    notifyListeners();
  }

  // ---------- Despensa ("¿Qué cocino?") ----------
  Set<String> get pantry => Set.unmodifiable(_pantry);

  void togglePantry(String ingredientId) {
    if (!_pantry.remove(ingredientId)) _pantry.add(ingredientId);
    _prefs.setStringList(_kPantry, _pantry.toList());
    notifyListeners();
  }

  void clearPantry() {
    _pantry.clear();
    _prefs.setStringList(_kPantry, const []);
    notifyListeners();
  }

  // ---------- Lista de compras ----------
  List<ShoppingItem> get shoppingList => List.unmodifiable(_shopping);
  int get pendingShoppingCount => _shopping.where((i) => !i.checked).length;

  int _idCounter = 0;
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  /// Agrega ítems evitando duplicados exactos. Devuelve cuántos se agregaron.
  int addShoppingItems(Iterable<({String text, String category})> items) {
    final existing = _shopping.map((i) => i.text.toLowerCase()).toSet();
    var added = 0;
    for (final item in items) {
      final text = item.text.trim();
      if (text.isEmpty || existing.contains(text.toLowerCase())) continue;
      _shopping.add(
        ShoppingItem(id: _newId(), text: text, category: item.category),
      );
      existing.add(text.toLowerCase());
      added++;
    }
    _saveShopping();
    return added;
  }

  void toggleShoppingItem(String id) {
    final item = _shopping.firstWhere((i) => i.id == id);
    item.checked = !item.checked;
    _saveShopping();
  }

  void removeShoppingItem(String id) {
    _shopping.removeWhere((i) => i.id == id);
    _saveShopping();
  }

  void clearCheckedShopping() {
    _shopping.removeWhere((i) => i.checked);
    _saveShopping();
  }

  void clearShopping() {
    _shopping.clear();
    _saveShopping();
  }

  void _saveShopping() {
    _prefs.setString(
      _kShopping,
      jsonEncode(_shopping.map((i) => i.toJson()).toList()),
    );
    notifyListeners();
  }

  // ---------- Plan semanal ----------
  SavedPlan? get plan => _plan;

  void savePlan(SavedPlan plan) {
    _plan = plan;
    _prefs.setString(_kPlan, jsonEncode(plan.toJson()));
    notifyListeners();
  }

  void clearPlan() {
    _plan = null;
    _prefs.remove(_kPlan);
    notifyListeners();
  }
}
