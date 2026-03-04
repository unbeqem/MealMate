---
phase: 03-ingredient-selection
plan: 04
subsystem: ui
tags: [flutter, riverpod, drift, openfoodfacts, ingredients]

# Dependency graph
requires:
  - phase: 03-ingredient-selection
    provides: ingredient data layer, category provider, favorites provider, search screen, favorites screen, selected-today bar

provides:
  - Category screen passes display name directly to provider (not pre-translated OFf tag)
  - Pull-to-refresh available in all states (loading, error, empty, data) on category screen
  - toggleFavorite upserts minimal Ingredient row when ingredient not yet in Drift
  - Favorites provider appends new favorites optimistically instead of silently skipping
  - Search screen tiles reflect correct isFavorite state from favorites provider

affects:
  - 04-recipe-discovery
  - any phase using ingredientFavoritesProvider or toggleFavorite

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Lift RefreshIndicator outside .when() — wrap all AsyncValue states with scrollable physics"
    - "Upsert-before-toggle pattern — create minimal domain row before mutating it"
    - "Optimistic append for new list items — append to state before async persist, then sync from source of truth"

key-files:
  created: []
  modified:
    - meal_mate/lib/features/ingredients/presentation/screens/ingredient_category_screen.dart
    - meal_mate/lib/features/ingredients/data/ingredient_repository.dart
    - meal_mate/lib/features/ingredients/presentation/providers/ingredient_favorites_provider.dart
    - meal_mate/lib/features/ingredients/presentation/screens/ingredient_search_screen.dart

key-decisions:
  - "Category screen must pass display name (not OFf tag) to ingredientsByCategoryProvider — repository owns the display-name-to-tag translation"
  - "toggleFavorite name: param added to repository and provider — callers must provide name at call site so Drift row has a display name"

patterns-established:
  - "RefreshIndicator must wrap all .when() branches — error and empty states need ListView with AlwaysScrollableScrollPhysics"
  - "Upsert-before-toggle: any toggle on a domain object must ensure the row exists in local DB first"

requirements-completed: [INGR-02, INGR-03]

# Metrics
duration: 15min
completed: 2026-03-04
---

# Phase 3 Plan 04: Category browse and favorite toggle root-cause fixes

**Double-translation bug eliminated, upsert-before-toggle for non-Drift ingredients, and pull-to-refresh in all category screen states**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-04T10:20:00Z
- **Completed:** 2026-03-04T10:35:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Fixed category screen double-translation: removed pre-lookup of OFf tag in the screen, now passes display name directly so `ingredientsByCategoryProvider` → `watchIngredientsByCategory` → `_getCategoryTag` works correctly
- Fixed pull-to-refresh: lifted `RefreshIndicator` outside `.when()` so loading, error, and empty states are all scrollable and support pull gesture
- Fixed favorite toggle no-op: repository now upserts a minimal `Ingredient` row if the ingredient doesn't exist in Drift, ensuring the toggle always succeeds
- Fixed optimistic update for new favorites: provider now appends new favorites to state instead of silently returning the unchanged list
- Fixed search tile isFavorite display: tiles now receive correct `isFavorite` state by checking favorites set at render time

## Task Commits

1. **Task 1: Fix category double-translation bug and pull-to-refresh** - `bb51995` (fix)
2. **Task 2: Fix toggleFavorite upsert and wire isFavorite to search tiles** - `36f63bb` (fix)

## Files Created/Modified

- `meal_mate/lib/features/ingredients/presentation/screens/ingredient_category_screen.dart` - Removed pre-translation, lifted RefreshIndicator, wrapped error/empty in scrollable ListView
- `meal_mate/lib/features/ingredients/data/ingredient_repository.dart` - toggleFavorite now upserts minimal row when ingredient absent; added `name:` param
- `meal_mate/lib/features/ingredients/presentation/providers/ingredient_favorites_provider.dart` - Optimistic append for new favorites; toggleFavorite accepts `name:` param
- `meal_mate/lib/features/ingredients/presentation/screens/ingredient_search_screen.dart` - Passes `name:` param to toggleFavorite; computes isFavorite per tile from favorites set

## Decisions Made

- Category screen must not pre-translate display names — the repository layer owns the display-name-to-OFf-tag mapping via `_getCategoryTag`. Screens pass display names through.
- `toggleFavorite` gains a `name:` optional parameter at both the repository and provider layer. Callers must provide the display name at call sites where they have the ingredient name available.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Pass `name:` param in category screen's onFavoriteTap**
- **Found during:** Task 2 (wiring toggleFavorite)
- **Issue:** After adding `name:` param to the provider's toggleFavorite, the category screen call site needed updating too for consistency and safety
- **Fix:** Updated `onFavoriteTap` in `ingredient_category_screen.dart` to pass `name: ingredient.name`
- **Files modified:** meal_mate/lib/features/ingredients/presentation/screens/ingredient_category_screen.dart
- **Verification:** flutter analyze — no errors
- **Committed in:** 36f63bb (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug)
**Impact on plan:** One-line fix needed at a call site not listed in Task 2 scope. No scope creep.

## Issues Encountered

The search screen file had already been partially updated by a linter/formatter between reads. The final state was confirmed to be correct after reading it fresh.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Category browse now correctly loads ingredients from the OFf API
- Favoriting from search results correctly persists to Drift and appears in the Favorites tab
- Quick-add chips and "Add all to today" button are unblocked (they are behind `isNotEmpty` guards that now trigger correctly)
- Pull-to-refresh works in all states on category screen
- Phase 4 (recipe discovery) can rely on a working favorites list for ingredient context

---
*Phase: 03-ingredient-selection*
*Completed: 2026-03-04*
