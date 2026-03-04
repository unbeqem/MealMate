import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_mate/features/ingredients/presentation/screens/ingredient_favorites_screen.dart';
import 'package:meal_mate/features/ingredients/presentation/screens/ingredient_search_screen.dart';
import 'package:meal_mate/features/ingredients/presentation/widgets/selected_today_bar.dart';

/// Main 2-tab shell for the ingredient selection feature.
///
/// Tab 0 (Search/Browse): [IngredientSearchScreen] — autocomplete search
/// with local-first matching and category browsing grid.
///
/// Tab 1 (Favorites): [IngredientFavoritesScreen] — saved ingredients
/// the user can quickly add to "I have these today".
///
/// [SelectedTodayBar] is placed OUTSIDE the [TabBarView] so it persists
/// across tab switches without rebuilding its expand/collapse state.
///
/// Route: /ingredients
class IngredientMainScreen extends ConsumerWidget {
  const IngredientMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ingredients'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search), text: 'Search'),
              Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            ],
          ),
        ),
        body: const Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  IngredientSearchScreen(), // Tab 0: Search/Browse
                  IngredientFavoritesScreen(), // Tab 1: Favorites
                ],
              ),
            ),
            SelectedTodayBar(), // Shared bar — persists across tab switches
          ],
        ),
      ),
    );
  }
}
