---
status: resolved
trigger: "Investigate why category browse returns no results in the MealMate Flutter app."
created: 2026-03-04T00:00:00Z
updated: 2026-03-04T00:00:00Z
---

## Current Focus

hypothesis: CONFIRMED — two independent bugs found; one breaks the UI, one breaks data loading
test: full static trace of data flow from category tap through router, provider, repository, and remote source
expecting: root causes identified
next_action: report findings

## Symptoms

expected: Tapping a category card navigates to IngredientCategoryScreen and shows a shimmer then a list of ingredients
actual: No shimmer, no results — screen appears empty or shows "No ingredients found for this category"
errors: None visible
reproduction: Tap any category card on IngredientSearchScreen
started: Unknown — feature is new

## Eliminated

- hypothesis: Provider not wired up or missing
  evidence: ingredient_category_provider.dart and .g.dart exist and are correct; provider is watched in screen
  timestamp: 2026-03-04

- hypothesis: Route not registered
  evidence: ingredientRoutes in app_router.dart correctly registers /ingredients/category/:name
  timestamp: 2026-03-04

- hypothesis: OFf API called with wrong tag (remote source side)
  evidence: searchByCategory receives whatever tag is passed in; the tag construction is the problem upstream
  timestamp: 2026-03-04

## Evidence

- timestamp: 2026-03-04
  checked: ingredient_search_screen.dart line 252
  found: context.push('/ingredients/category/$name') — name is the display name string e.g. "Nuts & Seeds"
  implication: The URL will be /ingredients/category/Nuts%20&%20Seeds (URL-encoded by go_router)

- timestamp: 2026-03-04
  checked: app_router.dart line 32
  found: categoryName: state.pathParameters['name'] ?? '' — extracts the path segment back to display name
  implication: categoryName received by IngredientCategoryScreen IS the display name e.g. "Nuts & Seeds"

- timestamp: 2026-03-04
  checked: ingredient_category_screen.dart lines 32-34
  found: |
    final categoryTag = ingredientCategories[categoryName] ?? categoryName;
    ref.watch(ingredientsByCategoryProvider(categoryTag));
  implication: Screen correctly translates display name -> OFf tag BEFORE passing to provider. This lookup is correct.

- timestamp: 2026-03-04
  checked: ingredient_category_provider.dart
  found: repo.watchIngredientsByCategory(category) — passes the OFf tag string through directly
  implication: Provider passes the OFf tag to the repository. Correct.

- timestamp: 2026-03-04
  checked: ingredient_repository.dart watchIngredientsByCategory lines 27-48
  found: |
    // Step 1: yield from local cache using raw `category` param (the OFf tag)
    final cached = await _local.getIngredientsByCategory(category);
    yield cached;

    // Step 2: call _getCategoryTag(category) to look up the OFf tag
    final categoryTag = _getCategoryTag(category);
  implication: |
    BUG #1: The `category` param passed in is ALREADY an OFf tag (e.g. "en:fruits-and-vegetables").
    The local source query on line 29 searches the DB column `category` for this OFf tag string.
    But upsertAll on line 42 stores ingredients with `category: category` (the display name, set via copyWith).
    So the local cache query will ALWAYS miss — it searches by OFf tag but the DB stores display name.

- timestamp: 2026-03-04
  checked: ingredient_repository.dart lines 34-35 and 85-88
  found: |
    final categoryTag = _getCategoryTag(category);
    // _getCategoryTag does: ingredientCategories[displayName]
    // But `category` at this point is already an OFf tag like "en:fruits-and-vegetables"
    // ingredientCategories maps displayName -> OFf tag, NOT OFf tag -> OFf tag
  implication: |
    BUG #2: _getCategoryTag receives an OFf tag as input but treats it as a display name key.
    ingredientCategories["en:fruits-and-vegetables"] returns null.
    categoryTag is null, so the `if (categoryTag != null)` guard on line 35 skips the entire
    remote fetch. The OFf API is NEVER called. No shimmer is shown because the stream
    immediately emits the cached empty list (data state, not loading), which shows
    "No ingredients found for this category".

- timestamp: 2026-03-04
  checked: ingredient_repository.dart line 39-41
  found: |
    final tagged = fresh.map((i) => i.copyWith(category: category)).toList();
    // Here `category` is the OFf tag passed in, NOT the display name
  implication: |
    BUG #3 (latent): Even if the remote fetch worked, it would store the OFf tag as the
    category field. The local cache lookup would still fail on next open because the DB
    stores OFf tags but the query expects display names (or vice versa — the mismatch
    exists regardless of direction).

## Resolution

root_cause: |
  The repository's watchIngredientsByCategory is passed an OFf tag (e.g. "en:fruits-and-vegetables")
  by the provider, but internally calls _getCategoryTag() which does a display-name lookup in
  ingredientCategories. Since the key doesn't exist, _getCategoryTag returns null, the null guard
  skips the remote fetch entirely, and only the empty cache is emitted — showing "No ingredients found"
  with no shimmer (because the stream is in data state immediately, not loading state).

  There is a secondary mismatch: the local cache stores display names in the category column (via
  copyWith(category: category) where category is the display name at the remote source level) but
  watchIngredientsByCategory queries the DB with the OFf tag string. So the local cache never hits.

fix: |
  The repository's interface should accept the display name (not the OFf tag). The provider
  currently passes the OFf tag because the screen pre-translates it. The fix is one of:

  Option A (minimal — fix the repository):
    - Remove the _getCategoryTag() call from watchIngredientsByCategory.
    - Accept `displayName` as the param. Use displayName directly as the local cache key.
    - Look up the OFf tag internally: `ingredientCategories[displayName]`.
    - Store with `copyWith(category: displayName)`.
    - Update the provider to pass the display name instead of the pre-translated tag.
    - The screen already does the tag lookup; skip it — pass categoryName directly to the provider.

  Option B (alternative — fix the screen):
    - Remove the pre-translation in the screen (lines 32-33 of ingredient_category_screen.dart).
    - Pass categoryName (display name) directly to ingredientsByCategoryProvider.
    - Fix the repository to look up the OFf tag from the display name internally (already has _getCategoryTag for this, but currently receives the wrong input type).

  Option A is cleaner: the provider/repository abstraction should own the tag translation.

verification: Static analysis — root cause confirmed via full trace. No runtime verification performed.
files_changed:
  - meal_mate/lib/features/ingredients/data/ingredient_repository.dart
  - meal_mate/lib/features/ingredients/presentation/screens/ingredient_category_screen.dart
  - meal_mate/lib/features/ingredients/presentation/providers/ingredient_category_provider.dart
