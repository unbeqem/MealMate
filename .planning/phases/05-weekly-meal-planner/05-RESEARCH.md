# Phase 5: Weekly Meal Planner - Research

**Researched:** 2026-03-02
**Domain:** Flutter drag-and-drop, 2D grid UI, Drift schema extension (meal_plan_slots + templates), Riverpod stream-notifier CRUD, ingredient overlap computation
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLAN-01 | User can view a 7-day weekly planner with breakfast, lunch, and dinner slots | `two_dimensional_scrollables` `TableView.builder` (Flutter team package, v0.3.8) or custom `SingleChildScrollView` + `Column` of rows; `MealPlanSlots` table already defined in Phase 1 schema with `dayOfWeek` and `mealType` columns |
| PLAN-02 | User can assign a recipe to any meal slot | Tap on an empty slot navigates to recipe picker (recipe browse screen from Phase 4); on selection, `MealPlanRepository.upsertSlot()` writes `MealPlanSlotsCompanion` with `recipeId`; Riverpod stream notifier reacts immediately |
| PLAN-03 | User can edit or replace a recipe in any meal slot | Same upsert path as PLAN-02 with a non-null `recipeId`; remove clears the slot via `MealPlanRepository.clearSlot()` which sets `recipeId` to null using `MealPlanSlotsCompanion(recipeId: Value(null))` |
| PLAN-04 | User can drag and drop meals to reschedule between slots | Flutter built-in `LongPressDraggable<MealSlotData>` + `DragTarget<MealSlotData>` on each cell; swap data on `onAcceptWithDetails`; call `MealPlanRepository.swapSlots()` to persist; critical pitfall: drag-in-scroll conflict documented below |
| PLAN-05 | User can save current week as a meal plan template | New Drift `MealPlanTemplates` + `MealPlanTemplateSlots` tables; `TemplateRepository.saveCurrentWeek(name)` bulk-inserts 21 slot copies; bottom-sheet input for template name |
| PLAN-06 | User can load a saved template into a future week | `TemplateRepository.loadTemplate(templateId, targetWeekStart)` reads template slots, maps each to a `MealPlanSlotsCompanion` for the target week, batch-inserts with upsert; week navigation via `DateTime` arithmetic |
| PLAN-07 | Planner suggests recipes that reuse ingredients already in the week's plan to reduce waste | Pure Dart `Set<String>.intersection()` on ingredient name sets; compute in a Riverpod `@riverpod` provider that watches current week's slot states; highlight candidate recipes in the recipe picker |
</phase_requirements>

---

## Summary

Phase 5 adds four distinct technical concerns on top of the Phase 1–4 foundation: (1) a 2D grid UI that shows 7 days × 3 meal types, (2) a slot assignment flow that reuses the Phase 4 recipe picker, (3) drag-and-drop rescheduling between cells, and (4) a templates system backed by two new Drift tables. The Phase 1 schema already defined `MealPlanSlots` with `dayOfWeek` and `mealType` columns, which is exactly the data model needed. Phase 4 established the repository and Drift patterns that Phase 5 follows directly.

The grid UI has a non-trivial decision: a 7-column layout does not fit in portrait width on most phones without horizontal scrolling. The recommended approach is `SingleChildScrollView(scrollDirection: Axis.horizontal)` wrapping a fixed-width `Row`-of-columns custom layout, rather than a `Table` or `two_dimensional_scrollables` widget. `two_dimensional_scrollables` (Flutter team package, v0.3.8) is purpose-built for large 2D datasets and would be over-engineered for a fixed 7×3 grid; it also has no built-in drag-and-drop support. The custom approach keeps drag targets outside the horizontal scroll physics, which sidesteps the well-documented gesture conflict between `Draggable` and scrollable parents.

Drag-and-drop is implemented with Flutter's built-in `LongPressDraggable<MealSlotData>` + `DragTarget<MealSlotData>`. These are the correct primitives for cross-cell (not just within-list) drag. Third-party reorderable grid packages (`flutter_reorderable_grid_view`, `reorderable_grid_view`) only support reordering within a single grid — they cannot move items between different grid positions in a 7×3 matrix. The ingredient reuse suggestion (PLAN-07) is pure Dart set arithmetic on ingredient name strings already present in the app from Phase 4 recipe data; no network call is needed.

**Primary recommendation:** Build a custom `PlannerGrid` widget using `SingleChildScrollView(horizontal)` → `Row` of 7 day columns, each a `Column` of 3 `DragTarget`-wrapped `MealSlotCard` widgets. Use `LongPressDraggable` on each filled slot card. Persist slot changes via `MealPlanRepository` backed by Drift with `insertOnConflictUpdate`. Follow the same stream-notifier pattern established in Phase 4: `build()` returns a `query.watch()` stream; mutation methods call the repository directly.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `drift` | 2.32.0 | `MealPlanSlots`, `MealPlanTemplates`, `MealPlanTemplateSlots` tables; CRUD + reactive streams | Project standard from Phase 1; already has `MealPlanSlots` table defined |
| `flutter_riverpod` | 3.x (codegen) | `MealPlanNotifier`, `TemplateNotifier` stream notifiers; ingredient reuse provider | Project standard; `@riverpod` codegen is the correct Riverpod 3.x path |
| `riverpod_annotation` | 4.x | `@riverpod` annotation | Required companion for codegen |
| `go_router` | 17.x | Navigation from planner slot → recipe picker; back navigation with selected recipe | Project standard from Phase 1 |
| `freezed` / `freezed_annotation` | 3.x | `MealSlotData` (drag payload), `WeeklyPlanState` models | Project standard from Phase 4 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `build_runner` | latest | Runs Drift + Riverpod + Freezed codegen | Required any time tables or providers are added |
| `uuid` | 4.x | UUID v4 for new template row PKs | Project standard from Phase 1 — templates get UUID PKs |
| `intl` | Flutter SDK bundled | Format day-of-week column headers (Mon, Tue…) | Use `DateFormat('EEE').format(date)` for abbreviated day names |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom `SingleChildScrollView` + `Row` grid | `two_dimensional_scrollables TableView` | `TableView` v0.3.8 is excellent for large 2D datasets but over-engineered for a fixed 7×3 grid and has no drag-and-drop support; adds package dependency for no benefit |
| `LongPressDraggable` + `DragTarget` (built-in) | `flutter_reorderable_grid_view` v5.5.3 | `flutter_reorderable_grid_view` only supports reordering within a single grid — cannot drag between different slot positions in a 7×3 matrix; not applicable here |
| Pure Dart `Set.intersection()` for PLAN-07 | Spoonacular `findByIngredients` API call | Spoonacular call costs API points and requires network; ingredient names are already in local Drift cache from Phase 4; local computation is instant and free |
| Drift `MealPlanTemplates` table | Serialize current week to JSON in SharedPreferences | SharedPreferences is limited in size and non-queryable; Drift keeps templates relational with slot-level granularity needed for Phase 6 shopping list |

**Installation (additions for this phase — most already in pubspec from prior phases):**
```bash
# No new runtime dependencies if Phase 4 is complete
# Only need to run codegen after schema changes:
dart run build_runner build --delete-conflicting-outputs
```

---

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── features/
│   └── meal_planner/
│       ├── data/
│       │   ├── meal_plan_repository.dart        # CRUD for MealPlanSlots
│       │   ├── template_repository.dart         # CRUD for Templates + TemplateSlots
│       │   └── meal_plan_dao.dart               # Drift DAO (joins slots + cached_recipes)
│       ├── domain/
│       │   ├── meal_slot.dart                   # @freezed domain model (slot + recipe summary)
│       │   ├── meal_slot.freezed.dart           # generated
│       │   ├── week_plan.dart                   # @freezed: List<MealSlot> for a week
│       │   └── plan_template.dart               # @freezed: template + its slots
│       └── presentation/
│           ├── planner_screen.dart              # root screen: week nav + PlannerGrid
│           ├── template_list_screen.dart        # list of saved templates + load action
│           ├── widgets/
│           │   ├── planner_grid.dart            # 7-col × 3-row layout with DragTargets
│           │   ├── meal_slot_card.dart          # LongPressDraggable card (recipe name + image)
│           │   ├── empty_slot_card.dart         # DragTarget + tap-to-assign affordance
│           │   └── ingredient_overlap_badge.dart # highlight badge for PLAN-07
│           └── providers/
│               ├── meal_plan_notifier.dart      # @riverpod StreamNotifier for week's slots
│               ├── template_notifier.dart       # @riverpod AsyncNotifier for templates list
│               └── ingredient_reuse_provider.dart # @riverpod for PLAN-07 overlap computation
│
core/
└── database/
    └── tables/
        ├── meal_plan_slots_table.dart           # already exists from Phase 1
        ├── meal_plan_templates_table.dart       # NEW: Phase 5
        └── meal_plan_template_slots_table.dart  # NEW: Phase 5
```

### Pattern 1: MealPlanNotifier — Stream-based with Mutation Methods
**What:** A `@riverpod` notifier whose `build()` returns the Drift stream for a specific week's slots joined with recipe summary data. Mutation methods (assign, clear, swap) write to Drift directly — the stream fires automatically.
**When to use:** Everywhere the planner grid needs to read or write slot data.

```dart
// Source: Drift stream docs https://drift.simonbinder.eu/dart_api/streams/
// + Dinko Marinac stream-notifier pattern https://dinkomarinac.dev/blog/building-local-first-flutter-apps-with-riverpod-drift-and-powersync/
// lib/features/meal_planner/presentation/providers/meal_plan_notifier.dart

part 'meal_plan_notifier.g.dart';

@riverpod
class MealPlanNotifier extends _$MealPlanNotifier {
  @override
  Stream<List<MealSlot>> build(DateTime weekStart) {
    final db = ref.watch(appDatabaseProvider);
    // Join meal_plan_slots with cached_recipes to get recipe title/image
    final query = db.select(db.mealPlanSlots).join([
      leftOuterJoin(
        db.cachedRecipes,
        db.cachedRecipes.id.equalsExp(db.mealPlanSlots.recipeId),
      ),
    ])
      ..where(
        db.mealPlanSlots.weekStart.equals(weekStart) &
        db.mealPlanSlots.userId.equals(ref.watch(currentUserIdProvider)),
      );
    return query.watch().map((rows) => rows.map(MealSlot.fromJoinRow).toList());
  }

  /// Assign or replace a recipe in a slot. Creates the slot row if it doesn't exist.
  Future<void> assignRecipe({
    required String dayOfWeek,
    required String mealType,
    required int recipeId,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final userId = ref.read(currentUserIdProvider);
    await db.into(db.mealPlanSlots).insertOnConflictUpdate(
      MealPlanSlotsCompanion.insert(
        userId: userId,
        weekStart: state.value!.first.weekStart, // use week being viewed
        dayOfWeek: dayOfWeek,
        mealType: mealType,
        recipeId: Value(recipeId),
      ),
    );
  }

  /// Clear a slot (set recipeId to null, keep the row for sync tracking).
  Future<void> clearSlot({
    required String dayOfWeek,
    required String mealType,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.mealPlanSlots)
          ..where(
            (s) =>
                s.dayOfWeek.equals(dayOfWeek) &
                s.mealType.equals(mealType) &
                s.userId.equals(ref.read(currentUserIdProvider)),
          ))
        .write(const MealPlanSlotsCompanion(recipeId: Value(null)));
  }

  /// Swap two slots: read both, write each other's recipeId.
  Future<void> swapSlots(MealSlot from, MealSlot to) async {
    final db = ref.read(appDatabaseProvider);
    final userId = ref.read(currentUserIdProvider);
    await db.transaction(() async {
      await (db.update(db.mealPlanSlots)
            ..where((s) =>
                s.dayOfWeek.equals(from.dayOfWeek) &
                s.mealType.equals(from.mealType) &
                s.userId.equals(userId)))
          .write(MealPlanSlotsCompanion(recipeId: Value(to.recipeId)));
      await (db.update(db.mealPlanSlots)
            ..where((s) =>
                s.dayOfWeek.equals(to.dayOfWeek) &
                s.mealType.equals(to.mealType) &
                s.userId.equals(userId)))
          .write(MealPlanSlotsCompanion(recipeId: Value(from.recipeId)));
    });
  }
}
```

### Pattern 2: Drift Schema — New Tables for Templates
**What:** Two new tables added to `app_database.dart`. Requires `schemaVersion` increment and a migration. `MealPlanTemplates` holds the name + creation date; `MealPlanTemplateSlots` holds the 21 slot entries (7 days × 3 meal types, some nullable).
**When to use:** Plans 05-01 and 05-04.

```dart
// Source: Drift table definition docs https://drift.simonbinder.eu/dart_api/tables/
// core/database/tables/meal_plan_templates_table.dart

class MealPlanTemplates extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get name => text()();  // user-given name, e.g. "Summer Favorites"
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class MealPlanTemplateSlots extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get templateId => text().references(MealPlanTemplates, #id)();
  TextColumn get dayOfWeek => text()(); // 'monday'...'sunday'
  TextColumn get mealType => text()();  // 'breakfast' | 'lunch' | 'dinner'
  // recipeId is nullable — not every slot in a template has to be filled
  IntColumn get recipeId => integer().nullable()();
  // Store recipe title/image at snapshot time so templates show correct info
  // even if cached_recipes TTL expires
  TextColumn get recipeTitle => text().nullable()();
  TextColumn get recipeImage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// In AppDatabase — increment schemaVersion to (current + 1):
@DriftDatabase(tables: [
  Ingredients, Recipes, MealPlanSlots, ShoppingListItems,
  MealPlanTemplates, MealPlanTemplateSlots,  // NEW
])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2;  // was 1 after Phase 1 (or current value + 1)

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(mealPlanTemplates);
        await m.createTable(mealPlanTemplateSlots);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

### Pattern 3: PlannerGrid Widget Layout
**What:** The 7×3 grid is built as a `SingleChildScrollView` (horizontal) wrapping a `Row` of 7 `DayColumn` widgets. Each `DayColumn` is a `Column` of 3 `MealSlotCell` widgets — one per meal type. Each cell is either `FilledSlotCard` (wrapped in `LongPressDraggable`) or `EmptySlotCard` (tap-to-assign). All cells are wrapped in `DragTarget`.
**When to use:** The `PlannerGrid` in plan 05-02.

```dart
// Source: Flutter drag-and-drop cookbook https://docs.flutter.dev/cookbook/effects/drag-a-widget
// lib/features/meal_planner/presentation/widgets/planner_grid.dart

@freezed
sealed class MealSlotData with _$MealSlotData {
  const factory MealSlotData({
    required String dayOfWeek,
    required String mealType,
    int? recipeId,
    String? recipeTitle,
    String? recipeImage,
  }) = _MealSlotData;
}

class PlannerGrid extends ConsumerWidget {
  const PlannerGrid({required this.weekStart, super.key});
  final DateTime weekStart;

  static const _days = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
  static const _meals = ['breakfast','lunch','dinner'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(mealPlanNotifierProvider(weekStart));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Use NeverScrollableScrollPhysics on inner scroll if drag is active
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _days.map((day) => _DayColumn(
          weekStart: weekStart,
          dayOfWeek: day,
          slots: slotsAsync,
        )).toList(),
      ),
    );
  }
}

class _MealSlotCell extends ConsumerWidget {
  const _MealSlotCell({
    required this.weekStart,
    required this.dayOfWeek,
    required this.mealType,
    required this.slot,
  });
  final DateTime weekStart;
  final String dayOfWeek;
  final String mealType;
  final MealSlot? slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = MealSlotData(
      dayOfWeek: dayOfWeek,
      mealType: mealType,
      recipeId: slot?.recipeId,
      recipeTitle: slot?.recipeTitle,
    );
    return DragTarget<MealSlotData>(
      onWillAcceptWithDetails: (details) =>
          // Accept any slot data except dropping on itself
          !(details.data.dayOfWeek == dayOfWeek && details.data.mealType == mealType),
      onAcceptWithDetails: (details) {
        ref.read(mealPlanNotifierProvider(weekStart).notifier)
           .swapSlots(details.data.toMealSlot(), data.toMealSlot());
      },
      builder: (context, candidateItems, rejectedItems) {
        final isHovered = candidateItems.isNotEmpty;
        return slot?.recipeId != null
            ? _FilledSlotCard(data: data, isHovered: isHovered)
            : _EmptySlotCard(
                dayOfWeek: dayOfWeek,
                mealType: mealType,
                weekStart: weekStart,
                isHovered: isHovered,
              );
      },
    );
  }
}

class _FilledSlotCard extends StatelessWidget {
  const _FilledSlotCard({required this.data, required this.isHovered});
  final MealSlotData data;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<MealSlotData>(
      data: data,
      feedback: Material(
        elevation: 4,
        child: _RecipeChip(title: data.recipeTitle ?? '', imageUrl: data.recipeImage),
      ),
      childWhenDragging: const _EmptySlotPlaceholder(),
      child: _RecipeChip(
        title: data.recipeTitle ?? '',
        imageUrl: data.recipeImage,
        highlighted: isHovered,
      ),
    );
  }
}
```

### Pattern 4: Ingredient Reuse Suggestion (PLAN-07)
**What:** A Riverpod provider that computes the set of ingredient names already used in the current week. When the recipe picker is opened from a slot, it passes this ingredient set down and highlights candidate recipes whose ingredient overlap > 0.
**When to use:** Plan 05-05. Runs entirely local — no API call needed.

```dart
// Source: Dart Set.intersection() docs https://api.flutter.dev/flutter/dart-core/Set/intersection.html
// lib/features/meal_planner/presentation/providers/ingredient_reuse_provider.dart

part 'ingredient_reuse_provider.g.dart';

/// Returns the set of all ingredient names (lowercase) used across all
/// filled slots in the current week's plan.
@riverpod
Set<String> weekIngredientNames(Ref ref, DateTime weekStart) {
  final slotsAsync = ref.watch(mealPlanNotifierProvider(weekStart));
  return slotsAsync.whenData((slots) {
    final names = <String>{};
    for (final slot in slots) {
      if (slot.ingredients != null) {
        names.addAll(slot.ingredients!.map((i) => i.name.toLowerCase()));
      }
    }
    return names;
  }).valueOrNull ?? {};
}

/// For a candidate recipe, compute how many of its ingredients overlap with
/// the current week's ingredient set.
@riverpod
int ingredientOverlapCount(
  Ref ref, {
  required DateTime weekStart,
  required List<String> candidateIngredientNames,
}) {
  final weekIngredients = ref.watch(weekIngredientNamesProvider(weekStart));
  final candidateSet = candidateIngredientNames.map((n) => n.toLowerCase()).toSet();
  return weekIngredients.intersection(candidateSet).length;
}

// Usage in recipe picker — sort/highlight by overlap count:
// final overlap = ref.watch(ingredientOverlapCountProvider(
//   weekStart: weekStart,
//   candidateIngredientNames: recipe.extendedIngredients.map((i) => i.name).toList(),
// ));
// if (overlap > 0) show IngredientOverlapBadge(count: overlap);
```

### Pattern 5: Template Save and Load
**What:** `TemplateRepository.saveCurrentWeek(name, weekStart)` snapshots all filled slots into `MealPlanTemplates` + `MealPlanTemplateSlots`. `loadTemplate(templateId, targetWeekStart)` reads template slots and batch-upserts them into `MealPlanSlots` for the target week.
**When to use:** Plan 05-04.

```dart
// Source: Drift writes docs https://drift.simonbinder.eu/dart_api/writes/
// lib/features/meal_planner/data/template_repository.dart

class TemplateRepository {
  TemplateRepository(this._db);
  final AppDatabase _db;

  Future<String> saveCurrentWeek({
    required String name,
    required String userId,
    required DateTime weekStart,
  }) async {
    final templateId = const Uuid().v4();

    // Load current week's filled slots
    final slots = await (_db.select(_db.mealPlanSlots)
          ..where((s) =>
              s.weekStart.equals(weekStart) &
              s.userId.equals(userId) &
              s.recipeId.isNotNull()))
        .get();

    await _db.transaction(() async {
      // Create template header
      await _db.into(_db.mealPlanTemplates).insert(
        MealPlanTemplatesCompanion.insert(
          id: Value(templateId),
          userId: userId,
          name: name,
        ),
      );

      // Snapshot each filled slot — batch for performance
      if (slots.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.mealPlanTemplateSlots,
            slots.map((s) => MealPlanTemplateSlotsCompanion.insert(
              templateId: templateId,
              dayOfWeek: s.dayOfWeek,
              mealType: s.mealType,
              recipeId: Value(s.recipeId),
              // Snapshot title/image from cached_recipes at save time
              recipeTitle: Value(s.recipeTitle),
              recipeImage: Value(s.recipeImage),
            )).toList(),
          );
        });
      }
    });

    return templateId;
  }

  Future<void> loadTemplate({
    required String templateId,
    required String userId,
    required DateTime targetWeekStart,
  }) async {
    final templateSlots = await (_db.select(_db.mealPlanTemplateSlots)
          ..where((ts) => ts.templateId.equals(templateId)))
        .get();

    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.mealPlanSlots,
        templateSlots.map((ts) => MealPlanSlotsCompanion.insert(
          userId: userId,
          weekStart: targetWeekStart,
          dayOfWeek: ts.dayOfWeek,
          mealType: ts.mealType,
          recipeId: Value(ts.recipeId),
        )).toList(),
      );
    });
  }

  Stream<List<MealPlanTemplate>> watchTemplates(String userId) {
    return (_db.select(_db.mealPlanTemplates)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}
```

### Pattern 6: Week Navigation Date Arithmetic
**What:** The planner shows one "week" at a time where a week is a `DateTime` representing Monday 00:00:00. `weekStart` is used as the foreign-key anchor for `MealPlanSlots`. Navigation arrows add/subtract 7 days.
**When to use:** The `PlannerScreen` week selector in plan 05-02.

```dart
// Source: Dart DateTime.weekday docs https://api.flutter.dev/flutter/dart-core/DateTime/weekday.html
// ISO 8601: Monday = 1, Sunday = 7

/// Compute the Monday of the week containing [date].
DateTime weekStartFor(DateTime date) {
  final daysFromMonday = date.weekday - DateTime.monday; // 0 for Mon, 6 for Sun
  return DateTime(date.year, date.month, date.day - daysFromMonday);
}

// Current week on open:
final currentWeekStart = weekStartFor(DateTime.now());

// Navigation:
DateTime nextWeek(DateTime weekStart) => weekStart.add(const Duration(days: 7));
DateTime prevWeek(DateTime weekStart) => weekStart.subtract(const Duration(days: 7));

// Column headers (Mon, Tue, etc.):
// DateFormat('EEE').format(weekStart.add(Duration(days: index)))
```

### Anti-Patterns to Avoid

- **Using `flutter_reorderable_grid_view` for cross-slot drag:** This package only reorders within a single `GridView`. It cannot drag a card from Monday/Breakfast to Thursday/Dinner. Use `LongPressDraggable` + `DragTarget` directly.
- **Calling `Draggable` without `LongPressDraggable`:** Standard `Draggable` starts on touch-down, which conflicts immediately with taps (the assign gesture). Use `LongPressDraggable` to disambiguate.
- **Storing the `weekStart` as a day-of-week string:** The planner can show any week, not just "this week". Store as `DateTime` (ISO date) in Drift so multiple weeks coexist without conflict.
- **Saving templates by serializing to JSON in SharedPreferences:** Templates need to be listable, queryable, and linked at the slot level for Phase 6 shopping list to read from templates. Keep them relational in Drift.
- **Calling `Set.intersection()` inside `build()`:** This is a pure computation but is called on every rebuild if inline. Extract into a dedicated Riverpod `@riverpod` provider so it only recomputes when the week's slots change.
- **Directly updating `mealType` as a localized string:** Store `'breakfast'`, `'lunch'`, `'dinner'` as canonical English strings in Drift. Localize only in the UI layer. Avoids locale mismatch issues if the user changes device language.
- **Using `StateNotifierProvider` for meal plan state:** Riverpod 3.0 moved it to `riverpod/legacy.dart`. Use `@riverpod` codegen with stream-returning `build()`.
- **Forgetting `schemaVersion` bump for template tables:** Phase 5 adds 2 new Drift tables. If `schemaVersion` is not incremented and `createTable()` migration added, the app crashes on existing installs. See Drift migration pattern in Phase 1 research.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Week start date computation | Manual date math in widget | `weekStartFor(DateTime)` helper + `DateTime.weekday` (ISO 8601 built-in) | ISO weekday is built into Dart's `DateTime`; one-liner |
| Ingredient overlap scoring | Custom tokenizer + similarity engine | `Set<String>.intersection()` on lowercased ingredient names | Dart's `Set.intersection()` is O(n); for 21 slots × ~10 ingredients each this is trivially fast |
| Cross-cell drag-and-drop | Third-party reorderable grid package | Flutter built-in `LongPressDraggable<T>` + `DragTarget<T>` | Third-party packages only support within-grid reorder; cross-slot drag requires native primitives |
| Template slot persistence | JSON blob in SharedPreferences | Drift `MealPlanTemplates` + `MealPlanTemplateSlots` tables | Relational storage supports querying, listing, and foreign-key links that Phase 6 shopping list needs |
| Week date column headers | Custom calendar library | `intl` (bundled) `DateFormat('EEE').format(date)` | One `DateFormat` call per column header — no calendar widget needed |

**Key insight:** Phase 5 builds on patterns already established in Phase 1 (Drift schema + UUID PKs) and Phase 4 (repository + stream notifier + recipe model). The main new complexity is the UI layer (grid layout + drag-and-drop) and the templates data model. Both can be solved with Flutter/Drift primitives rather than additional packages.

---

## Common Pitfalls

### Pitfall 1: Drag-and-Drop Gesture Conflict with Horizontal Scroll
**What goes wrong:** `LongPressDraggable` placed inside a `SingleChildScrollView(scrollDirection: Axis.horizontal)` causes one of two failure modes: (a) after a drag operation, the horizontal scroll stops responding until the user taps outside, or (b) the long-press gesture is consumed by the scroll recognizer and drag never starts.
**Why it happens:** Flutter's gesture arena has competing recognizers for the same pointer events. `SingleChildScrollView` and `LongPressDraggable` both register gesture recognizers. Known Flutter issue #144973 confirms scroll does not properly reset after drag within a scrollable.
**How to avoid:** Structure the layout so that each `DragTarget`-wrapped cell is not a direct child of the scrollable parent. Use `DragTarget` on the cells but keep `LongPressDraggable` as an immediate child of the cell widget (not the scroll view). Alternatively, set `NeverScrollableScrollPhysics` on the `SingleChildScrollView` while a drag is in progress (track drag state with a `ValueNotifier<bool>`), and restore physics on `onDragEnd`/`onDraggableCanceled`.
**Warning signs:** User reports inability to scroll after performing a drag. Or drag never starts in the horizontal zone.

### Pitfall 2: Missing `weekStart` Column on `MealPlanSlots`
**What goes wrong:** The Phase 1 `MealPlanSlots` table defined in the research uses `dayOfWeek TEXT` but does not include a `weekStart` column to distinguish slots for different weeks. Without it, every week shares the same 21 slots and loading a new week overwrites the previous one.
**Why it happens:** The Phase 1 table definition was a scaffold for a single current week; multi-week support was not required until Phase 5.
**How to avoid:** Plan 05-01 MUST add a `weekStart DateTimeColumn` to `MealPlanSlots` via a `schemaVersion` migration. The composite uniqueness constraint becomes `(userId, weekStart, dayOfWeek, mealType)`. This is the first schema migration the app will perform.
**Warning signs:** Navigating to a different week loads the same recipes as the current week.

### Pitfall 3: Template Slots Showing Stale Recipe Data
**What goes wrong:** Templates snapshot `recipeId` (an integer Spoonacular ID) but not the recipe title/image. After the 24-hour `cached_recipes` TTL expires, loading a template shows slot cards with no title or image until the user opens each recipe individually.
**Why it happens:** Templates reference `recipeId` but do not embed the display data at save time.
**How to avoid:** `MealPlanTemplateSlots` should include `recipeTitle TEXT NULLABLE` and `recipeImage TEXT NULLABLE` columns. At `saveCurrentWeek()` time, join against `cached_recipes` to snapshot the current title and image. The template slot card uses the snapshotted data for display; the actual recipe detail still uses the live `recipeId`.
**Warning signs:** Template list screen shows blank cards after first day of use.

### Pitfall 4: `swapSlots` Without a Database Transaction
**What goes wrong:** `swapSlots` writes slot A's recipeId, then the app is backgrounded before writing slot B. On resume, the database has an inconsistent state — slot A has B's recipe but slot B still has A's.
**Why it happens:** Two sequential `update()` calls without a transaction are not atomic.
**How to avoid:** Wrap both `update()` calls in `db.transaction(() async { ... })`. Drift transactions are SQLite `BEGIN IMMEDIATE`/`COMMIT` blocks. Either both writes succeed or neither does.
**Warning signs:** After a drag-and-drop, one slot shows the expected recipe but the other shows the original recipe (not swapped).

### Pitfall 5: Drift Schema Version Already Incremented by a Previous Phase
**What goes wrong:** Phase 4 added `CachedRecipes` to `AppDatabase`, which required incrementing `schemaVersion` to 2. Phase 5 adds two more tables, requiring version 3. If the Phase 5 developer assumes `schemaVersion` is still 1 and sets it to 2, the migration is skipped on devices that ran Phase 4.
**Why it happens:** Phases are implemented sequentially but the Phase 5 developer may not have checked the current `schemaVersion` in the codebase.
**How to avoid:** Before writing Phase 5 schema code, read `AppDatabase.schemaVersion` in the current codebase. Set Phase 5's version to `currentVersion + 1`. The `onUpgrade` guard `if (from < N)` handles any version gap.
**Warning signs:** `MigrationException` crash on startup, or the tables appear missing on Phase 4 devices.

### Pitfall 6: Ingredient Overlap Computation Using Recipe Summaries (No Ingredient Data)
**What goes wrong:** `weekIngredientNamesProvider` calls `slot.ingredients` but slots in the planner may be backed by `isSummaryOnly = true` cache entries (from Phase 4 `complexSearch`), which have no `extendedIngredients`. The ingredient set is always empty and PLAN-07 never highlights anything.
**Why it happens:** Phase 4 caches summary-only records for browse results. The slot card shows the recipe but the Drift `cached_recipes` row has an empty `jsonData.extendedIngredients`.
**How to avoid:** In `weekIngredientNamesProvider`, for each slot's `recipeId`, check if the Drift row is `isSummaryOnly`. If so, trigger a lazy-load of full recipe info via the Edge Function (same pattern as Phase 4 recipe detail). Only compute the ingredient set once all full records are loaded. The provider can return an empty set while loading — the badge simply won't show yet.
**Warning signs:** Ingredient overlap badges never appear on any recipe in the picker despite having a full week of meals planned.

---

## Code Examples

Verified patterns from official sources:

### MealPlanSlots Table with weekStart (Migration from Phase 1 schema)
```dart
// Source: Drift migration docs https://drift.simonbinder.eu/migrations/
// core/database/tables/meal_plan_slots_table.dart

class MealPlanSlots extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  // weekStart is the Monday of the week (date only, time = 00:00:00)
  DateTimeColumn get weekStart => dateTime()();
  TextColumn get recipeId => integer().nullable()(); // Spoonacular recipe id
  TextColumn get dayOfWeek => text()(); // 'monday'...'sunday'
  TextColumn get mealType => text()();  // 'breakfast' | 'lunch' | 'dinner'
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};

  // Conceptual unique constraint (enforced via upsert target):
  // UNIQUE(userId, weekStart, dayOfWeek, mealType)
}

// Migration in AppDatabase:
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      // Phase 4 added cached_recipes
      await m.createTable(cachedRecipes);
    }
    if (from < 3) {
      // Phase 5: add weekStart to meal_plan_slots + new template tables
      await m.addColumn(mealPlanSlots, mealPlanSlots.weekStart);
      await m.createTable(mealPlanTemplates);
      await m.createTable(mealPlanTemplateSlots);
    }
  },
);
```

### LongPressDraggable + DragTarget Type-Safe Pattern
```dart
// Source: Flutter drag-and-drop cookbook https://docs.flutter.dev/cookbook/effects/drag-a-widget
// The data type MUST match between LongPressDraggable<T> and DragTarget<T>

LongPressDraggable<MealSlotData>(
  data: MealSlotData(
    dayOfWeek: 'monday',
    mealType: 'breakfast',
    recipeId: 12345,
    recipeTitle: 'Avocado Toast',
  ),
  feedback: Material(
    elevation: 4,
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 120,
      child: RecipeChip(title: 'Avocado Toast'),
    ),
  ),
  childWhenDragging: const EmptySlotPlaceholder(),
  child: RecipeChip(title: 'Avocado Toast'),
);

DragTarget<MealSlotData>(
  onWillAcceptWithDetails: (details) => true,
  onAcceptWithDetails: (details) {
    // details.data is MealSlotData from the dropped LongPressDraggable
    notifier.swapSlots(details.data, currentSlotData);
  },
  builder: (context, candidateItems, rejectedItems) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        border: candidateItems.isNotEmpty
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: child,
    );
  },
);
```

### Batch Insert for Loading a Template
```dart
// Source: Drift writes docs https://drift.simonbinder.eu/dart_api/writes/
await db.batch((batch) {
  batch.insertAllOnConflictUpdate(
    db.mealPlanSlots,
    templateSlots.map((ts) => MealPlanSlotsCompanion.insert(
      userId: userId,
      weekStart: targetWeekStart,
      dayOfWeek: ts.dayOfWeek,
      mealType: ts.mealType,
      recipeId: Value(ts.recipeId),
    )).toList(),
  );
});
```

### Dart Set Intersection for Ingredient Overlap
```dart
// Source: Dart Set.intersection() https://api.flutter.dev/flutter/dart-core/Set/intersection.html
// Pure Dart — no dependency needed

final weekIngredients = {'chicken', 'garlic', 'olive oil', 'tomato', 'pasta'};
final candidateIngredients = {'chicken', 'lemon', 'garlic', 'thyme'};

final overlap = weekIngredients.intersection(candidateIngredients);
// Result: {'chicken', 'garlic'}

final overlapCount = overlap.length; // 2
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `StateNotifierProvider` for planner state | Stream-returning `@riverpod` notifier with `build()` → `query.watch()` | Riverpod 3.0 (Sep 2025) | Direct stream from Drift through Riverpod; reactive without manual `ref.invalidate()` |
| `DataTable` + `SingleChildScrollView` for 2D table | Custom `Row`-of-columns layout or `TableView.builder` | Flutter 3.x | `DataTable` renders off-screen content, causes jank; custom layout or `two_dimensional_scrollables` is efficient |
| Third-party reorderable grid for drag-and-drop | Flutter built-in `LongPressDraggable` + `DragTarget` | Ongoing community consensus | No third-party package supports cross-cell drag across a non-homogeneous grid |
| Integer PKs for template rows | UUID v4 `clientDefault()` | Phase 1 decision | UUID PKs required for offline-first multi-device sync in Phase 8 |

**Deprecated/outdated:**
- `StateNotifierProvider`: Moved to `riverpod/legacy.dart` in Riverpod 3.0 — do not use in Phase 5 code
- `flutter_reorderable_grid_view` for cross-list drag: Confirmed not applicable (within-grid only) — confirmed from package docs v5.5.3
- `two_dimensional_scrollables` for this use case: Over-engineered for 7×3 fixed grid; no drag support

---

## Open Questions

1. **`weekStart` column migration on existing Phase 1 `MealPlanSlots` data**
   - What we know: Phase 1 defined `MealPlanSlots` without a `weekStart` column; adding a column to an existing table with existing rows requires `addColumn()` migration
   - What's unclear: Drift's `addColumn()` for a `dateTime()` column requires either `nullable()` or a `withDefault()` value to populate existing rows; the correct default for existing rows needs to be decided
   - Recommendation: Add as `dateTime().withDefault(Constant(DateTime(2026, 1, 1)))` for migration safety; this is a dev-only concern since no real user data exists at Phase 5

2. **Horizontal scroll conflict severity on Android vs iOS**
   - What we know: Flutter GitHub issue #144973 confirms scroll stops responding after drag within a scrollable; the issue was reported but the Flutter team commented it "may be expected behavior"
   - What's unclear: Whether Flutter 3.41 has addressed this or whether `NeverScrollableScrollPhysics` during drag is the correct mitigation strategy
   - Recommendation: Plan 05-03 should include a physical device test on both Android and iOS specifically testing: drag a meal card, release, then try to scroll horizontally immediately. If scroll is blocked, implement the `ValueNotifier<bool>` scroll-physics toggling approach.

3. **Template slot count — partial templates**
   - What we know: A template can have 0–21 filled slots; only filled slots are saved
   - What's unclear: Whether loading a template into a week should (a) only fill the saved slots (leaving existing week slots untouched) or (b) overwrite all 21 slots (blanking slots not in the template)
   - Recommendation: Implement option (b) as the first pass — clear all slots for the target week, then load template slots. This is simpler and matches user mental model of "load template replaces the week". Make clearing + loading atomic in a Drift transaction.

4. **`recipeId` type mismatch: MealPlanSlots uses `IntColumn` but references Spoonacular integer IDs, while other tables use UUID TextColumn PKs**
   - What we know: Phase 1 defined `recipeId` as `text().nullable().references(Recipes, #id)` where `Recipes.id` is a UUID. But Spoonacular recipe IDs are integers. Phase 4 stored them as `IntColumn get id => integer()()` in `CachedRecipes`.
   - What's unclear: Whether `MealPlanSlots.recipeId` should reference `CachedRecipes.id` (integer FK) or `Recipes.id` (UUID FK for AI-generated recipes in Phase 7)
   - Recommendation: Phase 5 should use `IntColumn get recipeId` referencing `CachedRecipes.id` (Spoonacular integer). Phase 7 (AI recipes) will need to handle AI-generated recipes separately — potentially with a separate `aiRecipeId TEXT` column. This is a data model decision to resolve before Plan 05-01 schema work.

---

## Sources

### Primary (HIGH confidence)
- Flutter drag-and-drop cookbook https://docs.flutter.dev/cookbook/effects/drag-a-widget — `LongPressDraggable`, `DragTarget`, `onAcceptWithDetails` API; `data`, `feedback`, `childWhenDragging` properties
- Flutter `LongPressDraggable` class reference https://api.flutter.dev/flutter/widgets/LongPressDraggable-class.html — all properties and callbacks listed
- Dart `Set.intersection()` API https://api.flutter.dev/flutter/dart-core/Set/intersection.html — ingredient overlap computation
- Dart `DateTime.weekday` docs https://api.flutter.dev/flutter/dart-core/DateTime/weekday.html — ISO 8601 Monday=1, `weekStartFor()` helper
- Drift stream queries docs https://drift.simonbinder.eu/dart_api/streams/ — `watch()`, `watchSingle()`, `watchSingleOrNull()`, stream-based reactive queries
- Drift writes docs https://drift.simonbinder.eu/dart_api/writes/ — `insertOnConflictUpdate()`, `batch()`, Companion class partial updates, `Value.absent()`
- Drift migrations docs https://drift.simonbinder.eu/migrations/ — `addColumn()`, `createTable()`, `schemaVersion` increment pattern

### Secondary (MEDIUM confidence)
- `two_dimensional_scrollables` pub.dev https://pub.dev/packages/two_dimensional_scrollables — v0.3.8, Flutter team package, `TableView.builder`; confirmed over-engineered for fixed 7×3 grid + no drag support
- `flutter_reorderable_grid_view` pub.dev https://pub.dev/packages/flutter_reorderable_grid_view — v5.5.3; confirmed single-grid only, no cross-cell drag support
- Dinko Marinac: Building Local-First Flutter Apps with Riverpod, Drift, and PowerSync https://dinkomarinac.dev/blog/building-local-first-flutter-apps-with-riverpod-drift-and-powersync/ — stream-returning `@riverpod` notifier pattern with direct DAO writes; cross-verified with Riverpod official docs
- Flutter GitHub issue #144973 https://github.com/flutter/flutter/issues/144973 — drag-within-scrollable gesture conflict; team response suggests workaround rather than fix
- `in_date_utils` pub.dev — provides `firstDayOfWeek()` helper if custom `weekStartFor()` is considered too fragile

### Tertiary (LOW confidence)
- Various community Medium articles on Riverpod 3.0 + Drift integration patterns — consistent with Dinko Marinac article and official Riverpod docs but not independently verified from a single authoritative source
- Canopas Medium article on `two_dimensional_scrollables` https://medium.com/canopas/how-to-implement-2d-scrollable-tableview-in-flutter-a8b0fe703614 — performance comparison showing `TableView` at 60fps vs `DataTable+SingleChildScrollView` at 11fps; community benchmark, not official

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries verified from pub.dev or official Flutter docs; no new runtime dependencies beyond Phase 1–4 baseline
- Grid UI architecture (custom Row layout): HIGH — Flutter primitives; scroll conflict pitfall documented from official Flutter GitHub issue
- Drag-and-drop (LongPressDraggable + DragTarget): HIGH — official Flutter cookbook and API docs
- Drift schema extension + migrations: HIGH — verified from drift.simonbinder.eu official docs
- Riverpod stream-notifier pattern: HIGH — verified from Dinko Marinac article (primary Riverpod + Drift authority) + official Riverpod docs
- Ingredient overlap (Set.intersection): HIGH — Dart built-in API
- Template data model: MEDIUM — design pattern is straightforward Drift relational; recipeId type mismatch (open question 4) needs resolution before schema work
- Drag-scroll conflict resolution: MEDIUM — workaround direction is clear but exact mitigation code needs device testing

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (Riverpod 3.x, Drift 2.32, Flutter 3.41 APIs stable; drag-scroll behavior unlikely to change in a minor Flutter release; re-verify `two_dimensional_scrollables` version if that approach is reconsidered)
