import 'package:meal_mate/features/ingredients/data/ingredient_repository_provider.dart';
import 'package:meal_mate/features/meal_planner/data/template_repository.dart';
import 'package:meal_mate/features/meal_planner/domain/plan_template.dart';
import 'package:meal_mate/features/meal_planner/presentation/providers/meal_plan_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'template_notifier.g.dart';

/// Manages the list of saved plan templates and template lifecycle operations.
@riverpod
class TemplateNotifier extends _$TemplateNotifier {
  late TemplateRepository _repository;

  @override
  Future<List<PlanTemplate>> build() async {
    final db = ref.watch(appDatabaseProvider);
    final userId = ref.watch(currentUserIdProvider);
    _repository = TemplateRepository(db);
    return _repository.getAllTemplates(userId);
  }

  /// Saves the current week as a named template.
  Future<void> saveCurrentWeek({
    required String name,
    required DateTime weekStart,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    await _repository.saveCurrentWeek(
      name: name,
      userId: userId,
      weekStart: weekStart,
    );
    ref.invalidateSelf();
  }

  /// Loads a saved template into the target week.
  Future<void> loadTemplate({
    required String templateId,
    required DateTime targetWeekStart,
    required bool replaceAll,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    await _repository.loadTemplate(
      templateId: templateId,
      userId: userId,
      targetWeekStart: targetWeekStart,
      replaceAll: replaceAll,
    );
  }

  /// Deletes a template and refreshes the list.
  Future<void> deleteTemplate(String templateId) async {
    await _repository.deleteTemplate(templateId);
    ref.invalidateSelf();
  }
}
