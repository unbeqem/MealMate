---
phase: 03-ingredient-selection
verified: 2026-03-04T11:00:00Z
status: passed
score: 28/28 must-haves verified
re_verification: true
  previous_status: passed
  previous_score: 22/22
  gaps_closed:
    - "Gap 2: Category screen no longer pre-translates display name to OFf tag"
    - "Gap 5: toggleFavorite upserts minimal Ingredient row before toggling"
    - "Gap 9: RefreshIndicator wraps all async states on category screen"
    - "Gap 1: Local commonIngredients check before debounce Timer (fast path)"
    - "Gap 3: Search screen watches ingredientFilterProvider and filters results"
    - "Gap 4: Search tiles enriched with dietary badge data from favorites cache"
  gaps_remaining: []
  regressions: []
---

# Phase 3: Ingredient Selection — Re-Verification Report

**Phase Goal:** Users can find any ingredient they want to cook with — by searching, browsing categories, or filtering by dietary restriction — and build a personal favorites list for quick reuse.
**Verified:** 2026-03-04T11:00:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure plans 03-04 and 03-05

---

## Re-Verification Focus

Plans 03-04 and 03-05 closed 6 UAT-diagnosed gaps. Each gap is verified below in full (exists + substantive + wired). The 22 previously-passing truths are regression-checked at existence + basic sanity level.

---

## Gap Closure Verification

### Gap 2: Category screen no longer pre-translates display name to OFf tag

**Claim:** Category screen passes display name directly to `ingredientsByCategoryProvider(categoryName)`; repository's `_getCategoryTag` owns the display-name-to-OFf-tag lookup.

**Verification:**

- `ingredient_category_screen.dart:31-32` — `ref.watch(ingredientsByCategoryProvider(categoryName))` where `categoryName` is the raw route param string (e.g. `"Produce"`). No lookup against `ingredientCategories` map in the screen.
- `ingredient_repository.dart:34` — `_getCategoryTag(category)` is called inside `watchIngredientsByCategory`, which maps `"Produce"` -> `"en:fruits-and-vegetables"` via `ingredientCategories[displayName]`.
- `ingredient_repository.dart:100-104` — `_getCategoryTag` imports and uses `ingredientCategories` from `openfoodfacts_remote_source.dart` as a const map lookup.

**Status: VERIFIED** — Double-translation eliminated. Screen -> provider -> repository -> OFf tag is a single translation path.

---

### Gap 5: toggleFavorite upserts minimal Ingredient row before toggling

**Claim:** `IngredientRepository.toggleFavorite` checks whether the ingredient exists in Drift first; if absent, creates a minimal row before calling the toggle.

**Verification:**

- `ingredient_repository.dart:57-76` — `toggleFavorite(String ingredientId, {String userId = '', String name = ''})` calls `_local.getIngredient(ingredientId)`. If result is `null`, constructs `Ingredient(id: ingredientId, name: name.isNotEmpty ? name : ingredientId, cachedAt: DateTime.now())` and calls `_local.upsert(ingredient, userId: userId)`. Then computes `updated = ingredient.copyWith(isFavorite: !ingredient.isFavorite)` and upserts again.
- `ingredient_favorites_provider.dart:47` — provider calls `repo.toggleFavorite(ingredientId, name: name)`, passing the display name through.
- `ingredient_search_screen.dart:177-179` — `onFavoriteTap` calls `toggleFavorite(name, name: name)`, providing the ingredient display name.
- `ingredient_category_screen.dart:111-113` — `onFavoriteTap` calls `toggleFavorite(ingredient.id, name: ingredient.name)`.

**Status: VERIFIED** — Upsert-before-toggle pattern correctly implemented at both repository and all call sites.

---

### Gap 9: RefreshIndicator wraps all async states on category screen

**Claim:** `RefreshIndicator` is lifted outside `.when()` so it detects pull gestures in loading, error, and empty states — not only in the data state.

**Verification:**

- `ingredient_category_screen.dart:43-121` — `RefreshIndicator` widget wraps `ingredientsAsync.when(...)` at line 43; `onRefresh` calls `ref.invalidate(ingredientsByCategoryProvider(categoryName))` then `await ref.read(...future)`.
- Loading state (`loading:`) at line 50 returns `_buildShimmerList()` — a `ListView.builder` inside `Shimmer.fromColors`.
- Error state (`error:`) at lines 51-72 returns a `ListView` with `physics: const AlwaysScrollableScrollPhysics()` — comment at line 52 explicitly notes this is "required so RefreshIndicator detects the pull gesture".
- Empty data state at lines 84-96 returns a `ListView` with `physics: const AlwaysScrollableScrollPhysics()` — comment at line 86 repeats the same note.
- Data state at lines 99-119 uses `ListView.builder` with `physics: const AlwaysScrollableScrollPhysics()`.

**Status: VERIFIED** — RefreshIndicator correctly wraps all four `.when()` branches; all non-loading states use `AlwaysScrollableScrollPhysics`.

---

### Gap 1: Local commonIngredients check before debounce Timer (fast path)

**Claim:** `IngredientSearch.search()` checks `commonIngredients` synchronously before starting the `Timer`. If >= 5 matches found, emits immediately and returns without starting the timer at all.

**Verification:**

- `ingredient_search_provider.dart:24-26` — `build()` registers `ref.onDispose(() => _debounce?.cancel())` once. This is no longer registered per keystroke (the original leak).
- `ingredient_search_provider.dart:37-46` — Before any `Timer(...)` call: `localResults` is computed from `commonIngredients.where(...)`. If `localResults.length >= 5`, `state = AsyncData(localResults)` and `return`. Timer is never started on the fast path.
- `ingredient_search_provider.dart:49-53` — Partial fast path: if `localResults.isNotEmpty` (but < 5), emits partial results immediately, then falls through to the timer for API fallback.
- `ingredient_search_provider.dart:56-65` — `_debounce = Timer(const Duration(milliseconds: 300), ...)` only reached when local results < 5.

**Status: VERIFIED** — Local-first fast path emits synchronously before debounce. Timer only started for uncommon queries. `ref.onDispose` registered once in `build()`.

---

### Gap 3: Search screen watches ingredientFilterProvider

**Claim:** `ingredient_search_screen.dart` watches `ingredientFilterProvider` inside the `data:` branch and applies active dietary filters to search results.

**Verification:**

- `ingredient_search_screen.dart:8` — `import '.../ingredient_filter_provider.dart'` present.
- `ingredient_search_screen.dart:136` — `final activeFilters = ref.watch(ingredientFilterProvider)` inside the `data:` branch of `searchResults.when(...)`.
- `ingredient_search_screen.dart:152-163` — When `activeFilters.isNotEmpty`, `filtered` list is computed via `suggestions.where(...)` using `_restrictionToFlag()` to match flag strings against `cached.dietaryFlags`. Items without cached metadata pass through (graceful degradation, line 157: `if (cached == null) return true`).

**Status: VERIFIED** — Filter provider is watched and actively applied to search results in the data branch.

---

### Gap 4: Search tiles enriched with dietary badge data

**Claim:** Search result tiles receive dietary badge data from a `favoritesList`-based enrichment lookup, not hardcoded empty lists.

**Verification:**

- `ingredient_search_screen.dart:137` — `final favoritesList = favoritesAsync.value ?? []` (favorites already watched at line 51 via `ref.watch(ingredientFavoritesProvider)`).
- `ingredient_search_screen.dart:140-143` — `final ingredientLookup = <String, Ingredient>{}` built by iterating `favoritesList` and keying by `fav.name.toLowerCase()`.
- `ingredient_search_screen.dart:145-149` — `favoriteNames` set computed from `favoritesList` for `isFavorite` determination per tile.
- `ingredient_search_screen.dart:169,174` — `final cached = ingredientLookup[name.toLowerCase()]` — `IngredientTile` receives `dietaryFlags: cached?.dietaryFlags ?? []` and `isFavorite: isFav`.

**Status: VERIFIED** — Tiles receive correct `dietaryFlags` (from favorites enrichment cache) and `isFavorite` (from `favoriteNames` set). Items not in cache receive empty flags (never hidden from results).

---

## Regression Checks (Previously-Passing Truths)

Quick sanity pass on all 22 truths from the initial verification to confirm no regressions from plans 03-04 and 03-05.

| # | Truth (abbreviated) | Regression Check | Status |
|---|---------------------|-----------------|--------|
| 1 | OFf SDK configured with User-Agent | `openfoodfacts_config.dart` unchanged | CLEAN |
| 2 | `getSuggestions` returns `List<String>` | `openfoodfacts_remote_source.dart` unchanged | CLEAN |
| 3 | Pull-through cache: Drift first, then OFf | `ingredient_repository.dart:27-49` still present, pull-through pattern intact | CLEAN |
| 4 | 12 ingredient categories static list | `ingredientCategories` map still 12 entries at line 4-17 of remote source | CLEAN |
| 5 | Dietary flags parsed and stored | Remote source parsing unchanged | CLEAN |
| 6 | Repository is single source of truth | No `OpenFoodAPIClient` calls in presentation after plan 03-04/05 changes | CLEAN |
| 7 | `getSelectedToday` returns all with no date filter | `ingredient_local_source.dart` unchanged | CLEAN |
| 8 | Debounced search within 500ms | `Timer(300ms)` still present as API fallback; fast path is faster | CLEAN |
| 9 | Min 2 chars before API call | `ingredient_search_provider.dart:31-33` — guard intact | CLEAN |
| 10 | Local `commonIngredients` checked before OFf | Now verified to run BEFORE the Timer — stronger than before | CLEAN |
| 11 | 12 colored category cards | `_buildCategoryGrid` with 12-entry `categoryMeta` const map unchanged | CLEAN |
| 12 | Dietary filter chips toggle correctly | `dietary_filter_chips.dart` and `ingredient_filter_provider.dart` unchanged | CLEAN |
| 13 | Incomplete-data footnote for GF/DF | `dietary_filter_chips.dart` unchanged | CLEAN |
| 14 | 2-tab main screen | `ingredient_main_screen.dart` unchanged | CLEAN |
| 15 | Ingredient tile shows name + category + dietary badges | `ingredient_tile.dart` unchanged; tiles in search screen now enriched | CLEAN |
| 16 | Shimmer loading, no CircularProgressIndicator | Both screens still use `Shimmer.fromColors`; no `CircularProgressIndicator` added | CLEAN |
| 17 | Favorites persist via heart icon | `ingredient_favorites_provider.dart` updated but core persist path intact; `ref.mounted` check at line 50 present | CLEAN |
| 18 | Favorites tab lists favorited ingredients | `ingredient_favorites_screen.dart` unchanged | CLEAN |
| 19 | Selected-today persists across navigation | `selected_today_provider.dart` unchanged | CLEAN |
| 20 | Selected-today available to Phase 4 | `selected_today_provider.dart` keepAlive, `selectedNames`/`selectedIds` getters unchanged | CLEAN |
| 21 | No auto-reset at midnight | `ingredient_local_source.dart` unchanged | CLEAN |
| 22 | Favorites toggle is optimistic | `ingredient_favorites_provider.dart:26-43` — state updated before `await repo.toggleFavorite` | CLEAN |

**Zero regressions detected.**

---

## Requirements Coverage

| Requirement | Plans | Description | Status | Evidence |
|-------------|-------|-------------|--------|----------|
| INGR-01 | 03-01, 03-02, 03-05 | User can search ingredients from external API with autocomplete | SATISFIED | Local-first fast path (03-05) + OFf fallback; search screen wired; no regressions |
| INGR-02 | 03-01, 03-02, 03-04 | User can browse ingredients by category | SATISFIED | Double-translation bug fixed (03-04); `RefreshIndicator` in all states (03-04) |
| INGR-03 | 03-03, 03-04 | User can add ingredients to favorites for quick access | SATISFIED | Upsert-before-toggle ensures favorites from search suggestions always persist (03-04) |
| INGR-04 | 03-01, 03-02, 03-05 | User can filter ingredients by dietary restrictions | SATISFIED | Filter provider now wired to search results (03-05); category screen filtering unchanged |
| INGR-05 | 03-03 | User can select "I have these ingredients today" for recipe discovery | SATISFIED | `SelectedTodayProvider` unchanged; no regressions |

All 5 requirements remain satisfied. No orphaned requirements.

---

## Anti-Patterns Check (Plans 03-04 and 03-05 Changes Only)

Files modified in the gap-closure plans:

| File | Line | Pattern | Severity | Notes |
|------|------|---------|----------|-------|
| No blockers found | — | — | — | — |

- `ingredient_repository.dart`: No TODO/stub/placeholder; `getIngredient` null-check is real logic; `upsert` before toggle is real implementation.
- `ingredient_favorites_provider.dart`: No stubs; optimistic append with `AsyncData([...currentList, newIngredient])` is real logic; `ref.mounted` guard present.
- `ingredient_search_provider.dart`: No stubs; `ref.onDispose` correctly in `build()` (not per keystroke); local-first check is real code.
- `ingredient_search_screen.dart`: `ingredientLookup` map and `_restrictionToFlag()` helper are real; graceful degradation (`if (cached == null) return true`) is intentional, not a stub.
- `ingredient_category_screen.dart`: `RefreshIndicator` lifted outside `.when()` with real `ref.invalidate` + `await future` refresh logic.

Zero blocker or warning anti-patterns in any modified file.

---

## Human Verification Required

The following items from the initial verification remain relevant and still require manual device/emulator testing:

### 1. Category Browse Loads Correct Ingredients

**Test:** Navigate to `/ingredients`, tap "Produce" category card.
**Expected:** Screen shows real vegetables and fruits from OpenFoodFacts (not a blank screen or wrong-category items).
**Why human:** The double-translation fix corrects the code path but actual OFf API responses for `en:fruits-and-vegetables` require runtime verification.

### 2. Favorite from Search Persists

**Test:** Search for "quinoa" (uncommon, not in commonIngredients), tap the heart icon. Navigate to the Favorites tab.
**Expected:** "quinoa" appears in the Favorites tab despite never having been fetched into Drift via category browsing.
**Why human:** Tests the upsert-before-toggle path with a real ingredient not previously in the local DB.

### 3. Search Fast Path Feels Instant

**Test:** Type "chick" in the search box.
**Expected:** Results appear immediately (no 300ms wait); "Chicken", "Chickpeas", "Chicken breast", etc. appear from local list without spinner.
**Why human:** Timing perception and absence of loading state require live interaction.

### 4. Dietary Filter on Search Results

**Test:** Tap "Vegan" filter chip, then search for an ingredient you have previously favorited with known vegan status.
**Expected:** That ingredient appears in results; non-vegan cached items are filtered out; unfamiliar items (no cache entry) still appear.
**Why human:** Requires a pre-populated favorites cache and real filter interaction to verify graceful degradation behavior.

### 5. Pull-to-Refresh on Error State

**Test:** With airplane mode enabled, navigate to a category screen (triggers error state). Pull down on the error message.
**Expected:** `RefreshIndicator` spinner appears and a new fetch is attempted.
**Why human:** Requires simulated network failure and live gesture to test the `AlwaysScrollableScrollPhysics` behavior in the error branch.

---

## Summary

All 6 UAT gaps diagnosed after initial verification are confirmed closed:

**Plan 03-04 fixed (3 gaps):**
- Gap 2 (category double-translation): Screen passes display name directly; repository owns the OFf tag mapping via `_getCategoryTag`. Verified at `ingredient_category_screen.dart:31-32` and `ingredient_repository.dart:100-104`.
- Gap 5 (favorite from search no-op): Repository `toggleFavorite` now performs `getIngredient` -> upsert minimal row if null -> upsert toggle. Verified at `ingredient_repository.dart:57-76`.
- Gap 9 (RefreshIndicator only in data state): `RefreshIndicator` lifted to wrap `.when(...)` entirely; error and empty branches use `AlwaysScrollableScrollPhysics`. Verified at `ingredient_category_screen.dart:43-121`.

**Plan 03-05 fixed (3 gaps):**
- Gap 1 (local check after debounce): `commonIngredients` match runs synchronously before `Timer(...)` call; >= 5 matches emit immediately and skip the timer entirely. Verified at `ingredient_search_provider.dart:37-46`.
- Gap 3 (search screen not watching filter provider): `ref.watch(ingredientFilterProvider)` added inside the `data:` branch at `ingredient_search_screen.dart:136`.
- Gap 4 (search tiles no dietary badges): `ingredientLookup` map built from `favoritesList` provides `dietaryFlags` to each `IngredientTile`; `isFavorite` computed from `favoriteNames` set. Verified at `ingredient_search_screen.dart:140-184`.

Zero regressions in the 22 previously-passing truths. All 5 INGR requirements remain satisfied.

Phase 3 goal is fully achieved — users can find ingredients by search, category browsing, and dietary filtering; favorites persist; selected-today state is ready for Phase 4 recipe discovery.

---

_Verified: 2026-03-04T11:00:00Z_
_Verifier: Claude (gsd-verifier)_
