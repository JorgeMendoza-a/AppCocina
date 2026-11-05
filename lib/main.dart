import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/recipe_repository.dart';
import 'state/user_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final results = await Future.wait([RecipeRepository.load(), UserData.load()]);
  final repository = results[0] as RecipeRepository;
  final userData = results[1] as UserData;

  runApp(
    MultiProvider(
      providers: [
        Provider<RecipeRepository>.value(value: repository),
        ChangeNotifierProvider<UserData>.value(value: userData),
      ],
      child: const AppCocina(),
    ),
  );
}
