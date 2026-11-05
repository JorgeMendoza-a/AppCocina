import 'package:appcocina/app.dart';
import 'package:appcocina/data/recipe_repository.dart';
import 'package:appcocina/state/user_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

Future<UserData> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final userData = UserData(await SharedPreferences.getInstance());
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<RecipeRepository>.value(value: loadRealRepository()),
        ChangeNotifierProvider<UserData>.value(value: userData),
      ],
      child: const AppCocina(),
    ),
  );
  await tester.pumpAndSettle();
  return userData;
}

void main() {
  testWidgets('muestra el aviso la primera vez y luego no', (tester) async {
    final userData = await _pumpApp(tester);
    expect(find.text('¡Te damos la bienvenida!'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(userData.acceptedDisclaimer, isTrue);
    expect(find.text('¡Te damos la bienvenida!'), findsNothing);
  });

  testWidgets('buscar, abrir una receta y guardarla en favoritos', (
    tester,
  ) async {
    final userData = await _pumpApp(
      tester,
      prefs: {'accepted_disclaimer_v1': true},
    );

    await tester.enterText(find.byType(TextField).first, 'encebollado');
    await tester.pumpAndSettle();
    expect(find.text('1 receta'), findsOneWidget);

    await tester.tap(find.text('Encebollado'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Albacora fresca'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ingredientes'), findsOneWidget);
    expect(find.text('Albacora fresca'), findsOneWidget);

    await tester.tap(find.byTooltip('Agregar a favoritos'));
    await tester.pump();
    expect(userData.isFavorite('encebollado'), isTrue);

    // El encebollado es para 6; subimos a 8 porciones.
    await tester.ensureVisible(find.byTooltip('Más porciones'));
    await tester.pumpAndSettle();
    expect(find.text('1 kg'), findsNWidgets(2)); // albacora y yuca para 6
    await tester.tap(find.byTooltip('Más porciones'));
    await tester.pump();
    await tester.tap(find.byTooltip('Más porciones'));
    await tester.pump();
    expect(find.text('8 porciones'), findsOneWidget);
    expect(find.text('1 1/3 kg'), findsNWidgets(2)); // para 8
  });

  testWidgets('crear un plan semanal', (tester) async {
    final userData = await _pumpApp(
      tester,
      prefs: {'accepted_disclaimer_v1': true},
    );
    await tester.tap(find.text('Mi plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vegetariano'));
    await tester.scrollUntilVisible(
      find.text('Crear mi plan'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Crear mi plan'));
    await tester.pumpAndSettle();
    expect(userData.plan?.goalId, 'vegetariano');
    expect(find.text('Lunes'), findsOneWidget);

    // Generar la lista de compras de toda la semana.
    await tester.tap(find.text('Lista de compras de la semana'));
    await tester.pump();
    expect(userData.shoppingList, isNotEmpty);
    expect(
      userData.shoppingList.map((i) => i.text).join(),
      isNot(contains('Sal')),
    );
  });
}
