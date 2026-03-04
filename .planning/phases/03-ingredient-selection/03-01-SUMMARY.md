---
phase: 03-ingredient-selection
plan: 01
subsystem: database
tags: [drift, openfoodfacts, riverpod, freezed, sqlite, pull-through-cache]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: Drift AppDatabase with UUID-PK Ingredients table (schemaVersion 1)
  - phase: 02-authentication-onboarding
    provides: AuthRepository and authStateProvider for userId context
provides:
  - Freezed Ingredient domain model with dietary flags (vegan, vegetarian, gluten-free, dairy-free)
  - Freezed IngredientFilter model with DietaryRestriction enum
  - OpenFoodFacts SDK configured with MealMate User-Agent
  - Drift schema migrated to v2 — isFavorite, dietaryFlags (JSON), cachedAt on ingredients; SelectedTodayIngredients table
  - OpenFoodFactsRemoteSource wrapping getSuggestions and searchByCategory with dietary flag parsing
  - IngredientLocalSource with full Drift CRUD, dietary filtering, alphabetical ordering, and no-date-scoped selected-today
  - IngredientRepository as pull-through cache — presentation never calls OFf or Drift directly
  - appDatabaseProvider (keepAlive: true) and ingredientRepositoryProvider shared by Wave 2 plans
  - 12-entry ingredientCategories map including Baking and Nuts & Seeds
affects:
  - 03-02-ingredient-search (consumes ingredientRepositoryProvider and searchSuggestions)
  - 03-03-ingredient-browse (consumes watchIngredientsByCategory and ingredientCategories)

# Tech tracking
tech-stack:
  added:
    - openfoodfacts (OFf SDK — getSuggestions, searchProducts, ProductSearchQueryConfiguration)
    - mocktail (test mocking for OpenFoodFactsRemoteSource)
  patterns:
    - Pull-through cache via Stream — emit cached Drift data first, fetch OFf remote, upsert, re-emit
    - Optimistic local write — toggleFavorite flips flag in Drift and sets syncStatus='pending' before sync
    - JSON-encoded list column — dietaryFlags stored as '["vegan","gluten-free"]' in text column
    - Shared keepAlive provider — appDatabaseProvider survives navigation; consumed by multiple Wave 2 plans

key-files:
  created:
    - meal_mate/lib/features/ingredients/domain/ingredient.dart
    - meal_mate/lib/features/ingredients/domain/ingredient_filter.dart
    - meal_mate/lib/core/config/openfoodfacts_config.dart
    - meal_mate/lib/core/database/tables/selected_today_table.dart
    - meal_mate/lib/features/ingredients/data/openfoodfacts_remote_source.dart
    - meal_mate/lib/features/ingredients/data/ingredient_local_source.dart
    - meal_mate/lib/features/ingredients/data/ingredient_repository.dart
    - meal_mate/lib/features/ingredients/data/ingredient_repository_provider.dart
    - meal_mate/test/features/ingredients/data/ingredient_repository_test.dart
  modified:
    - meal_mate/lib/core/database/tables/ingredients_table.dart (added isFavorite, dietaryFlags, cachedAt)
    - meal_mate/lib/core/database/app_database.dart (schemaVersion 2, migration, SelectedTodayIngredients added)
    - meal_mate/lib/main.dart (configureOpenFoodFacts() called before runApp)

key-decisions:
  - "selectedToday has NO date filter — getSelectedToday and clearSelectedToday operate on all rows for userId (persist until manual clear)"
  - "ingredientCategories has exactly 12 entries including Baking and Nuts & Seeds per locked decision"
  - "Category results sorted alphabetically by name (ORDER BY name ASC in local source, sort() in remote source)"
  - "dietaryFlags stored as JSON-encoded text column in Drift (not as separate table) for query simplicity"
  - "appDatabaseProvider uses keepAlive: true so db connection survives navigation across Phase 3 screens"

patterns-established:
  - "Pull-through cache: local first emit -> remote fetch -> upsert -> second emit (watchIngredientsByCategory)"
  - "Remote source wrapper: all OFf SDK calls encapsulated in OpenFoodFactsRemoteSource, never called directly from repository or presentation"
  - "Selected-today persistence: Drift SelectedTodayIngredients table with audit timestamp but no date filter"
  - "Dietary flag parsing: ingredientsAnalysisTags for vegan/vegetarian, labelsTags for gluten-free/dairy-free"

requirements-completed: [INGR-01, INGR-02, INGR-04]

# Metrics
duration: 15min
completed: 2026-03-04
---

# Phase 3 Plan 01: Ingredient Data Layer Summary

**OpenFoodFacts pull-through cache with Drift schema v2 — Freezed domain models, 12-category remote source with dietary flag parsing, and no-date-scoped selected-today persistence via IngredientRepository**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-04T09:01:47Z
- **Completed:** 2026-03-04T09:20:00Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Freezed Ingredient and IngredientFilter domain models compile and generate correctly
- OpenFoodFacts SDK initialized with MealMate User-Agent before runApp; 12-entry category map with Baking and Nuts & Seeds
- Drift schema migrated from v1 to v2 with isFavorite, dietaryFlags (JSON), cachedAt on ingredients table and new SelectedTodayIngredients table
- IngredientRepository implements pull-through cache: emits cached Drift data first, fetches OFf remote, upserts, re-emits
- Selected-today operates with NO date filter — selections persist until user manually calls clearSelectedToday
- All 11 repository tests pass using in-memory NativeDatabase and mocktail mocks

## Task Commits

Each task was committed atomically:

1. **Task 1: Domain models, OFf configuration, and Drift schema extension** - `9aa1f05` (feat)
2. **Task 2: Remote source, local source, and IngredientRepository with pull-through cache** - `6734f2c` (test) + `12f45fa` (feat)
3. **Fix: Locked-decision violations corrected** - `b14e22a` (fix)

## Files Created/Modified

- `meal_mate/lib/features/ingredients/domain/ingredient.dart` - Freezed Ingredient model with id, name, category, isFavorite, dietaryFlags, cachedAt
- `meal_mate/lib/features/ingredients/domain/ingredient_filter.dart` - Freezed IngredientFilter with DietaryRestriction enum
- `meal_mate/lib/core/config/openfoodfacts_config.dart` - configureOpenFoodFacts() sets UserAgent, language, country
- `meal_mate/lib/core/database/tables/ingredients_table.dart` - Added isFavorite, dietaryFlags (nullable text), cachedAt columns
- `meal_mate/lib/core/database/tables/selected_today_table.dart` - SelectedTodayIngredients table (id, ingredientId, selectedDate audit, userId)
- `meal_mate/lib/core/database/app_database.dart` - schemaVersion 2, migration adds new columns and creates selected_today_ingredients table
- `meal_mate/lib/main.dart` - Added configureOpenFoodFacts() call after Supabase.initialize()
- `meal_mate/lib/features/ingredients/data/openfoodfacts_remote_source.dart` - OFf API wrapper with 12-category map, getSuggestions, searchByCategory, dietary flag parsing, alphabetical sort
- `meal_mate/lib/features/ingredients/data/ingredient_local_source.dart` - Drift queries: CRUD, category filter (ORDER BY name ASC), dietary LIKE filter, selected-today with no date scope
- `meal_mate/lib/features/ingredients/data/ingredient_repository.dart` - Pull-through cache repository, single source of truth for presentation
- `meal_mate/lib/features/ingredients/data/ingredient_repository_provider.dart` - appDatabaseProvider (keepAlive) and ingredientRepositoryProvider for Wave 2 consumers
- `meal_mate/test/features/ingredients/data/ingredient_repository_test.dart` - 11 tests covering suggestions, favorite toggle, selected-today round-trip, dietary filtering

## Decisions Made

- Selected-today persistence uses NO date filter — the `selectedDate` column is audit-only; `getSelectedToday` and `clearSelectedToday` filter only by `userId`. This matches the locked plan decision that selections persist until manually cleared.
- 12 ingredient categories enforced including Baking (`en:baking-preparations`) and Nuts & Seeds (`en:nuts-and-their-products`) per locked decision.
- Alphabetical sorting enforced at both layers: `ORDER BY name ASC` in `IngredientLocalSource.getIngredientsByCategory` and `.sort()` in `OpenFoodFactsRemoteSource.searchByCategory`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ingredientCategories was missing Baking and Nuts & Seeds (10 entries instead of 12)**
- **Found during:** Post-commit review against plan must_haves
- **Issue:** Remote source was initialized with 10 categories, violating the locked decision requiring exactly 12 including Baking and Nuts & Seeds
- **Fix:** Added `'Baking': 'en:baking-preparations'` and `'Nuts & Seeds': 'en:nuts-and-their-products'` to the constant map
- **Files modified:** `meal_mate/lib/features/ingredients/data/openfoodfacts_remote_source.dart`
- **Verification:** Count verified as 12; all tests still pass
- **Committed in:** `b14e22a`

**2. [Rule 1 - Bug] getSelectedToday, clearSelectedToday, removeSelectedToday incorrectly date-filtered**
- **Found during:** Post-commit review against plan locked decisions
- **Issue:** All three methods filtered by today's date range, causing selections to be lost at midnight — violated the locked decision that selections persist until manual clear
- **Fix:** Removed date filtering from all three methods; `getSelectedToday` now returns all rows WHERE userId matches; `clearSelectedToday` deletes all rows for userId; `selectedDate` column retained as audit-only timestamp
- **Files modified:** `meal_mate/lib/features/ingredients/data/ingredient_local_source.dart`
- **Verification:** All 11 tests pass; clearSelectedToday user-isolation test confirms correct scoping
- **Committed in:** `b14e22a`

**3. [Rule 1 - Bug] getIngredientsByCategory lacked alphabetical ordering**
- **Found during:** Review of locked decisions (alphabetical sort within category)
- **Issue:** Local source returned rows in insertion order, not alphabetically
- **Fix:** Added `..orderBy([(t) => OrderingTerm.asc(t.name)])` to the Drift query
- **Files modified:** `meal_mate/lib/features/ingredients/data/ingredient_local_source.dart`
- **Verification:** Tests pass; ORDER BY verified in code
- **Committed in:** `b14e22a`

---

**Total deviations:** 3 auto-fixed (all Rule 1 — locked decision violations corrected)
**Impact on plan:** All fixes necessary for plan correctness. No scope creep.

## Issues Encountered

The previous session had committed Task 1 and Task 2 but the implementation did not fully comply with the plan's locked decisions (12-category map, no date filtering, alphabetical sort). These were caught during review and fixed atomically in a single fix commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `appDatabaseProvider` and `ingredientRepositoryProvider` are exported and ready for Wave 2 plans (03-02 and 03-03) to consume
- `ingredientCategories` map is exported from `openfoodfacts_remote_source.dart` for use in category browse UI
- All 11 repository tests pass; data layer contract is stable
- No blockers for Wave 2 parallel execution

---
*Phase: 03-ingredient-selection*
*Completed: 2026-03-04*
