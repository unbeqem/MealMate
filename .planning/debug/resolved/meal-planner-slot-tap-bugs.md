---
status: resolved
trigger: "Tapping an empty slot in the meal planner shows recipe detail view instead of assigning the recipe, and the UI freezes after the first attempt."
created: 2026-03-05T00:00:00Z
updated: 2026-03-05T00:00:00Z
---

## Current Focus

hypothesis: Two distinct confirmed bugs identified. No further investigation needed.
test: Static code analysis of all three files + RecipeCard.
expecting: N/A — root causes confirmed.
next_action: Apply fixes.

## Symptoms

expected: EmptySlotCard tap -> /recipes?selectForSlot=true -> user picks recipe -> context.pop() returns data -> recipe assigned to slot.
actual: Symptom 1: tapping a recipe in select mode shows detail screen instead of popping back. Symptom 2: UI freezes after first attempt.
errors: No runtime errors reported; silent misbehaviour.
reproduction: Tap any empty slot in planner, tap any recipe card in the browse screen.
started: Since meal planner feature introduction.

## Eliminated

- hypothesis: selectForSlot query param not being read correctly.
  evidence: recipe_browse_screen.dart line 58 correctly reads `queryParams['selectForSlot'] == 'true'` and passes `isSelectMode` down to _SearchModeBody and _IngredientModeBody.
  timestamp: 2026-03-05

- hypothesis: _SelectableRecipeCard not wrapping correctly / wrong widget returned.
  evidence: Lines 241-247 in recipe_browse_screen.dart correctly return _SelectableRecipeCard when isSelectMode is true, and RecipeCard otherwise.
  timestamp: 2026-03-05

- hypothesis: context.pop() called with wrong data shape.
  evidence: Lines 391-395 call context.pop<Map<String,dynamic>>({'recipeId': recipe.id, 'recipeTitle': recipe.title, 'recipeImage': recipe.image}) — correct shape matching EmptySlotCard's expectation at line 78.
  timestamp: 2026-03-05

- hypothesis: planner_grid.dart is doing something wrong with the result.
  evidence: EmptySlotCard._onTap (not planner_grid.dart) handles the push/pop result. planner_grid.dart only creates EmptySlotCard with the right params.
  timestamp: 2026-03-05

## Evidence

- timestamp: 2026-03-05
  checked: recipe_card.dart lines 20-24
  found: RecipeCard uses Card > InkWell(onTap: () => context.push('/recipes/${recipe.id}')). The InkWell tap handler navigates to the detail screen unconditionally.
  implication: BUG 1 ROOT CAUSE — _SelectableRecipeCard wraps RecipeCard in a GestureDetector, but the GestureDetector sits OUTSIDE the Card. The Card's own InkWell is INSIDE the widget tree and handles taps at the Material level. In Flutter, GestureDetector.onTap and InkWell.onTap compete; InkWell (being a Material-layer recogniser) wins. The RecipeCard's InkWell fires context.push('/recipes/...') before the outer GestureDetector can call context.pop(). The user sees the detail screen.

- timestamp: 2026-03-05
  checked: recipe_browse_screen.dart lines 389-399 (_SelectableRecipeCard.build)
  found: GestureDetector wraps Stack([RecipeCard(...), Positioned(badges)]). RecipeCard internally has InkWell with its own onTap. GestureDetector.onTap is never reached because InkWell consumes the tap first.
  implication: Confirms BUG 1. The fix must disable or replace RecipeCard's onTap when in select mode.

- timestamp: 2026-03-05
  checked: recipe_browse_screen.dart lines 176-183 (_SearchModeBodyState.build / data callback)
  found: Inside the `data:` callback of firstPageAsync.when(), there is a conditional setState call via addPostFrameCallback at lines 177-183:
    if (_totalResults != firstPage.totalResults) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _totalResults = firstPage.totalResults);
        }
      });
    }
  The setState triggers a rebuild. The rebuild re-watches the same provider (recipeSearchPageProvider page 0). The provider returns the same cached data immediately (AsyncData). _totalResults is now equal to firstPage.totalResults, so the condition is false — no infinite loop here by itself.
  implication: Alone this is safe. BUT see next entry.

- timestamp: 2026-03-05
  checked: recipe_browse_screen.dart lines 202-208 (load-more trigger inside itemBuilder)
  found: Inside itemBuilder, when the last-page trigger item is rendered:
    if (index == _loadedPages * pageSize - 1 && _loadedPages * pageSize < totalResults) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _loadedPages++);
      });
    }
  This is also safe in isolation during normal browsing.
  implication: Not the freeze cause on its own.

- timestamp: 2026-03-05
  checked: recipe_browse_screen.dart lines 57-58 — GoRouterState.of(context).uri.queryParameters read inside build()
  found: `GoRouterState.of(context)` is called on every build inside _RecipeBrowseScreenState.build(). GoRouterState.of() subscribes the widget to router state changes via InheritedWidget. When context.push('/recipes/ID') fires (from RecipeCard's InkWell), the router navigates to the detail screen. On return (back button), the router state changes, which invalidates the InheritedWidget, which triggers a rebuild of RecipeBrowseScreen. The rebuild reads the same URI again. If the detail screen itself uses GoRouterState.of(), those same widgets also rebuild.
  implication: Contributes to churn but is not the freeze cause alone.

- timestamp: 2026-03-05
  checked: Interaction sequence when user taps recipe card in select mode
  found: Step-by-step what actually happens:
    1. User taps recipe card.
    2. RecipeCard's InkWell fires context.push('/recipes/123') — WRONG path.
    3. GestureDetector.onTap ALSO fires (it is not consumed by InkWell; GestureDetector and InkWell are in different parts of the hit-test arena — GestureDetector wraps the whole Stack including the Card).
    4. context.pop() is called WHILE context.push() is also being processed.
    5. context.push() adds route /recipes/123. context.pop() pops the CURRENT top route — which is /recipes (the browse screen itself), not /recipes/123 yet.
    6. The browse screen is popped OFF the stack before the detail screen finishes pushing. EmptySlotCard._onTap's await context.push() returns null (the screen was popped from underneath).
    7. The navigation stack is now in an inconsistent state: detail screen is mid-push onto a stack that lost its predecessor. GoRouter's navigator has orphaned or double-popped state.
  implication: BUG 2 ROOT CAUSE — The double-fire of InkWell + GestureDetector causes context.pop() to pop the wrong route. After this, the Navigator stack is corrupt: routes exist in the stack but the GoRouter location is desynchronised. Flutter's gesture arena is then in a bad state (pending recogniser callbacks against widgets that are no longer mounted), which manifests as complete UI unresponsiveness.

## Resolution

root_cause: |
  BUG 1 (wrong screen shown): _SelectableRecipeCard wraps RecipeCard in a
  GestureDetector, but RecipeCard's internal InkWell (inside the Card widget)
  also has an onTap that calls context.push('/recipes/ID'). InkWell.onTap and
  GestureDetector.onTap both fire. InkWell fires first (Material ink splash
  handling takes precedence), navigating to the detail screen.

  BUG 2 (UI freeze): Because both handlers fire simultaneously, context.push()
  (from InkWell) and context.pop() (from GestureDetector) execute in the same
  frame. context.pop() pops the browse screen itself (not the detail screen,
  which hasn't finished pushing yet). This corrupts the GoRouter/Navigator stack,
  leaving Flutter's gesture arena referencing disposed/orphaned widgets, causing
  all subsequent taps to be silently swallowed.

fix: |
  RecipeCard needs an optional `onTap` parameter. When provided it overrides the
  internal InkWell's navigation. _SelectableRecipeCard passes its pop callback
  directly as `onTap`, completely replacing the detail-navigation behaviour.
  This eliminates the double-handler race entirely.

  Specifically:
  1. Add `final VoidCallback? onTap` to RecipeCard.
  2. In RecipeCard.build(), change InkWell.onTap to:
       onTap: onTap ?? () => context.push('/recipes/${recipe.id}'),
  3. In _SelectableRecipeCard.build(), replace:
       GestureDetector(onTap: ..., child: Stack([RecipeCard(recipe: recipe), ...]))
     with:
       Stack([
         RecipeCard(
           recipe: recipe,
           onTap: () => context.pop<Map<String, dynamic>>({...}),
         ),
         Positioned(badges)...
       ])
  This removes the GestureDetector entirely and routes the tap through the
  single InkWell, which gives correct ink-splash feedback and no double-fire.

verification: Static analysis confirms no other callers of RecipeCard pass onTap (it is currently absent), so the change is backwards-compatible with a null default.

files_changed:
  - meal_mate/lib/features/recipes/presentation/recipe_card.dart
  - meal_mate/lib/features/recipes/presentation/recipe_browse_screen.dart
