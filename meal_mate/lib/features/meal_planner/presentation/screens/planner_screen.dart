import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_mate/features/meal_planner/presentation/widgets/planner_grid.dart';

/// The root screen for the weekly meal planner.
///
/// Displays a 7-day grid of breakfast/lunch/dinner slots with week navigation
/// (previous/next arrows and a date-picker label). Users can tap empty slots
/// to assign recipes and use inline icons on filled slots to replace or remove.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
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

          // --- Planner grid ---
          Expanded(
            child: PlannerGrid(weekStart: _weekStart),
          ),
        ],
      ),
    );
  }
}
