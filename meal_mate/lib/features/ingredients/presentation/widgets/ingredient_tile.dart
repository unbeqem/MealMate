import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable list tile for displaying an ingredient with dietary badges,
/// favorite, and "I have this today" selection actions.
///
/// Used across search results, category browsing, and the favorites screen.
///
/// Dietary badges are shown as compact chips:
/// - "vegan"       → green "V" chip
/// - "vegetarian"  → light green "VG" chip
/// - "gluten-free" → amber "GF" chip
/// - "dairy-free"  → blue "DF" chip
class IngredientTile extends StatefulWidget {
  final String name;
  final String? category;
  final List<String> dietaryFlags;
  final bool isFavorite;
  final bool isSelected;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onSelectTap;
  final VoidCallback? onTap;

  const IngredientTile({
    super.key,
    required this.name,
    this.category,
    this.dietaryFlags = const [],
    this.isFavorite = false,
    this.isSelected = false,
    this.onFavoriteTap,
    this.onSelectTap,
    this.onTap,
  });

  @override
  State<IngredientTile> createState() => _IngredientTileState();
}

class _IngredientTileState extends State<IngredientTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _handleFavoriteTap() async {
    await HapticFeedback.lightImpact();
    await _heartController.forward();
    await _heartController.reverse();
    widget.onFavoriteTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasBadges = widget.dietaryFlags.isNotEmpty;

    return ListTile(
      onTap: widget.onTap,
      title: Text(widget.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.category != null)
            Text(
              widget.category!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          if (hasBadges) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: widget.dietaryFlags
                  .map((flag) => _DietaryBadge(flag: flag))
                  .toList(),
            ),
          ],
        ],
      ),
      isThreeLine: hasBadges,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "I have this today" toggle
          IconButton(
            icon: Icon(
              widget.isSelected
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip:
                widget.isSelected ? 'Remove from today' : 'I have this today',
            onPressed: widget.onSelectTap,
          ),
          // Animated favorite heart toggle
          ScaleTransition(
            scale: _heartScale,
            child: IconButton(
              icon: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: widget.isFavorite ? Colors.red : null,
              ),
              tooltip: widget.isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              onPressed: widget.onFavoriteTap != null ? _handleFavoriteTap : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact dietary badge chip shown within an [IngredientTile].
class _DietaryBadge extends StatelessWidget {
  final String flag;

  const _DietaryBadge({required this.flag});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (flag) {
      'vegan' => ('V', const Color(0xFF4CAF50)),
      'vegetarian' => ('VG', const Color(0xFF8BC34A)),
      'gluten-free' => ('GF', const Color(0xFFFFC107)),
      'dairy-free' => ('DF', const Color(0xFF2196F3)),
      _ => (flag.substring(0, 2).toUpperCase(), Colors.grey),
    };

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
