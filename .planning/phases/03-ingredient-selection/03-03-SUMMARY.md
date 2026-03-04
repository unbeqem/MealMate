---
phase: 03-ingredient-selection
plan: 03
subsystem: ui
tags: [flutter, riverpod, drift, ingredient-selection, favorites, selected-today]

requires:
  - phase: 03-01
    provides: IngredientRepository with toggleFavorite, getFavorites, addSelectedToday, removeSelectedToday, getSelectedToday, clearSelectedToday
  - phase: 03-02
    provides: IngredientTile widget, IngredientMainScreen, IngredientSearchScreen, IngredientCategoryScreen tab shells

provides:
  - IngredientFavoritesProvider (AsyncNotifier, auto-dispose) with optimistic toggleFavorite
  - SelectedTodayNotifier (keepAlive, Map<String,String> id->name) with toggle(id, name:), addAll, clearAll, selectedIds, selectedNames, count
  - IngredientFavoritesScreen tab child with Add-all-to-today bulk action and shimmer loading
  - SelectedTodayBar expandable pill bar (AnimatedContainer, ConsumerStatefulWidget) with name chips
  - Quick-add favorites chips on IngredientSearchScreen (unselected favorites as ActionChip)
  - onSelectTap wired on all IngredientTile instances across search, category, favorites screens
  - selectedTodayProvider keepAlive with Map<String,String> — ready for Phase 4 recipe discovery

affects: [04-recipe-discovery, any feature reading ingredient selection state]

tech-stack:
  added: []
  patterns:
    - "keepAlive Riverpod provider for cross-navigation state (selectedTodayNotifier)"
    - "Map<String,String> state (id->name) to avoid async name lookups in pill bar"
    - "Optimistic UI update: state set before await, refreshed from source of truth after"
    - "ConsumerStatefulWidget for local UI state (expand/collapse) + global provider state"
    - "AnimatedContainer expand/collapse with 250ms easeInOut for pill bar"
    - "Batch addAll with single state update to avoid N widget rebuilds"

key-files:
  created:
    - meal_mate/lib/features/ingredients/presentation/providers/selected_today_provider.dart
    - meal_mate/lib/features/ingredients/presentation/providers/selected_today_provider.g.dart
    - meal_mate/test/features/ingredients/presentation/providers/selected_today_provider_test.dart
  modified:
    - meal_mate/lib/features/ingredients/presentation/widgets/selected_today_bar.dart
    - meal_mate/lib/features/ingredients/presentation/screens/ingredient_favorites_screen.dart
    - meal_mate/lib/features/ingredients/presentation/screens/ingredient_search_screen.dart
    - meal_mate/lib/features/ingredients/presentation/screens/ingredient_category_screen.dart
    - meal_mate/lib/features/ingredients/presentation/screens/ingredient_main_screen.dart

key-decisions:
  - "SelectedTodayNotifier state is Map<String,String> (not Set<String>) so pill bar can display names without async lookups"
  - "toggle() requires {name:} named param — name provided at call site where Ingredient object is available"
  - "SelectedTodayBar is ConsumerStatefulWidget (not ConsumerWidget) to hold _expanded bool locally"
  - "SelectedTodayBar lives in IngredientMainScreen body Column (outside TabBarView) and separately in IngredientCategoryScreen"
  - "/ingredients/favorites standalone route omitted — screen is a tab child with no own Scaffold, consistent with locked decision from 03-02"
  - "Quick-add favorites chips filtered to unselected-only: once added they disappear from chip row"

patterns-established:
  - "Map<String,String> for selection state where names needed downstream"
  - "keepAlive provider for inter-phase data sharing (recipe discovery reads selectedTodayProvider)"
  - "Pill bar widget as ConsumerStatefulWidget for expand state + provider watch"

requirements-completed: [INGR-03, INGR-05]

duration: 18min
completed: 2026-03-04
---

# Phase 03 Plan 03: Favorites, Selected-Today Bar, and Quick-Add Chips Summary

**Riverpod keepAlive Map provider for selected-today ingredients (id->name) with expandable AnimatedContainer pill bar, favorites bulk-add, and quick-add chip row**

## Performance

- **Duration:** 18 min
- **Started:** 2026-03-04T09:20:00Z
- **Completed:** 2026-03-04T09:38:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- `SelectedTodayNotifier` upgraded from `Set<String>` to `Map<String, String>` (id->name) — state now carries display names so the pill bar shows ingredient chips without additional async repository calls
- `SelectedTodayBar` rebuilt as expandable `ConsumerStatefulWidget` with `AnimatedContainer`: collapsed shows count + first 3 name chips + Find Recipes CTA; expanded shows full deletable chip list with Clear all
- `IngredientFavoritesScreen` gained "Add all to today" `ElevatedButton.icon` at top — calls `addAll()` for a single state update instead of N individual toggles
- `IngredientSearchScreen` has quick-add favorites chips above the search field — `ActionChip` row showing only unselected favorites, one-tap add
- All `onSelectTap` calls across search, category, and favorites screens updated to pass `name:` parameter
- `SelectedTodayBar` integrated into `IngredientMainScreen` body Column (shared across both tabs) and separately into `IngredientCategoryScreen`
- 10 provider tests pass covering: toggle add/remove with name, addAll batch-add, addAll skips duplicates, clearAll, count, selectedIds, selectedNames, null-user guard

## Task Commits

1. **Task 1: Favorites provider, selected-today Map provider, and tests** - `56c45cf` (feat + test, TDD)
2. **Task 2: Favorites screen, expandable bar, quick-add chips, wiring** - `de4e740` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `meal_mate/lib/features/ingredients/presentation/providers/selected_today_provider.dart` - keepAlive notifier, Map<String,String> state, toggle/addAll/clearAll/selectedNames
- `meal_mate/lib/features/ingredients/presentation/providers/selected_today_provider.g.dart` - hand-crafted generated code for Map<String,String> type
- `meal_mate/test/features/ingredients/presentation/providers/selected_today_provider_test.dart` - 10 tests covering all notifier methods
- `meal_mate/lib/features/ingredients/presentation/widgets/selected_today_bar.dart` - expandable AnimatedContainer pill bar (was flat count row)
- `meal_mate/lib/features/ingredients/presentation/screens/ingredient_favorites_screen.dart` - "Add all to today" button, Map-based isSelected, name: in toggle()
- `meal_mate/lib/features/ingredients/presentation/screens/ingredient_search_screen.dart` - quick-add favorites chips, name: in toggle()
- `meal_mate/lib/features/ingredients/presentation/screens/ingredient_category_screen.dart` - SelectedTodayBar added, name: in toggle()
- `meal_mate/lib/features/ingredients/presentation/screens/ingredient_main_screen.dart` - SelectedTodayBar in body Column outside TabBarView

## Decisions Made

- `Map<String, String>` state (not `Set<String>`) chosen because the expandable pill bar needs ingredient names for chips — building names at toggle time avoids async lookups during render
- `toggle()` requires `{required String name}` param so callers pass name at the point they have the `Ingredient` object — no extra repository reads
- `SelectedTodayBar` is `ConsumerStatefulWidget` to hold `_expanded` bool locally while watching the global provider
- `/ingredients/favorites` standalone route omitted per locked decision from Plan 03-02 (`IngredientFavoritesScreen` has no own Scaffold — standalone access would crash)
- `SelectedTodayBar` placed in `IngredientMainScreen` Column body outside `TabBarView` so expand/collapse state persists across tab switches

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `valueOrNull` not available in Riverpod 3.x — replaced with `.value`**
- **Found during:** Task 1 (provider implementation)
- **Issue:** Plan's code scaffolding used `state.valueOrNull` which doesn't exist in Riverpod 3.x (3.2.1). Correct getter is `state.value` (returns `T?`)
- **Fix:** Replaced all `state.valueOrNull` with `state.value` in `selected_today_provider.dart`
- **Files modified:** `selected_today_provider.dart`
- **Verification:** `flutter test` passes — 10/10 tests green
- **Committed in:** `56c45cf` (Task 1 commit)

**2. [Scope - Omission] `/ingredients/favorites` standalone route not added**
- **Found during:** Task 2 (router wiring)
- **Reason:** Pre-existing locked decision in STATE.md: "/ingredients/favorites removed as standalone route — Favorites is now Tab 1 of IngredientMainScreen". `IngredientFavoritesScreen` has no own `Scaffold` so a standalone route would render without AppBar/navigation context.
- **Impact:** No functional impact. Favorites is accessible via Tab 1 at `/ingredients`. A deep-link route would require wrapping in a Scaffold or converting to standalone first.
- **Deferred to:** Phase future if deep-linking to favorites tab is required

---

**Total deviations:** 1 auto-fixed (Riverpod API), 1 planned omission (standalone route)
**Impact on plan:** API fix essential for compilation. Route omission consistent with locked architectural decision.

## Issues Encountered

- Riverpod 3.2.1 uses `.value` (nullable) not `.valueOrNull` — plan code scaffolding referenced a Riverpod 2.x API. Fixed immediately (Rule 1).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `selectedTodayProvider` is `keepAlive` and stores `Map<String, String>` — Phase 4 recipe discovery can read `selectedNames` or `selectedIds` directly from this provider
- `Find Recipes` CTA in `SelectedTodayBar` routes to `/recipes` — Phase 4 must register this route
- No outstanding blockers for Phase 4 ingredient-based recipe filtering

---
*Phase: 03-ingredient-selection*
*Completed: 2026-03-04*

## Self-Check: PASSED

- FOUND: `meal_mate/lib/features/ingredients/presentation/providers/selected_today_provider.dart`
- FOUND: `meal_mate/lib/features/ingredients/presentation/widgets/selected_today_bar.dart`
- FOUND: `meal_mate/lib/features/ingredients/presentation/screens/ingredient_favorites_screen.dart`
- FOUND: `meal_mate/test/features/ingredients/presentation/providers/selected_today_provider_test.dart`
- FOUND: commit `56c45cf` (Task 1 — providers and tests)
- FOUND: commit `de4e740` (Task 2 — UI screens and widgets)
