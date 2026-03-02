# Phase 6: Shopping List - Research

**Researched:** 2026-03-02
**Domain:** Drift aggregate queries, unit normalization pipeline, Riverpod 3.x stream providers, Flutter shopping list UI
**Confidence:** HIGH (Drift, Riverpod, Flutter UI patterns), MEDIUM (unit normalization — no standard Dart library covers all cooking units)

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SHOP-01 | Shopping list is auto-generated from all recipes in the current meal plan | Drift JOIN across `meal_plan_slots` → `cached_recipes` (JSON data) → extracted ingredients; `ShoppingListRepository.generateFromMealPlan()` reads all slots, parses recipe JSON, aggregates |
| SHOP-02 | Duplicate ingredients across recipes are merged into single line items | Deduplication by normalized ingredient name key during aggregation; `Map<String, ShoppingListItem>` merge pass before Drift write |
| SHOP-03 | Ingredient units are normalized (g/kg, ml/L, cups/tbsp/tsp) so quantities are summed correctly | Custom 5-stage normalization service; no Dart library covers all cooking unit families adequately — must be hand-written with exhaustive unit tests |
| SHOP-04 | User can manually add items to the shopping list (non-recipe items) | Drift `ShoppingListItems` table with `isManual` flag; Riverpod AsyncNotifier `addManualItem()` mutation |
| SHOP-05 | User can remove items from the shopping list | Riverpod AsyncNotifier `removeItem(id)` → Drift DELETE; stream triggers UI rebuild |
| SHOP-06 | User can check off items as purchased during shopping | `ShoppingListItems.isChecked` boolean; `toggleChecked(id)` mutation with optimistic update; Drift `.watch()` stream drives UI |
| SHOP-07 | User can adjust quantities on any shopping list item | `updateQuantity(id, newQuantity)` mutation; inline text field or stepper widget in the list tile |
</phase_requirements>

---

## Summary

Phase 6 has two largely independent technical concerns. The first is the **aggregation pipeline**: reading all recipes from the current meal plan, extracting their ingredient lists, normalizing units so quantities can be summed, deduplicating by ingredient name, and persisting the result to the `shopping_list_items` Drift table. The second concern is the **UI layer**: a reactive ListView driven by a Drift `.watch()` stream exposed as a Riverpod `StreamProvider`, with mutations for check-off, quantity editing, manual add, and removal — all persisting to Drift and surviving app restarts.

The hardest technical problem is unit normalization (SHOP-03). No Dart pub.dev package adequately covers all cooking unit families with correct conversion factors. The `units_converter` package (3.1.0) handles metric mass and volume but lacks US customary cooking units (cups, tbsp, tsp). The `measurements` package (GitHub only, v0.1.0, 0 stars) is unstable. **The correct approach is a custom normalization service** — a small, self-contained Dart class with a conversion table mapping all unit strings to a canonical base unit per family, plus exhaustive unit tests. This is testable, controllable, and the right scope of work for a cooking-unit problem. The plan already specifies this as a 5-stage pipeline.

The Drift + Riverpod integration pattern for the UI is well-established: Drift DAO exposes a `Stream<List<ShoppingListItem>>` via `.watch()`; a Riverpod `StreamProvider` wraps it; the widget uses `.when(data:, loading:, error:)`. Mutations (toggle, update, add, remove) go through a Riverpod `AsyncNotifier` that writes to Drift; the stream automatically re-emits. No manual UI refresh is needed.

**Primary recommendation:** Build the unit normalization service first with full unit coverage and exhaustive tests before writing any aggregation or UI code — every other part of this phase depends on it being correct.

---

## Standard Stack

### Core (all already in project from prior phases)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `drift` | 2.32.0 | Shopping list persistence, aggregate queries | Project database; `.watch()` drives reactive UI; Drift JOIN + aggregate patterns verified |
| `flutter_riverpod` | 3.2.1 | State management for list + mutations | Project standard; `StreamProvider` + `AsyncNotifier` is the correct pattern for Drift-backed lists |
| `riverpod_annotation` | 4.0.2 | Code generation for providers | Project standard; always use with riverpod_generator |
| `freezed_annotation` | 2.4.x | `ShoppingListItem` domain model | Project standard; immutable model with `copyWith` for optimistic updates |

### No New Dependencies Required

Phase 6 uses exclusively the stack established in Phases 1–4. No new pub.dev packages need to be added.

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom unit normalization | `units_converter 3.1.0` | units_converter lacks US culinary units (cups, tbsp, tsp); custom service is 100–150 lines with full control |
| Custom unit normalization | `measurements` (GitHub, v0.1.0) | 0 stars, unstable API, not on pub.dev — do not use in production |
| Drift `.watch()` stream | `FutureProvider` + manual refresh | `.watch()` is reactive — no refresh calls needed; FutureProvider would require manual invalidation on every mutation |

**Installation:** No new packages. All dependencies already in `pubspec.yaml`.

---

## Architecture Patterns

### Recommended Project Structure

```
lib/
├── core/
│   └── services/
│       └── unit_normalizer.dart        # 5-stage unit normalization service
│
├── features/
│   └── shopping/
│       ├── data/
│       │   ├── shopping_list_dao.dart         # Drift DAO: watch, insert, update, delete
│       │   └── shopping_list_repository.dart  # generateFromMealPlan(), manual add/remove/toggle
│       ├── domain/
│       │   ├── shopping_list_item.dart        # @freezed model
│       │   └── shopping_list_item.freezed.dart # generated
│       └── presentation/
│           ├── shopping_list_screen.dart      # main screen
│           ├── providers/
│           │   ├── shopping_list_provider.dart     # StreamProvider wrapping DAO watch()
│           │   └── shopping_list_notifier.dart     # AsyncNotifier for mutations
│           └── widgets/
│               ├── shopping_item_tile.dart         # CheckboxListTile + quantity editor
│               └── add_item_bottom_sheet.dart      # Manual add sheet
```

### Pattern 1: Drift DAO for Shopping List with Stream

**What:** A DAO wraps all shopping list queries. The `watchAll()` method returns a `Stream<List<ShoppingListItem>>` that Drift automatically re-emits when the table changes. Mutations use `into().insertOnConflictUpdate()` and `delete()` with `where`.

**When to use:** All shopping list database access goes through this DAO.

```dart
// Source: drift.simonbinder.eu/dart_api/daos/ + drift.simonbinder.eu/dart_api/streams/
// lib/features/shopping/data/shopping_list_dao.dart

part of 'app_database.dart';

@DriftAccessor(tables: [ShoppingListItems])
class ShoppingListDao extends DatabaseAccessor<AppDatabase>
    with _$ShoppingListDaoMixin {
  ShoppingListDao(super.db);

  // Reactive stream — re-emits on any insert/update/delete
  Stream<List<ShoppingListItem>> watchAll(String userId) {
    return (select(shoppingListItems)
          ..where((i) => i.userId.equals(userId))
          ..orderBy([
            (i) => OrderingTerm.asc(i.isChecked), // unchecked first
            (i) => OrderingTerm.asc(i.name),
          ]))
        .watch();
  }

  Future<void> upsertItem(ShoppingListItemsCompanion item) =>
      into(shoppingListItems).insertOnConflictUpdate(item);

  Future<void> deleteItem(String id) =>
      (delete(shoppingListItems)..where((i) => i.id.equals(id))).go();

  Future<void> toggleChecked(String id, bool current) {
    return (update(shoppingListItems)..where((i) => i.id.equals(id)))
        .write(ShoppingListItemsCompanion(isChecked: Value(!current)));
  }

  Future<void> updateQuantity(String id, double quantity) {
    return (update(shoppingListItems)..where((i) => i.id.equals(id)))
        .write(ShoppingListItemsCompanion(quantity: Value(quantity)));
  }

  Future<void> replaceAll(List<ShoppingListItemsCompanion> items, String userId) {
    return transaction(() async {
      // Clear all auto-generated items, preserve manual ones
      await (delete(shoppingListItems)
            ..where((i) => i.userId.equals(userId))
            ..where((i) => i.isManual.equals(false)))
          .go();
      for (final item in items) {
        await into(shoppingListItems).insertOnConflictUpdate(item);
      }
    });
  }
}
```

**Critical note:** The `ShoppingListItems` Drift table defined in Phase 1 (in `01-RESEARCH.md`) does not have an `isManual` flag column. Phase 6 must add this column via a Drift schema migration (increment `schemaVersion`).

### Pattern 2: StreamProvider Wrapping Drift Watch

**What:** A `@riverpod` `StreamProvider` wraps the DAO's `watchAll()`. The widget watches this provider and gets `AsyncValue<List<ShoppingListItem>>`.

**When to use:** The main shopping list screen.

```dart
// Source: pattern from deepwiki.com/h-enoki/sample_drift_app + Riverpod docs
// lib/features/shopping/presentation/providers/shopping_list_provider.dart

part 'shopping_list_provider.g.dart';

@riverpod
Stream<List<ShoppingListItem>> shoppingList(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return db.shoppingListDao.watchAll(userId);
}
```

Consumed in widget:
```dart
final listAsync = ref.watch(shoppingListProvider);
return listAsync.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
  data: (items) => ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, i) => ShoppingItemTile(item: items[i]),
  ),
);
```

### Pattern 3: AsyncNotifier for Mutations

**What:** A Riverpod `AsyncNotifier` handles all write operations (add, remove, toggle, update). Each mutation writes to Drift; the `StreamProvider` automatically re-emits because Drift detects the table change.

**When to use:** For every mutation action from the UI.

```dart
// Source: codewithandrea.com/articles/flutter-riverpod-async-notifier/
// lib/features/shopping/presentation/providers/shopping_list_notifier.dart

part 'shopping_list_notifier.g.dart';

@riverpod
class ShoppingListNotifier extends _$ShoppingListNotifier {
  @override
  Future<void> build() async {}  // No state — mutations are fire-and-forget

  Future<void> toggleChecked(String id, bool current) async {
    final db = ref.read(appDatabaseProvider);
    final userId = ref.read(currentUserIdProvider);
    await db.shoppingListDao.toggleChecked(id, current);
    // No manual state update needed — StreamProvider re-emits from Drift watch
  }

  Future<void> updateQuantity(String id, double quantity) async {
    final db = ref.read(appDatabaseProvider);
    await db.shoppingListDao.updateQuantity(id, quantity);
  }

  Future<void> removeItem(String id) async {
    final db = ref.read(appDatabaseProvider);
    await db.shoppingListDao.deleteItem(id);
  }

  Future<void> addManualItem({
    required String name,
    required double quantity,
    required String unit,
    required String userId,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await db.shoppingListDao.upsertItem(
      ShoppingListItemsCompanion(
        id: Value(const Uuid().v4()),
        userId: Value(userId),
        name: Value(name),
        quantity: Value(quantity),
        unit: Value(unit),
        isChecked: const Value(false),
        isManual: const Value(true),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<void> generateFromMealPlan(String userId) async {
    final repository = ref.read(shoppingListRepositoryProvider);
    await repository.generateFromMealPlan(userId);
    // Stream auto-updates after repository writes to Drift
  }
}
```

### Pattern 4: Unit Normalization Service (5-Stage Pipeline)

**What:** A pure Dart service that takes an ingredient name, quantity, and unit string, and returns a normalized `(canonicalName, quantity, canonicalUnit)` triple. The 5 stages are: (1) lexical normalization, (2) unit family detection, (3) intra-family conversion to base unit, (4) cross-family conflict handling, (5) density lookup fallback.

**When to use:** Called during shopping list generation for every ingredient before the merge/dedup step.

```dart
// lib/core/services/unit_normalizer.dart
// No external dependency — pure Dart

/// Canonical base units per family:
/// - Mass family: grams (g)
/// - Volume family: milliliters (ml)
/// - Count family: "whole" (no unit)

class UnitNormalizer {
  // Conversion table: unit alias → (family, factor to base unit)
  static const Map<String, _UnitDef> _unitMap = {
    // Mass family (base: grams)
    'g': _UnitDef('mass', 1.0),
    'gram': _UnitDef('mass', 1.0),
    'grams': _UnitDef('mass', 1.0),
    'kg': _UnitDef('mass', 1000.0),
    'kilogram': _UnitDef('mass', 1000.0),
    'kilograms': _UnitDef('mass', 1000.0),
    'oz': _UnitDef('mass', 28.3495),
    'ounce': _UnitDef('mass', 28.3495),
    'ounces': _UnitDef('mass', 28.3495),
    'lb': _UnitDef('mass', 453.592),
    'lbs': _UnitDef('mass', 453.592),
    'pound': _UnitDef('mass', 453.592),
    'pounds': _UnitDef('mass', 453.592),

    // Volume family (base: milliliters)
    'ml': _UnitDef('volume', 1.0),
    'milliliter': _UnitDef('volume', 1.0),
    'milliliters': _UnitDef('volume', 1.0),
    'l': _UnitDef('volume', 1000.0),
    'liter': _UnitDef('volume', 1000.0),
    'liters': _UnitDef('volume', 1000.0),
    'litre': _UnitDef('volume', 1000.0),
    'litres': _UnitDef('volume', 1000.0),
    'tsp': _UnitDef('volume', 4.92892),
    'teaspoon': _UnitDef('volume', 4.92892),
    'teaspoons': _UnitDef('volume', 4.92892),
    'tbsp': _UnitDef('volume', 14.7868),
    'tablespoon': _UnitDef('volume', 14.7868),
    'tablespoons': _UnitDef('volume', 14.7868),
    'cup': _UnitDef('volume', 236.588),
    'cups': _UnitDef('volume', 236.588),
    'fl oz': _UnitDef('volume', 29.5735),
    'fluid ounce': _UnitDef('volume', 29.5735),
    'fluid ounces': _UnitDef('volume', 29.5735),
    'pt': _UnitDef('volume', 473.176),
    'pint': _UnitDef('volume', 473.176),
    'pints': _UnitDef('volume', 473.176),
    'qt': _UnitDef('volume', 946.353),
    'quart': _UnitDef('volume', 946.353),
    'quarts': _UnitDef('volume', 946.353),
    'gal': _UnitDef('volume', 3785.41),
    'gallon': _UnitDef('volume', 3785.41),
    'gallons': _UnitDef('volume', 3785.41),

    // Count family — no conversion, kept as-is
    '': _UnitDef('count', 1.0),
    'whole': _UnitDef('count', 1.0),
    'clove': _UnitDef('count', 1.0),
    'cloves': _UnitDef('count', 1.0),
    'piece': _UnitDef('count', 1.0),
    'pieces': _UnitDef('count', 1.0),
    'slice': _UnitDef('count', 1.0),
    'slices': _UnitDef('count', 1.0),
    'large': _UnitDef('count', 1.0),
    'medium': _UnitDef('count', 1.0),
    'small': _UnitDef('count', 1.0),
    'pinch': _UnitDef('count', 1.0),
    'pinches': _UnitDef('count', 1.0),
    'dash': _UnitDef('count', 1.0),
    'dashes': _UnitDef('count', 1.0),
    'handful': _UnitDef('count', 1.0),
    'handfuls': _UnitDef('count', 1.0),
    'can': _UnitDef('count', 1.0),
    'cans': _UnitDef('count', 1.0),
    'package': _UnitDef('count', 1.0),
    'packages': _UnitDef('count', 1.0),
    'serving': _UnitDef('count', 1.0),
    'servings': _UnitDef('count', 1.0),
  };

  /// Normalize a unit string to lowercase and trim whitespace.
  String _lexNormalize(String unit) => unit.toLowerCase().trim();

  /// Returns (family, quantityInBaseUnit) or null if unknown unit.
  ({String family, double baseQty, String baseUnit})? normalize({
    required double quantity,
    required String unit,
  }) {
    final key = _lexNormalize(unit);
    final def = _unitMap[key];
    if (def == null) return null; // unknown unit — caller handles as count

    final baseUnit = switch (def.family) {
      'mass' => 'g',
      'volume' => 'ml',
      _ => key.isEmpty ? 'whole' : key, // count family keeps its original unit
    };

    return (
      family: def.family,
      baseQty: quantity * def.factor,
      baseUnit: baseUnit,
    );
  }

  /// Normalize a base-unit quantity to a human-readable display unit.
  /// e.g., 1500ml → '1.5 L', 1000g → '1 kg', 5ml → '1 tsp'
  String formatBaseQuantity(double baseQty, String family) {
    switch (family) {
      case 'mass':
        if (baseQty >= 1000) return '${(baseQty / 1000).toStringAsFixed(1)} kg';
        return '${baseQty.round()} g';
      case 'volume':
        if (baseQty >= 1000) return '${(baseQty / 1000).toStringAsFixed(1)} L';
        if (baseQty >= 236.588) {
          return '${(baseQty / 236.588).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} cups';
        }
        if (baseQty >= 14.7868) {
          return '${(baseQty / 14.7868).toStringAsFixed(1)} tbsp';
        }
        return '${(baseQty / 4.92892).toStringAsFixed(1)} tsp';
      default:
        return '${baseQty.round()} whole';
    }
  }
}

class _UnitDef {
  final String family;
  final double factor; // multiply quantity by this to get base unit
  const _UnitDef(this.family, this.factor);
}
```

### Pattern 5: Shopping List Generation from Meal Plan

**What:** `ShoppingListRepository.generateFromMealPlan()` reads `meal_plan_slots` from Drift, parses the recipe JSON for each slot, normalizes every ingredient unit, merges by ingredient name + family, then writes the result to `shopping_list_items` (replacing all non-manual items).

**When to use:** Called whenever the user opens the shopping list screen or explicitly regenerates it.

```dart
// lib/features/shopping/data/shopping_list_repository.dart

class ShoppingListRepository {
  final AppDatabase _db;
  final UnitNormalizer _normalizer;

  ShoppingListRepository(this._db, this._normalizer);

  Future<void> generateFromMealPlan(String userId) async {
    // 1. Load all meal plan slots that have a recipe
    final slots = await (_db.select(_db.mealPlanSlots)
          ..where((s) => s.userId.equals(userId))
          ..where((s) => s.recipeId.isNotNull()))
        .get();

    // 2. For each slot, load the cached recipe JSON
    final Map<String, _AggEntry> aggregated = {};

    for (final slot in slots) {
      final cached = await (_db.select(_db.cachedRecipes)
            ..where((r) => r.id.equals(int.parse(slot.recipeId!))))
          .getSingleOrNull();
      if (cached == null || cached.isSummaryOnly) continue;

      final recipe = Recipe.fromJson(
        jsonDecode(cached.jsonData) as Map<String, dynamic>,
      );

      for (final ingredient in recipe.extendedIngredients) {
        // 3. Normalize the unit to base unit
        final result = _normalizer.normalize(
          quantity: ingredient.amount,
          unit: ingredient.unit,
        );

        // Build a merge key: ingredient name + family (cross-family = conflict)
        final name = ingredient.name.toLowerCase().trim();
        final family = result?.family ?? 'count';
        final mergeKey = '$name|$family';

        if (aggregated.containsKey(mergeKey)) {
          // 4. Sum quantities (already in base units)
          aggregated[mergeKey]!.baseQty += result?.baseQty ?? ingredient.amount;
        } else {
          aggregated[mergeKey] = _AggEntry(
            name: ingredient.name,
            family: family,
            baseQty: result?.baseQty ?? ingredient.amount,
            baseUnit: result?.baseUnit ?? ingredient.unit,
          );
        }
      }
    }

    // 5. Convert to ShoppingListItemsCompanion and persist
    final companions = aggregated.values.map((entry) {
      final display = _normalizer.formatBaseQuantity(entry.baseQty, entry.family);
      // Parse display back to quantity + unit
      // (or store baseQty + baseUnit directly and format at display time)
      return ShoppingListItemsCompanion(
        id: Value(const Uuid().v4()),
        userId: Value(userId),
        name: Value(entry.name),
        quantity: Value(entry.baseQty),
        unit: Value(entry.baseUnit),
        isChecked: const Value(false),
        isManual: const Value(false),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      );
    }).toList();

    await _db.shoppingListDao.replaceAll(companions, userId);
  }
}

class _AggEntry {
  final String name;
  final String family;
  double baseQty;
  final String baseUnit;
  _AggEntry({required this.name, required this.family, required this.baseQty, required this.baseUnit});
}
```

### Pattern 6: Shopping Item Tile UI

**What:** A `CheckboxListTile` widget with trailing quantity display and long-press to edit. Checked items visually dim with strikethrough text.

**When to use:** Each item in the `ListView.builder` on the shopping list screen.

```dart
// lib/features/shopping/presentation/widgets/shopping_item_tile.dart

class ShoppingItemTile extends ConsumerWidget {
  final ShoppingListItem item;
  const ShoppingItemTile({required this.item, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      value: item.isChecked,
      onChanged: (_) => ref
          .read(shoppingListNotifierProvider.notifier)
          .toggleChecked(item.id, item.isChecked),
      title: Text(
        item.name,
        style: item.isChecked
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text('${item.quantity} ${item.unit}'),
      secondary: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => ref
            .read(shoppingListNotifierProvider.notifier)
            .removeItem(item.id),
      ),
    );
  }
}
```

### Anti-Patterns to Avoid

- **Re-generating the shopping list on every app launch:** Generation should be triggered by the user or when the meal plan changes, not on every screen open. Cache the generated list in Drift and only regenerate on explicit user action or after meal plan modification.
- **Storing scaled display strings in the database:** Store `baseQty` (double) and `baseUnit` (canonical string like `'g'`, `'ml'`). Format for display at render time. This makes quantity editing unambiguous.
- **Cross-family summation (e.g., grams + cups of the same ingredient):** A recipe may list `100g flour` and another `1 cup flour`. Mass and volume cannot be summed without a density lookup. For Phase 6, treat mass-flour and volume-flour as separate line items — do not attempt density conversion. This is the documented "cross-family conflict" stage: emit two line items rather than guessing.
- **Using `setState` directly in a StatefulWidget for check-off:** The check-off state is persisted (SHOP-06 requires it to survive app restarts). Always write to Drift; never rely on local widget state.
- **Forgetting `isManual` column requires a Drift migration:** The Phase 1 `ShoppingListItems` table schema does not have `isManual`. Adding it requires incrementing `schemaVersion` and a migration.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reactive list that updates on DB change | `Timer.periodic` polling | Drift `.watch()` stream | Drift tracks table mutations and re-emits automatically; polling is wasteful and laggy |
| Manual stream subscription in widget | `StreamBuilder` + `StreamController` | `StreamProvider` + Riverpod `ref.watch()` | Riverpod manages subscription lifecycle, auto-dispose, loading/error states |
| Unit conversion between tsp/tbsp/cups | Custom ad-hoc conditionals | `UnitNormalizer` service with conversion table | A lookup table with 30 unit aliases is the correct scope; ad-hoc conditionals diverge when edge cases appear |
| Atomic "replace all non-manual items" | Two separate DELETE + INSERT calls | `db.transaction(() async { ... })` | Without a transaction, a crash between DELETE and INSERT leaves the shopping list empty |
| Quantity display formatting | Each widget formats independently | `UnitNormalizer.formatBaseQuantity()` | Centralized formatting ensures "1.5 L" not "1500.0 ml" consistently across the screen |

**Key insight:** The Drift `.watch()` → `StreamProvider` → widget pipeline means zero manual refresh code. Write to Drift; the UI updates itself. Every custom "refresh on X" pattern is an anti-pattern in this stack.

---

## Common Pitfalls

### Pitfall 1: Missing `isManual` Column — Schema Migration Forgotten

**What goes wrong:** Phase 6 code references `ShoppingListItems.isManual` but the Drift table was defined in Phase 1 without it. App crashes on startup with `MigrationException`.

**Why it happens:** Phase 1 research document defines a minimal `ShoppingListItems` schema without `isManual`. The column is required to distinguish auto-generated items (from meal plan) from manual user-added items so that `replaceAll()` only clears auto-generated ones.

**How to avoid:** At the START of plan 06-02, increment `AppDatabase.schemaVersion` and add the migration:
```dart
if (from < N) {
  await m.addColumn(shoppingListItems, shoppingListItems.isManual);
}
```
Set the default to `false` so existing rows become auto-generated.

**Warning signs:** `MigrationException` or `no such column: isManual` on first run after Phase 6 install.

### Pitfall 2: Cross-Family Unit Conflict Causes Incorrect Summing

**What goes wrong:** Recipe A uses `100g flour`, Recipe B uses `1 cup flour`. The aggregation naively sums `100 + 1 = 101` into either grams or cups, producing nonsense.

**Why it happens:** The merge key is only ingredient name, not name + unit family. Grams and cups are in different families and cannot be summed without density conversion.

**How to avoid:** Build the merge key as `"$name|$family"` (e.g., `"flour|mass"` and `"flour|volume"` are separate entries). Emit two separate shopping list line items. Display both to the user — they can combine manually. The density lookup path is out of scope for Phase 6.

**Warning signs:** Shopping list shows "101 g flour" when one recipe used cups.

### Pitfall 3: Unknown Unit String from Spoonacular

**What goes wrong:** Spoonacular returns a unit like `"head"`, `"stalk"`, `"sprig"`, `"bunch"`, `"fillet"` that is not in the `UnitNormalizer._unitMap`. The normalization returns `null`. If not handled, the quantity is dropped or causes a null error.

**Why it happens:** Spoonacular's `extendedIngredients.unit` field contains free-text — over 50 unit variants are known, including non-standard ones. No public complete list exists.

**How to avoid:** In `normalize()`, when `_unitMap[key]` is `null`, treat the ingredient as count family with `quantity = ingredient.amount` and `unit = ingredient.unit` (preserve original). Never drop an ingredient because its unit is unknown. Log unknown units in debug mode to discover gaps.

**Warning signs:** Shopping list missing ingredients that had unusual units.

### Pitfall 4: `replaceAll` Not Wrapped in a Transaction

**What goes wrong:** App is killed mid-generation (screen rotation, background kill). The DELETE has run but the INSERTs haven't finished. Shopping list is empty.

**Why it happens:** Two separate Drift write calls without a transaction are not atomic.

**How to avoid:** Wrap `DELETE` + `INSERT` in `db.transaction(() async { ... })`. Drift rolls back the entire block if any step throws.

**Warning signs:** Shopping list occasionally empty after app restart with no apparent data entry.

### Pitfall 5: Shopping List Not Regenerated After Meal Plan Change

**What goes wrong:** User changes recipes in their meal plan (Phase 5 feature), then opens the shopping list. The list reflects the old meal plan because regeneration is not triggered.

**Why it happens:** The shopping list screen reads the Drift `shopping_list_items` table directly — it does not watch `meal_plan_slots`. There is no automatic link.

**How to avoid:** Trigger regeneration when the shopping list tab is activated AND the meal plan has been modified since last generation. Store a `lastGeneratedAt` timestamp in `SharedPreferences` or a Drift table; compare against the most recent `meal_plan_slots.updated_at`. Show a "Regenerate shopping list" banner if stale.

**Warning signs:** User sees outdated items in shopping list after changing meal plan.

### Pitfall 6: Rebuilding Entire List on Every Check-Off

**What goes wrong:** Each `toggleChecked()` call triggers a full `ListView` rebuild including all unchecked items, causing janky animations on long lists.

**Why it happens:** The `StreamProvider` emits a new `List<ShoppingListItem>` on every Drift table change. Each new emission rebuilds the entire `ListView.builder`.

**How to avoid:** Use `const` constructors for `ShoppingItemTile` where possible. If list performance is a concern, use individual `itemProvider(id)` selectors instead of a full-list stream — Riverpod's `.select()` filters rebuilds to the exact changed item. For Phase 6 MVP (typically < 30 items), full rebuild is acceptable.

**Warning signs:** Visible lag or animation stutter when checking off items on a long list.

---

## Code Examples

Verified patterns from official sources:

### Drift Table — ShoppingListItems with isManual Column

```dart
// Source: drift.simonbinder.eu/dart_api/tables/
// Note: Phase 1 schema did NOT include isManual — this requires a migration
class ShoppingListItems extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  BoolColumn get isManual => boolean().withDefault(const Constant(false))(); // NEW in Phase 6
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Schema Migration for isManual Column

```dart
// Source: drift.simonbinder.eu/migrations/
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      // Phase 4: add cachedRecipes table (per Phase 4 research)
      await m.createTable(cachedRecipes);
    }
    if (from < 3) {
      // Phase 6: add isManual column to shoppingListItems
      await m.addColumn(shoppingListItems, shoppingListItems.isManual);
    }
    // Note: exact version numbers depend on what Phases 1-5 established
    // Check AppDatabase.schemaVersion before implementing
  },
);
```

### Riverpod StreamProvider Watching Drift DAO

```dart
// Source: drift.simonbinder.eu/dart_api/streams/ + riverpod.dev
@riverpod
Stream<List<ShoppingListItem>> shoppingList(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  // Drift auto-notifies this stream whenever shoppingListItems table changes
  return db.shoppingListDao.watchAll(userId);
}
```

### Drift Transaction for Atomic Replace-All

```dart
// Source: drift.simonbinder.eu/dart_api/transactions/
Future<void> replaceAll(List<ShoppingListItemsCompanion> items, String userId) {
  return db.transaction(() async {
    // Step 1: delete auto-generated items only (preserve manual)
    await (db.delete(db.shoppingListItems)
          ..where((i) => i.userId.equals(userId))
          ..where((i) => i.isManual.equals(false)))
        .go();
    // Step 2: insert new items
    for (final item in items) {
      await db.into(db.shoppingListItems).insertOnConflictUpdate(item);
    }
  });
}
```

### AsyncNotifier Mutation Pattern

```dart
// Source: codewithandrea.com/articles/flutter-riverpod-async-notifier/ (Riverpod 3.x)
@riverpod
class ShoppingListNotifier extends _$ShoppingListNotifier {
  @override
  Future<void> build() async {}

  Future<void> toggleChecked(String id, bool current) async {
    // Write to Drift — StreamProvider re-emits automatically
    await ref.read(appDatabaseProvider).shoppingListDao.toggleChecked(id, current);
  }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `StreamBuilder` widget with direct Drift stream | `StreamProvider` + Riverpod `ref.watch()` | Riverpod 3.x (Oct 2025) | Lifecycle managed by Riverpod; no manual `StreamSubscription` management |
| `StateNotifier` for list mutations | `AsyncNotifier` with `@riverpod` codegen | Riverpod 3.0 (Oct 2025) | `StateNotifier` moved to `riverpod/legacy.dart`; use `AsyncNotifier` |
| `CheckboxListTile` with `setState` | `CheckboxListTile` writing to Drift (persisted) | Architecture requirement (SHOP-06) | App restarts must preserve check-off state — `setState` is always wrong for this |
| Ad-hoc unit conversion | Lookup table with base-unit aggregation | Best practice | Lookup table is exhaustively testable; ad-hoc conditionals accumulate bugs |

**Deprecated/outdated:**
- `StateNotifierProvider` from `riverpod`: Import is now `riverpod/legacy.dart` — do not use in new Phase 6 code
- Direct `StreamBuilder` consuming Drift streams without Riverpod: Works but loses Riverpod's caching, error handling, and lifecycle management

---

## Open Questions

1. **Current `schemaVersion` in AppDatabase**
   - What we know: Phase 1 defines `schemaVersion = 1`; Phase 4 adds `CachedRecipes` (requires increment to 2)
   - What's unclear: Whether Phase 4 was implemented and its migration was committed; exact current `schemaVersion`
   - Recommendation: At start of Phase 6, read `app_database.dart` and check the current `schemaVersion`. Phase 6 migration for `isManual` column must use the next available version number.

2. **Spoonacular unit strings not in the normalization table**
   - What we know: Spoonacular returns free-text unit strings; known values include `tbsp`, `cups`, `ounces`, `cloves`, `pinches`, `servings`, empty string; additional rare strings exist (head, stalk, sprig, bunch, fillet)
   - What's unclear: Complete set of unit strings that will actually appear in real recipe data
   - Recommendation: The normalization service in plan 06-01 should log unknown units to console in debug mode. After generating from a few recipes in plan 06-02 integration testing, any unknown units discovered should be added to the lookup table.

3. **Staleness detection for regeneration trigger**
   - What we know: SHOP-01 says the list "contains every ingredient from every recipe in the current meal plan" — implying it must be current
   - What's unclear: Exact trigger for regeneration (user taps a button? Automatic when meal plan changes? Both?)
   - Recommendation: For Phase 6, implement a "Regenerate" FAB on the shopping list screen. Automatic trigger (when meal plan changes) can be added as a Phase 8 enhancement. Log `lastGeneratedAt` in `SharedPreferences`.

---

## Sources

### Primary (HIGH confidence)
- [drift.simonbinder.eu/dart_api/daos/](https://drift.simonbinder.eu/dart_api/daos/) — DAO pattern, `@DriftAccessor`, `DatabaseAccessor`, mixin
- [drift.simonbinder.eu/dart_api/streams/](https://drift.simonbinder.eu/dart_api/streams/) — `.watch()` mechanism, table tracking, multi-table join streams, `readsFrom` for custom queries
- [drift.simonbinder.eu/dart_api/select/](https://drift.simonbinder.eu/dart_api/select/) — aggregate functions (sum, count), `addColumns()`, `groupBy()`
- [drift.simonbinder.eu/docs/advanced-features/joins/](https://drift.simonbinder.eu/docs/advanced-features/joins/) — inner join, `useColumns: false`, multi-table join pattern
- [drift.simonbinder.eu/migrations/](https://drift.simonbinder.eu/migrations/) — `addColumn()`, `schemaVersion`, migration strategy
- [riverpod.dev/docs/whats_new](https://riverpod.dev/docs/whats_new) — Riverpod 3.0 `AsyncNotifier`, mutation pattern, `Ref.mounted`
- [codewithandrea.com/articles/flutter-riverpod-async-notifier/](https://codewithandrea.com/articles/flutter-riverpod-async-notifier/) — `AsyncNotifier` CRUD pattern for repository-backed lists
- Phase 1 RESEARCH.md — `ShoppingListItems` table schema, Drift setup, `schemaVersion = 1`
- Phase 4 RESEARCH.md — `CachedRecipes` table schema, Spoonacular `extendedIngredients` structure with `amount` (double) and `unit` (string) fields

### Secondary (MEDIUM confidence)
- [pub.dev/packages/units_converter](https://pub.dev/packages/units_converter) — v3.1.0 capabilities: mass (kg/oz) and volume (L/cubic meters) but NOT culinary units (cups, tbsp, tsp) — confirms custom service is needed
- [deepwiki.com/h-enoki/sample_drift_app/5.1-state-management-with-riverpod](https://deepwiki.com/h-enoki/sample_drift_app/5.1-state-management-with-riverpod) — `StreamProvider` wrapping Drift `watchAll()` pattern, `.when()` consumption
- [spoonacular.com/food-api/docs](https://spoonacular.com/food-api/docs) — `extendedIngredients.unit` field: confirmed free-text strings include `tbsp`, `cups`, `cloves`, `pinches`, `servings`, empty string, `ounces`

### Tertiary (LOW confidence)
- WebSearch: unit normalization approaches for cooking ingredients — multiple sources confirm lookup-table approach with base unit per family is standard pattern; no single authoritative source
- WebSearch: Spoonacular complete unit string enumeration — no public complete list exists; community suggests 50+ variants; treat unknown units as count family as fallback

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all prior-phase packages verified
- Drift DAO + stream + aggregate patterns: HIGH — verified against drift.simonbinder.eu official docs
- Riverpod 3.x AsyncNotifier + StreamProvider patterns: HIGH — verified against riverpod.dev and codewithandrea.com
- Unit normalization service design: HIGH (approach), MEDIUM (completeness of unit table) — approach is correct; table may need extension as real recipe data is processed
- Shopping list UI patterns: HIGH — CheckboxListTile, ListView.builder are standard Flutter; Drift watch stream drives updates
- Pitfalls: HIGH for migration/transaction/cross-family — verified from Drift docs; MEDIUM for Spoonacular unit coverage — based on community reports

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (stable APIs; unit normalization table may need expansion after first real data run)
