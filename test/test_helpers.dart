import 'dart:io';

import 'package:appcocina/data/recipe_repository.dart';

/// Carga el catálogo real de recetas desde el archivo del proyecto.
RecipeRepository loadRealRepository() => RecipeRepository.fromJsonString(
  File(RecipeRepository.assetPath).readAsStringSync(),
);
