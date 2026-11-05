import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/user_data.dart';
import '../widgets/recipe_widgets.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<UserData>().addShoppingItems([
      (text: text, category: 'Agregados por ti'),
    ]);
    _controller.clear();
  }

  Future<void> _confirmClearAll() async {
    final userData = context.read<UserData>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Vaciar la lista?'),
        content: const Text('Se borrarán todos los productos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (ok == true) userData.clearShopping();
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserData>();
    final items = userData.shoppingList;
    final pending = items.where((i) => !i.checked).toList();
    final done = items.where((i) => i.checked).toList();

    final grouped = <String, List<ShoppingItem>>{};
    for (final item in pending) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de compras'),
        actions: [
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'checked') userData.clearCheckedShopping();
                if (v == 'all') _confirmClearAll();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'checked',
                  enabled: done.isNotEmpty,
                  child: const Text('Borrar lo comprado'),
                ),
                const PopupMenuItem(value: 'all', child: Text('Vaciar lista')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _add(),
              decoration: InputDecoration(
                hintText: 'Agregar producto',
                prefixIcon: const Icon(Icons.add),
                suffixIcon: IconButton(
                  tooltip: 'Agregar',
                  icon: const Icon(Icons.send),
                  onPressed: _add,
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    emoji: '🛒',
                    title: 'Tu lista está vacía',
                    message:
                        'Agrega productos aquí, desde una receta o desde tu '
                        'plan semanal.',
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      for (final entry in grouped.entries) ...[
                        _Header(entry.key),
                        for (final item in entry.value) _ItemTile(item: item),
                      ],
                      if (done.isNotEmpty) ...[
                        _Header('Comprado (${done.length})'),
                        for (final item in done) _ItemTile(item: item),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});
  final ShoppingItem item;

  @override
  Widget build(BuildContext context) {
    final userData = context.read<UserData>();
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => userData.removeShoppingItem(item.id),
      child: CheckboxListTile(
        value: item.checked,
        onChanged: (_) => userData.toggleShoppingItem(item.id),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          item.text,
          style: item.checked
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: scheme.onSurfaceVariant,
                )
              : null,
        ),
      ),
    );
  }
}
