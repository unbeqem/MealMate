import 'package:drift/drift.dart';
import 'package:meal_mate/core/database/app_database.dart';
import 'package:meal_mate/features/meal_planner/data/meal_plan_repository.dart';
import 'package:meal_mate/features/meal_planner/domain/meal_slot.dart';
import 'package:meal_mate/features/meal_planner/domain/plan_template.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Repository for template save/load/list/delete operations.
class TemplateRepository {
  final AppDatabase _db;

  TemplateRepository(this._db);

  /// Saves the current week's filled slots as a named template.
  ///
  /// Returns the new template's UUID.
  Future<String> saveCurrentWeek({
    required String name,
    required String userId,
    required DateTime weekStart,
  }) async {
    final repo = MealPlanRepository(_db);
    final filledSlots = await repo.getFilledSlots(userId, weekStart);
    final templateId = _uuid.v4();

    await _db.transaction(() async {
      // Insert the template header row
      await _db.into(_db.mealPlanTemplates).insert(
        MealPlanTemplatesCompanion.insert(
          id: Value(templateId),
          userId: userId,
          name: name,
        ),
      );

      // Insert a slot row for each filled slot
      for (final slot in filledSlots) {
        await _db.into(_db.mealPlanTemplateSlots).insert(
          MealPlanTemplateSlotsCompanion.insert(
            templateId: templateId,
            dayOfWeek: slot.dayOfWeek,
            mealType: slot.mealType,
            recipeId: Value(slot.recipeId),
            recipeTitle: Value(slot.recipeTitle),
            recipeImage: Value(slot.recipeImage),
          ),
        );
      }
    });

    return templateId;
  }

  /// Loads a saved template into the target week's meal plan.
  ///
  /// If [replaceAll] is true, all existing slots for the target week are
  /// deleted first. Otherwise, only slots whose (dayOfWeek, mealType) position
  /// is occupied by the template overwrite existing slots.
  Future<void> loadTemplate({
    required String templateId,
    required String userId,
    required DateTime targetWeekStart,
    required bool replaceAll,
  }) async {
    final weekStartNormalised = DateTime.utc(
      targetWeekStart.year,
      targetWeekStart.month,
      targetWeekStart.day,
    );

    // Fetch template slots first (outside transaction is fine — read-only)
    final templateSlots = await (_db.select(_db.mealPlanTemplateSlots)
          ..where((s) => s.templateId.equals(templateId)))
        .get();

    await _db.transaction(() async {
      if (replaceAll) {
        // Delete all existing slots for the target week
        await (_db.delete(_db.mealPlanSlots)
              ..where(
                (s) =>
                    s.userId.equals(userId) &
                    s.weekStart.equals(weekStartNormalised),
              ))
            .go();
      }

      for (final ts in templateSlots) {
        if (ts.recipeId == null) continue;

        // Upsert — handles both fresh inserts and overwrite of existing slots
        await _db.into(_db.mealPlanSlots).insertOnConflictUpdate(
          MealPlanSlotsCompanion.insert(
            id: Value(_uuid.v4()),
            userId: userId,
            dayOfWeek: ts.dayOfWeek,
            mealType: ts.mealType,
            weekStart: weekStartNormalised,
            recipeId: Value(ts.recipeId),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  /// Returns all templates for a given user, with their slots populated.
  Future<List<PlanTemplate>> getAllTemplates(String userId) async {
    final templates = await (_db.select(_db.mealPlanTemplates)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    final result = <PlanTemplate>[];
    for (final template in templates) {
      final slots = await (_db.select(_db.mealPlanTemplateSlots)
            ..where((s) => s.templateId.equals(template.id)))
          .get();

      result.add(
        PlanTemplate(
          id: template.id,
          name: template.name,
          createdAt: template.createdAt,
          slots: slots.map((s) {
            return MealSlot(
              id: s.id,
              dayOfWeek: s.dayOfWeek,
              mealType: s.mealType,
              // weekStart is not meaningful in a template context; use epoch
              weekStart: DateTime.utc(1970),
              recipeId: s.recipeId,
              recipeTitle: s.recipeTitle,
              recipeImage: s.recipeImage,
            );
          }).toList(),
        ),
      );
    }
    return result;
  }

  /// Deletes a template and all its associated slots in a transaction.
  Future<void> deleteTemplate(String templateId) async {
    await _db.transaction(() async {
      // Delete child rows first to respect FK constraints
      await (_db.delete(_db.mealPlanTemplateSlots)
            ..where((s) => s.templateId.equals(templateId)))
          .go();
      await (_db.delete(_db.mealPlanTemplates)
            ..where((t) => t.id.equals(templateId)))
          .go();
    });
  }
}
