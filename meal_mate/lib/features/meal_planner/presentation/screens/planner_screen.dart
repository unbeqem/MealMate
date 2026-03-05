import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meal_mate/features/meal_planner/domain/meal_slot.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/meal_plan_notifier.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/template_notifier.dart';
import 'package:meal_mate/features/meal_planner/presentation/widgets/planner_grid.dart';
import 'package:meal_mate/features/meal_planner/presentation/widgets/week_ingredient_summary.dart';

/// The root screen for the weekly meal planner.
///
/// Displays a 7-day grid of breakfast/lunch/dinner slots with week navigation
/// (previous/next arrows and a date-picker label). Users can tap empty slots
/// to assign recipes and use inline icons on filled slots to replace or remove.
///
/// The overflow menu provides "Save as Template" and "Load Template" actions:
/// - Save: prompts for a name, validates the week has at least one filled slot,
///   then calls [TemplateNotifier.saveCurrentWeek].
/// - Load: navigates to [TemplateListScreen] passing the current [_weekStart].
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  /// Returns the Monday of the week containing [date].
  DateTime _mondayOf(DateTime date) {
    final daysFromMonday = (date.weekday - DateTime.monday) % 7;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime.utc(monday.year, monday.month, monday.day);
  }

  String _formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startStr = _formatDate(weekStart);
    final endStr = _formatDate(weekEnd);
    return '$startStr \u2013 $endStr';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _weekStart = _mondayOf(picked);
      });
    }
  }

  /// Shows a dialog prompting for a template name, then saves the current week.
  Future<void> _saveAsTemplate() async {
    // Check if the current week has any filled slots before prompting for name.
    final slotsAsync = ref.read(mealPlanNotifierProvider(_weekStart));
    final slots = switch (slotsAsync) {
      AsyncData(:final value) => value,
      _ => <MealSlot>[],
    };
    final hasFilledSlots = slots.any((s) => s.recipeId != null);

    if (!hasFilledSlots) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No meals in this week to save as a template.'),
          ),
        );
      }
      return;
    }

    final nameController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Template'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(
            hintText: 'e.g., Busy Week, Veggie Week',
            labelText: 'Template name',
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    final name = nameController.text.trim();
    nameController.dispose();

    if (confirmed != true || !mounted) return;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name.')),
      );
      return;
    }

    try {
      await ref.read(templateNotifierProvider.notifier).saveCurrentWeek(
            name: name,
            weekStart: _weekStart,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Template saved as '$name'")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save template: $e')),
        );
      }
    }
  }

  /// Navigates to the template list, passing the current week as a query param.
  void _openTemplateList() {
    context.push(
      '/planner/templates?week=${_weekStart.millisecondsSinceEpoch}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'save') {
                _saveAsTemplate();
              } else if (value == 'load') {
                _openTemplateList();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'save', child: Text('Save as Template')),
              PopupMenuItem(value: 'load', child: Text('Load Template')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Week navigation row ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _weekStart =
                          _weekStart.subtract(const Duration(days: 7));
                    });
                  },
                ),
                GestureDetector(
                  onTap: _openDatePicker,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _formatWeekRange(_weekStart),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _weekStart = _weekStart.add(const Duration(days: 7));
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // --- Planner grid + ingredient summary ---
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: PlannerGrid(weekStart: _weekStart),
                ),
                // --- Ingredient summary panel ---
                // Expandable panel listing all unique ingredients for the week.
                // Visible when at least one slot is filled; hidden otherwise.
                WeekIngredientSummary(weekStart: _weekStart),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
