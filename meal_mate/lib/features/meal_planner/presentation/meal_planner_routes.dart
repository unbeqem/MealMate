// Meal planner routes — registered in app/router.dart.
//
// Routes:
//   /planner              → PlannerScreen (7-day grid with week navigation)
//   /planner/templates    → TemplateListScreen (placeholder; full UI in Plan 05-04)

import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/meal_planner/presentation/screens/planner_screen.dart';
import 'package:meal_mate/features/meal_planner/presentation/screens/template_list_screen.dart';

/// GoRouter routes for the weekly meal planner feature (Phase 5).
///
/// - /planner             → PlannerScreen (week grid + navigation)
/// - /planner/templates   → TemplateListScreen (save/load templates)
final List<RouteBase> mealPlannerRoutes = [
  GoRoute(
    path: '/planner',
    builder: (_, __) => const PlannerScreen(),
    routes: [
      GoRoute(
        path: 'templates',
        builder: (_, __) => const TemplateListScreen(),
      ),
    ],
  ),
];
