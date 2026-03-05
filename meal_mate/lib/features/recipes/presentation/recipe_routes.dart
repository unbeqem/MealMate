// Recipe routes — registered alongside ingredient routes in app/router.dart.
//
// Routes:
//   /recipes          → RecipeBrowseScreen
//   /recipes/:id      → RecipeDetailScreen (serving scaler + ingredients + instructions)

import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/recipes/presentation/recipe_browse_screen.dart';
import 'package:meal_mate/features/recipes/presentation/screens/recipe_detail_screen.dart';

/// GoRouter routes for the recipe discovery feature (Phase 4).
///
/// - /recipes         → RecipeBrowseScreen (search + filter + ingredient mode)
/// - /recipes/:id     → RecipeDetailScreen (full detail with serving scaler)
final List<RouteBase> recipeRoutes = [
  GoRoute(
    path: '/recipes',
    builder: (_, __) => const RecipeBrowseScreen(),
    routes: [
      GoRoute(
        path: ':id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RecipeDetailScreen(recipeId: id);
        },
      ),
    ],
  ),
];
