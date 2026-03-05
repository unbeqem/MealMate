import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_mate/features/meal_planner/domain/plan_template.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/template_notifier.dart';

/// Screen that displays all saved meal plan templates.
///
/// Each template card shows:
/// - Template name and creation date
/// - A 7-dot density preview (filled = at least one meal that day)
/// - Load action: picks target week, then replace-all vs fill-empty choice
/// - Delete action: confirmation dialog before removal
///
/// [weekStart] is passed from PlannerScreen so the load dialog can
/// pre-select the currently viewed week.
class TemplateListScreen extends ConsumerWidget {
  final DateTime weekStart;

  const TemplateListScreen({super.key, required this.weekStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(templateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meal Plan Templates')),
      body: templateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load templates: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(templateProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  const Text(
                    'No templates saved yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Save your current week from the planner\nto create a template',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return _TemplateCard(
                template: template,
                weekStart: weekStart,
              );
            },
          );
        },
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final PlanTemplate template;
  final DateTime weekStart;

  const _TemplateCard({required this.template, required this.weekStart});

  /// Returns the set of day-of-week strings that have at least one recipe.
  Set<String> _filledDays() {
    return template.slots
        .where((s) => s.recipeId != null)
        .map((s) => s.dayOfWeek)
        .toSet();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filledDays = _filledDays();
    // Ordered Mon-Sun display
    const dayOrder = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_formatDate(template.createdAt)),
            const SizedBox(height: 8),
            // Day-density preview dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: dayOrder.map((day) {
                final filled = filledDays.contains(day);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Load template',
              onPressed: () => _showLoadDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete template',
              onPressed: () => _showDeleteDialog(context, ref),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _showLoadDialog(BuildContext context, WidgetRef ref) async {
    // Step 1: pick target week
    final targetWeek = await showDatePicker(
      context: context,
      initialDate: weekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Load into which week? (any day of that week)',
    );
    if (targetWeek == null || !context.mounted) return;

    final normalised = _mondayOf(targetWeek);

    // Step 2: choose replace-all vs fill-empty
    if (!context.mounted) return;
    final replaceAll = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load mode'),
        content: const Text('How should the template be applied?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Fill empty slots only'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Replace all meals'),
          ),
        ],
      ),
    );
    if (replaceAll == null || !context.mounted) return;

    try {
      await ref.read(templateProvider.notifier).loadTemplate(
            templateId: template.id,
            targetWeekStart: normalised,
            replaceAll: replaceAll,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template loaded')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load template: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete template'),
        content: Text(
            "Delete template '${template.name}'? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(templateProvider.notifier)
          .deleteTemplate(template.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete template: $e')),
        );
      }
    }
  }

  /// Returns the Monday of the week containing [date].
  DateTime _mondayOf(DateTime date) {
    final daysFromMonday = (date.weekday - DateTime.monday) % 7;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return DateTime.utc(monday.year, monday.month, monday.day);
  }
}
