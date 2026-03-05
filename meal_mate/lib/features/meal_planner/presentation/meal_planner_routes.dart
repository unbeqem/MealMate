// Meal planner routes — registered in app/router.dart.
//
// Routes:
//   /planner              → PlannerScreen (7-day grid with week navigation)
//   /planner/templates    → TemplateListScreen (save/load templates)
//     ?week=<epochMs>     — optional query param for pre-selecting the week

import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/meal_planner/presentation/screens/planner_screen.dart';
import 'package:meal_mate/features/meal_planner/presentation/screens/template_list_screen.dart';

/// GoRouter routes for the weekly meal planner feature (Phase 5).
///
/// - /planner             → PlannerScreen (week grid + navigation)
/// - /planner/templates   → TemplateListScreen (save/load templates)
///   Accepts optional query param `?week=<epochMs>` so PlannerScreen can pass
///   its current weekStart and TemplateListScreen pre-fills the load dialog.
final List<RouteBase> mealPlannerRoutes = [
  GoRoute(
    path: '/planner',
    builder: (_, __) => const PlannerScreen(),
    routes: [
      GoRoute(
        path: 'templates',
        builder: (context, state) {
          final weekParam = state.uri.queryParameters['week'];
          final DateTime weekStart;
          if (weekParam != null) {
            final epochMs = int.tryParse(weekParam);
            weekStart = epochMs != null
                ? DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true)
                : _currentMonday();
          } else {
            weekStart = _currentMonday();
          }
          return TemplateListScreen(weekStart: weekStart);
        },
      ),
    ],
  ),
];

/// Returns the Monday of the current week at UTC midnight.
DateTime _currentMonday() {
  final now = DateTime.now();
  final daysFromMonday = (now.weekday - DateTime.monday) % 7;
  final monday = now.subtract(Duration(days: daysFromMonday));
  return DateTime.utc(monday.year, monday.month, monday.day);
}
