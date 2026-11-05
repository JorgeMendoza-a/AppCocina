import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/user_data.dart';
import 'favorites_screen.dart';
import 'pantry_screen.dart';
import 'plan_screen.dart';
import 'recipes_screen.dart';
import 'shopping_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    RecipesScreen(),
    PantryScreen(),
    PlanScreen(),
    ShoppingListScreen(),
    FavoritesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDisclaimer());
  }

  Future<void> _maybeShowDisclaimer() async {
    final userData = context.read<UserData>();
    if (userData.acceptedDisclaimer || !mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Text('👩‍🍳', style: TextStyle(fontSize: 40)),
        title: const Text('¡Te damos la bienvenida!'),
        content: const Text(
          'Aquí encontrarás recetas, ideas con lo que tienes en casa y menús '
          'semanales.\n\n'
          'Los planes de alimentación y las calorías son orientativos y no '
          'reemplazan la consulta con un médico o nutricionista, sobre todo '
          'si tienes alguna condición de salud, alergias o estás embarazada.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              userData.acceptDisclaimer();
              Navigator.of(context).pop();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.select<UserData, int>(
      (u) => u.pendingShoppingCount,
    );
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Recetas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: '¿Qué cocino?',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Mi plan',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Compras',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
        ],
      ),
    );
  }
}
