import 'package:drift/drift.dart';
import 'package:meal_mate/core/database/app_database.dart';
import 'package:meal_mate/features/meal_planner/domain/meal_slot.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Repository for CRUD operations on the meal plan slots table.
///
/// The meal planner grid stores Spoonacular integer IDs as strings in the
/// recipeId column (e.g. "716429"). Joins with cachedRecipes use int.parse.
class MealPlanRepository {
  final AppDatabase _db;

  MealPlanRepository(this._db);

  /// Watches all slots for a given user and week, joined with cachedRecipes
  /// to populate title and image from the local cache.
  ///
  /// Returns a reactive Stream that emits whenever Drift detects changes.
  Stream<List<MealSlot>> watchWeek(String userId, DateTime weekStart) {
    // Normalise weekStart to midnight UTC to ensure consistent matching
    final weekStartNormalised = DateTime.utc(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    final query = _db.select(_db.mealPlanSlots).join([
      leftOuterJoin(
        _db.cachedRecipes,
        // Join condition: cast the text recipeId to int for comparison
        // SQLite will coerce the text column to int for equality comparison
        CustomExpression<bool>(
          '"meal_plan_slots"."recipe_id" = CAST("cached_recipes"."id" AS TEXT)',
        ),
      ),
    ]);
    query.where(
      _db.mealPlanSlots.userId.equals(userId) &
          _db.mealPlanSlots.weekStart.equals(weekStartNormalised),
    );

    return query.watch().map((rows) {
      return rows.map((row) {
        final slot = row.readTable(_db.mealPlanSlots);
        final cached = row.readTableOrNull(_db.cachedRecipes);
        return MealSlot(
          id: slot.id,
          dayOfWeek: slot.dayOfWeek,
          mealType: slot.mealType,
          weekStart: slot.weekStart,
          recipeId: slot.recipeId,
          recipeTitle: cached?.title,
          recipeImage: cached?.image,
        );
      }).toList();
    });
  }

  /// Assigns a recipe to a slot. Uses insert-or-replace so calling this on an
  /// already-assigned slot replaces the recipe without creating a duplicate row.
  ///
  /// The [recipeId] integer is stored as its string representation.
  /// [recipeTitle] and [recipeImage] are upserted into CachedRecipes so the
  /// watchWeek JOIN always finds display data for the slot.
  Future<void> assignRecipe({
    required String userId,
    required String dayOfWeek,
    required String mealType,
    required DateTime weekStart,
    required int recipeId,
    String? recipeTitle,
    String? recipeImage,
  }) async {
    // Ensure the recipe exists in CachedRecipes so the watchWeek JOIN
    // returns title/image. Uses insertOnConflictUpdate to avoid overwriting
    // a full-detail entry with summary-only data.
    final existing = await (_db.select(_db.cachedRecipes)
          ..where((r) => r.id.equals(recipeId)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.cachedRecipes).insertOnConflictUpdate(
            CachedRecipesCompanion.insert(
              id: Value(recipeId),
              title: recipeTitle ?? 'Recipe',
              image: Value(recipeImage),
              jsonData: '{}',
              isSummaryOnly: const Value(true),
            ),
          );
    }
    final weekStartNormalised = DateTime.utc(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    // Find existing slot for this position, or create a new id
    final existingSlot = await (_db.select(_db.mealPlanSlots)
          ..where(
            (s) =>
                s.userId.equals(userId) &
                s.weekStart.equals(weekStartNormalised) &
                s.dayOfWeek.equals(dayOfWeek) &
                s.mealType.equals(mealType),
          ))
        .getSingleOrNull();

    final slotId = existingSlot?.id ?? _uuid.v4();

    await _db.into(_db.mealPlanSlots).insertOnConflictUpdate(
      MealPlanSlotsCompanion.insert(
        id: Value(slotId),
        userId: userId,
        dayOfWeek: dayOfWeek,
        mealType: mealType,
        weekStart: weekStartNormalised,
        recipeId: Value(recipeId.toString()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Clears the recipe from a slot (sets recipeId to null).
  Future<void> clearSlot(String slotId) async {
    await (_db.update(_db.mealPlanSlots)
          ..where((s) => s.id.equals(slotId)))
        .write(
          const MealPlanSlotsCompanion(recipeId: Value(null)),
        );
  }

  /// Swaps the recipe assignments of two slots in a single transaction.
  Future<void> swapSlots(String slotIdA, String slotIdB) async {
    await _db.transaction(() async {
      final slotA = await (_db.select(_db.mealPlanSlots)
            ..where((s) => s.id.equals(slotIdA)))
          .getSingleOrNull();
      final slotB = await (_db.select(_db.mealPlanSlots)
            ..where((s) => s.id.equals(slotIdB)))
          .getSingleOrNull();

      if (slotA == null || slotB == null) return;

      await (_db.update(_db.mealPlanSlots)
            ..where((s) => s.id.equals(slotIdA)))
          .write(MealPlanSlotsCompanion(recipeId: Value(slotB.recipeId)));
      await (_db.update(_db.mealPlanSlots)
            ..where((s) => s.id.equals(slotIdB)))
          .write(MealPlanSlotsCompanion(recipeId: Value(slotA.recipeId)));
    });
  }

  /// Returns only the slots that have a recipe assigned for the given week.
  /// Used by template save and ingredient reuse logic.
  Future<List<MealSlot>> getFilledSlots(
    String userId,
    DateTime weekStart,
  ) async {
    final weekStartNormalised = DateTime.utc(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    final query = _db.select(_db.mealPlanSlots).join([
      leftOuterJoin(
        _db.cachedRecipes,
        CustomExpression<bool>(
          '"meal_plan_slots"."recipe_id" = CAST("cached_recipes"."id" AS TEXT)',
        ),
      ),
    ]);
    query.where(
      _db.mealPlanSlots.userId.equals(userId) &
          _db.mealPlanSlots.weekStart.equals(weekStartNormalised) &
          _db.mealPlanSlots.recipeId.isNotNull(),
    );

    final rows = await query.get();
    return rows.map((row) {
      final slot = row.readTable(_db.mealPlanSlots);
      final cached = row.readTableOrNull(_db.cachedRecipes);
      return MealSlot(
        id: slot.id,
        dayOfWeek: slot.dayOfWeek,
        mealType: slot.mealType,
        weekStart: slot.weekStart,
        recipeId: slot.recipeId,
        recipeTitle: cached?.title,
        recipeImage: cached?.image,
      );
    }).toList();
  }
}
