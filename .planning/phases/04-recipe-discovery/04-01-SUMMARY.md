---
phase: 04-recipe-discovery
plan: 01
subsystem: api
tags: [spoonacular, drift, freezed, riverpod, edge-function, deno, typescript, recipe-cache]

requires:
  - phase: 01-foundation
    provides: AppDatabase with Drift setup, supabase_flutter client
  - phase: 03-ingredient-selection
    provides: appDatabaseProvider (keepAlive), ingredient domain models

provides:
  - Freezed domain models: Recipe, ExtendedIngredient, AnalyzedInstruction, InstructionStep, RecipeSearchResult, RecipeSummary
  - CachedRecipes Drift table with 24-hour TTL cache-first reads (Spoonacular integer ID as PK)
  - RecipeCacheDao with getById, isFresh, upsert, getSummaryPage
  - SpoonacularClient routing complexSearch, getRecipeInformation, findByIngredients through Edge Function proxy
  - QuotaExhaustedException for Spoonacular 402 responses
  - RecipeRepository with cache-first detail reads, search caching, ingredient-based discovery
  - Supabase Edge Function (Deno/TypeScript) proxying Spoonacular requests with server-side API key injection
  - Riverpod providers: spoonacularClientProvider, recipeRepositoryProvider
  - 8 repository unit tests (mocktail mocks + in-memory Drift integration test)

affects:
  - 04-02-recipe-browse — depends on recipeRepositoryProvider and RecipeSearchResult
  - 04-03-recipe-detail — depends on recipeRepositoryProvider and Recipe model
  - 05-meal-planning — depends on Recipe domain model

tech-stack:
  added:
    - supabase/functions/spoonacular-proxy/index.ts (Deno Edge Function — new runtime)
  patterns:
    - Cache-first reads: check Drift TTL before hitting API; upsert on miss
    - Edge Function proxy: all external API calls go through supabase.functions.invoke, never direct from Flutter
    - Freezed sealed classes: sealed class syntax with @Default([]) list fields
    - Drift integer PK: CachedRecipes uses Spoonacular integer ID (not UUID) as PK
    - Mocktail + NativeDatabase.memory(): test pattern for repository unit tests

key-files:
  created:
    - meal_mate/lib/features/recipes/domain/recipe.dart
    - meal_mate/lib/features/recipes/domain/extended_ingredient.dart
    - meal_mate/lib/features/recipes/domain/analyzed_instruction.dart
    - meal_mate/lib/features/recipes/domain/recipe_search_result.dart
    - meal_mate/lib/core/database/tables/cached_recipes_table.dart
    - meal_mate/lib/features/recipes/data/recipe_cache_dao.dart
    - meal_mate/lib/features/recipes/data/spoonacular_client.dart
    - meal_mate/lib/features/recipes/data/recipe_repository.dart
    - supabase/functions/spoonacular-proxy/index.ts
    - meal_mate/test/features/recipes/data/recipe_repository_test.dart
  modified:
    - meal_mate/lib/core/database/app_database.dart (added CachedRecipes table + RecipeCacheDao, schemaVersion 2→3)

key-decisions:
  - "CachedRecipes uses Spoonacular integer recipe ID as primary key (not UUID) — external IDs are stable and don't collide"
  - "AppDatabase schemaVersion incremented to 3 with from<3 createTable(cachedRecipes) migration for existing users"
  - "RecipeCacheDao registered in @DriftDatabase daos list so AppDatabase exposes a typed dao accessor"
  - "RecipeRepository hides Drift Recipe class (from sync Recipes table) via 'hide Recipe' import alias to avoid ambiguity with Freezed Recipe domain model"
  - "SpoonacularClient uses supabase.functions.invoke exclusively — no direct Spoonacular URL in Flutter bundle"
  - "QuotaExhaustedException thrown on HTTP 402 from Edge Function — callers can show user-friendly message"
  - "isSummaryOnly=true for complexSearch and findByIngredients results; false only after getRecipeInformation fetches full detail"
  - "Edge Function passes upstream Spoonacular status faithfully — 402 reaches Flutter client as QuotaExhaustedException"

patterns-established:
  - "Pattern: Edge Function proxy — supabase.functions.invoke('spoonacular-proxy', body: {path, params}) for all Spoonacular calls"
  - "Pattern: Cache-first repository — getById -> isFresh && !isSummaryOnly -> return cached; else fetch -> upsert -> return"
  - "Pattern: Test fallback registration — registerFallbackValue(_buildCachedRecipe()) in setUpAll when using any() with Drift data classes"
  - "Pattern: Import disambiguation — 'hide Recipe' on app_database.dart import when Drift table name collides with domain model"

requirements-completed: [RECP-01, RECP-02, RECP-04]

duration: 7min
completed: 2026-03-05
---

# Phase 4 Plan 01: Recipe Data Layer Summary

**Freezed recipe domain models + Spoonacular Edge Function proxy + Drift cache table (24h TTL) + RecipeRepository with cache-first reads + 8 passing unit tests**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-05T20:10:15Z
- **Completed:** 2026-03-05T20:16:50Z
- **Tasks:** 2
- **Files modified:** 21 (17 created, 4 modified including generated files)

## Accomplishments

- Freezed sealed class domain models (Recipe, ExtendedIngredient, AnalyzedInstruction, InstructionStep, RecipeSearchResult, RecipeSummary) with `fromJson`/`toJson` and `@Default([])` list fields
- Supabase Deno Edge Function that injects `SPOONACULAR_API_KEY` server-side and proxies GET requests to Spoonacular — API key never appears in Flutter bundle
- Drift `CachedRecipes` table with integer PK, 24-hour TTL cache-first pattern via `RecipeCacheDao`, schema migration from version 2 to 3
- `RecipeRepository` with `getRecipeDetail` (cache-first), `searchRecipes` (cache summaries), `findByIngredients` (cache summaries); `QuotaExhaustedException` on 402
- 8 repository unit tests covering cache hit, stale, miss, summary-only refresh, search caching, ingredient join, and integration with real in-memory Drift DB — all passing

## Task Commits

Each task was committed atomically:

1. **Task 1: Freezed domain models and Drift cache table** - `8c918e7` (feat)
2. **Task 2: SpoonacularClient, Edge Function proxy, RecipeRepository, and tests** - `51eca58` (feat)

**Plan metadata:** (to be committed with docs commit)

## Files Created/Modified

- `meal_mate/lib/features/recipes/domain/recipe.dart` - Freezed Recipe with extendedIngredients, analyzedInstructions, isSummaryOnly
- `meal_mate/lib/features/recipes/domain/extended_ingredient.dart` - Freezed ExtendedIngredient with id, name, amount, unit, original
- `meal_mate/lib/features/recipes/domain/analyzed_instruction.dart` - Freezed AnalyzedInstruction + InstructionStep
- `meal_mate/lib/features/recipes/domain/recipe_search_result.dart` - Freezed RecipeSearchResult + RecipeSummary
- `meal_mate/lib/core/database/tables/cached_recipes_table.dart` - Drift CachedRecipes table definition (integer PK)
- `meal_mate/lib/core/database/app_database.dart` - Added CachedRecipes table, RecipeCacheDao, schemaVersion 3, migration
- `meal_mate/lib/features/recipes/data/recipe_cache_dao.dart` - @DriftAccessor with getById, isFresh, upsert, getSummaryPage
- `meal_mate/lib/features/recipes/data/spoonacular_client.dart` - SpoonacularClient with 3 methods + QuotaExhaustedException
- `meal_mate/lib/features/recipes/data/recipe_repository.dart` - RecipeRepository + Riverpod providers
- `supabase/functions/spoonacular-proxy/index.ts` - Deno Edge Function proxying Spoonacular with server-side API key
- `meal_mate/test/features/recipes/data/recipe_repository_test.dart` - 8 unit tests (mocktail + in-memory Drift)

## Decisions Made

- **CachedRecipes uses integer PK:** Spoonacular recipe IDs are stable external integers — no UUID needed, and integer PK enables direct equality queries without UUID generation overhead.
- **schemaVersion 2 → 3 with migration:** Existing installs that ran Phase 1-3 will not lose data; `from < 3` branch adds the new table on upgrade.
- **RecipeCacheDao in @DriftDatabase daos list:** Makes the DAO accessible as `db.recipeCacheDao` from the generated `AppDatabase` while keeping it in a separate file.
- **`hide Recipe` import alias:** The Drift-generated `Recipe` class (from the `Recipes` sync table) clashes with the domain `Recipe` Freezed model. Hiding it on the app_database import is the minimal fix.
- **QuotaExhaustedException on 402:** Named exception enables callers to display "try again tomorrow" rather than a generic error.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added `registerFallbackValue` for CachedRecipe in test setUpAll**
- **Found during:** Task 2 (test execution)
- **Issue:** Mocktail requires `registerFallbackValue` for any custom type used with `any()` matcher; tests failed with `Bad state` error
- **Fix:** Added `setUpAll { registerFallbackValue(_buildCachedRecipe(...)) }` to test file
- **Files modified:** `meal_mate/test/features/recipes/data/recipe_repository_test.dart`
- **Verification:** All 8 tests pass
- **Committed in:** `51eca58`

**2. [Rule 1 - Bug] Used `hide Recipe` to resolve ambiguous import**
- **Found during:** Task 2 (dart analyze)
- **Issue:** `Recipe` defined in both `app_database.dart` (Drift sync table) and `recipe.dart` (domain model) caused 4 analyzer errors
- **Fix:** Added `hide Recipe` to the `app_database.dart` import in `recipe_repository.dart`
- **Files modified:** `meal_mate/lib/features/recipes/data/recipe_repository.dart`
- **Verification:** `dart analyze lib/features/recipes/` exits 0 with no errors
- **Committed in:** `51eca58`

---

**Total deviations:** 2 auto-fixed (both Rule 1 bugs discovered during verification)
**Impact on plan:** Both required for tests to pass and code to compile. No scope creep.

## Issues Encountered

None beyond the two auto-fixed bugs above.

## User Setup Required

**External service requires configuration:** The `spoonacular-proxy` Edge Function reads `SPOONACULAR_API_KEY` from `Deno.env.get()`. Before deploying:

1. Go to Supabase Dashboard → Project Settings → Edge Functions → Secrets
2. Add secret: `SPOONACULAR_API_KEY = <your-key>` (from spoonacular.com account)
3. Deploy the function: `supabase functions deploy spoonacular-proxy`

No Flutter-side configuration needed — the key never appears in the app bundle.

## Next Phase Readiness

- Recipe data layer complete — all domain models, cache, client, and repository are production-ready
- 04-02 (recipe browse screen) can import `recipeRepositoryProvider` and `RecipeSearchResult` immediately
- 04-03 (recipe detail screen) can use `recipeRepositoryProvider.getRecipeDetail()` and the `Recipe` model
- The `CachedRecipes` table migration is in place — no schema changes needed in subsequent plans

---
*Phase: 04-recipe-discovery*
*Completed: 2026-03-05*
