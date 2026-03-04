// Ingredient routes — registered separately from the main auth router.
//
// This file exists so ingredient route builders can be imported cleanly.
// The actual GoRouter lives in lib/app/router.dart.
//
// Re-export pattern: import this file from router.dart and spread the routes.
//
// Usage in router.dart:
//   import '../core/router/app_router.dart';
//   ...
//   routes: [
//     ...ingredientRoutes,
//     ...existingRoutes,
//   ]

import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/ingredients/presentation/screens/ingredient_category_screen.dart';
import 'package:meal_mate/features/ingredients/presentation/screens/ingredient_main_screen.dart';

/// GoRouter routes for the ingredient selection feature (Phase 3).
///
/// - /ingredients                  → IngredientMainScreen (2-tab shell)
/// - /ingredients/category/:name   → IngredientCategoryScreen
final List<RouteBase> ingredientRoutes = [
  GoRoute(
    path: '/ingredients',
    builder: (_, __) => const IngredientMainScreen(),
    routes: [
      GoRoute(
        path: 'category/:name',
        builder: (_, state) => IngredientCategoryScreen(
          categoryName: state.pathParameters['name'] ?? '',
        ),
      ),
    ],
  ),
];
