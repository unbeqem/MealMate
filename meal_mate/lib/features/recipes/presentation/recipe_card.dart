import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/recipes/domain/recipe_search_result.dart';

/// A card widget that displays a [RecipeSummary] thumbnail, title, and
/// optionally cook time. Tapping navigates to the recipe detail route by
/// default, or invokes [onTap] if provided.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
  });

  final RecipeSummary recipe;

  /// Optional tap override. When null, tapping navigates to the recipe detail
  /// screen. Provide a callback to intercept the tap (e.g. in select-for-slot
  /// mode).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/recipes/${recipe.id}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Thumbnail ---
            SizedBox(
              width: 120,
              height: 90,
              child: _buildThumbnail(recipe.image),
            ),

            // --- Content ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  recipe.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _errorWidget();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: 120,
      height: 90,
      placeholder: (_, __) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => _errorWidget(),
    );
  }

  Widget _errorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.restaurant, color: Colors.grey, size: 32),
      ),
    );
  }
}
