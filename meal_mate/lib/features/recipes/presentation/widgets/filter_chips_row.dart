import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_mate/features/recipes/presentation/providers/recipe_search_provider.dart';

/// Hard-coded cuisine list from Spoonacular docs.
const List<String> _kCuisines = [
  'Italian',
  'Mexican',
  'Chinese',
  'Indian',
  'Japanese',
  'Mediterranean',
  'American',
  'Thai',
];

/// Cook-time chips mapped to maxReadyTime values (in minutes).
const List<(String label, int minutes)> _kCookTimes = [
  ('Under 15 min', 15),
  ('Under 30 min', 30),
  ('Under 60 min', 60),
];

/// Horizontal scrollable row of FilterChip widgets for cuisine, cook time, and
/// ingredient mode. Connected to [RecipeFilterStateNotifier] via Riverpod.
class FilterChipsRow extends ConsumerWidget {
  const FilterChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(recipeFilterStateProvider);
    final notifier = ref.read(recipeFilterStateProvider.notifier);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        spacing: 8,
        children: [
          // --- "Use my ingredients" toggle chip ---
          ChoiceChip(
            label: const Text('Use my ingredients'),
            selected: filterState.isIngredientMode,
            onSelected: (_) => notifier.toggleIngredientMode(),
            selectedColor: theme.colorScheme.primaryContainer,
          ),

          // --- Cuisine filter chips ---
          for (final cuisine in _kCuisines)
            FilterChip(
              label: Text(cuisine),
              selected: filterState.cuisine == cuisine,
              onSelected: (selected) =>
                  notifier.setCuisine(selected ? cuisine : null),
            ),

          // --- Cook time filter chips ---
          for (final (label, minutes) in _kCookTimes)
            FilterChip(
              label: Text(label),
              selected: filterState.maxReadyTime == minutes,
              onSelected: (selected) =>
                  notifier.setMaxReadyTime(selected ? minutes : null),
            ),
        ],
      ),
    );
  }
}
