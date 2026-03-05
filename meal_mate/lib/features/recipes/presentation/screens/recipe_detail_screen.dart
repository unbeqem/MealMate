import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_mate/features/recipes/domain/analyzed_instruction.dart';
import 'package:meal_mate/features/recipes/presentation/providers/recipe_detail_provider.dart';
import 'package:meal_mate/features/recipes/presentation/widgets/ingredient_list_tile.dart';
import 'package:meal_mate/features/recipes/presentation/widgets/serving_scaler_widget.dart';

/// Displays full recipe details: hero image, title, cook time, serving scaler,
/// scaled ingredient list, and step-by-step instructions.
///
/// Navigated to via the `/recipes/:id` route. The recipe is fetched using
/// [recipeDetailProvider] (cache-first via Drift → Spoonacular proxy).
class RecipeDetailScreen extends ConsumerWidget {
  final int recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load recipe',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(recipeDetailProvider(recipeId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (recipe) {
          final selectedServings =
              ref.watch(servingSizeProvider(recipe.servings));

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------------------
                // Hero image
                // ---------------------------------------------------------
                if (recipe.image != null && recipe.image!.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 250,
                    child: Image.network(
                      recipe.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.restaurant,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                      loadingBuilder: (_, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.restaurant,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------------------------------------------------
                      // Title
                      // ---------------------------------------------------
                      Text(
                        recipe.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // ---------------------------------------------------
                      // Metadata row: cook time + serving scaler
                      // ---------------------------------------------------
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cook time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cook time',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${recipe.readyInMinutes} min',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 32),
                          // Serving scaler
                          ServingScalerWidget(
                              originalServings: recipe.servings),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ---------------------------------------------------
                      // Ingredients section
                      // ---------------------------------------------------
                      Text(
                        'Ingredients',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (recipe.extendedIngredients.isEmpty)
                        Text(
                          'No ingredient data available.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recipe.extendedIngredients.length,
                          itemBuilder: (_, i) => IngredientListTile(
                            ingredient: recipe.extendedIngredients[i],
                            originalServings: recipe.servings,
                            selectedServings: selectedServings,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // ---------------------------------------------------
                      // Instructions section
                      // ---------------------------------------------------
                      Text(
                        'Instructions',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildInstructions(
                          context, recipe.analyzedInstructions),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInstructions(
    BuildContext context,
    List<AnalyzedInstruction> analyzedInstructions,
  ) {
    if (analyzedInstructions.isEmpty) {
      return Text(
        'No instructions available.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.grey),
      );
    }

    // Use the first instruction group (most recipes have only one).
    final firstGroup = analyzedInstructions.first;
    final steps = firstGroup.steps;

    if (steps.isEmpty) {
      return Text(
        'No instructions available.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.grey),
      );
    }

    return Column(
      children: steps.map<Widget>((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number in circle
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${step.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.step,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
