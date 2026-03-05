# Phase 5: Weekly Meal Planner - Context

**Gathered:** 2026-03-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can build a complete week of meals by assigning recipes to breakfast, lunch, and dinner slots across 7 days, reorder meals via drag-and-drop, save weeks as named templates, and receive ingredient reuse suggestions when picking recipes. Shopping list generation is Phase 6.

</domain>

<decisions>
## Implementation Decisions

### Planner grid layout
- Hybrid scroll: horizontal day tabs or PageView for focused single-day view, with a week overview strip for context
- Filled slot cards show recipe thumbnail image + recipe title (no cook time or other metadata)
- Empty slots use dashed border with centered "+" icon — tap opens recipe picker
- Default view opens to the current week (the Monday that already passed or is today)

### Week navigation
- Left/right arrow buttons flanking a date range label (e.g., "Mar 3 – Mar 9")
- Tap the date label to jump to a specific week (date picker)

### Recipe assignment flow
- Tapping an empty slot or "replace" navigates to RecipeBrowseScreen (Phase 4) in a "select for slot" mode — full search, filters, and ingredient mode available
- Filled slot cards have small inline edit (replace) and delete (remove) icons — one-tap actions, no extra step
- Tapping a filled slot card navigates to RecipeDetailScreen to view the recipe; edit/remove use the inline icons
- Recipes already assigned in the current week's plan show a small "Planned" badge in the recipe picker — informational, not blocking

### Drag-and-drop rescheduling
- Dragging a meal card onto another filled slot swaps the two meals
- Dragging onto an empty slot moves the meal there
- Both operations persist on reload

### Templates
- Save/load accessed from planner screen's overflow menu (three-dot or action bar)
- "Save as Template" prompts user to type a name (e.g., "Busy Week", "Veggie Week") via simple dialog
- "Load Template" shows saved templates; when loading into a week that has existing meals, dialog asks: "Replace all meals" or "Fill empty slots only"

### Ingredient reuse suggestions
- Small badge on recipe cards in the picker showing shared ingredient count (e.g., "3 shared ingredients")
- Expandable/collapsible panel on the planner screen showing all unique ingredients for the week with counts
- Exact ingredient name matching (Spoonacular names are already normalized) — no fuzzy/base ingredient grouping in v1

### Claude's Discretion
- Exact hybrid layout implementation (tab bar vs PageView vs custom)
- Week overview strip visual design and density
- Drag-and-drop scroll conflict mitigation approach
- Recipe picker "select for slot" mode implementation (parameter on route vs separate mode)
- Ingredient summary panel visual design and collapse behavior
- Animation and haptic feedback on drag-and-drop interactions
- Error state handling for failed persistence

</decisions>

<specifics>
## Specific Ideas

- Slot cards should be visually consistent with RecipeCard from Phase 4 but more compact for the grid context
- "Planned" badge in recipe picker is informational only — users should be free to plan the same recipe twice if they want
- Week ingredient summary panel serves as a bridge to Phase 6 shopping list — helps users visualize what they'll need
- Template naming should feel like naming a playlist — short, personal labels

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RecipeCard` widget (`features/recipes/presentation/recipe_card.dart`): shows recipe image, title, cook time — can be adapted for compact slot cards
- `RecipeBrowseScreen` (`features/recipes/presentation/recipe_browse_screen.dart`): full search + filter + pagination — reusable for recipe picker in "select for slot" mode
- `RecipeDetailScreen` (`features/recipes/presentation/screens/recipe_detail_screen.dart`): tap-through target from filled slots
- `FilterChipsRow` widget: reusable in recipe picker context
- `RecipeSearchResult` and `Recipe` Freezed models with Spoonacular data

### Established Patterns
- Feature-first directory structure: `data/`, `domain/`, `presentation/{providers, screens, widgets}`
- Freezed models for domain objects + Riverpod 3.x providers with code gen
- Drift tables with UUID v4 PKs and syncStatus/updatedAt columns for Phase 8 sync
- GoRouter route registration pattern: separate route file per feature, spread into main router
- Inline action icons on list items (Phase 3 ingredient tiles: heart + check icons)
- ConsumerStatefulWidget for screens with controllers

### Integration Points
- `MealPlanSlots` Drift table already exists with `id`, `userId`, `recipeId` (FK), `dayOfWeek`, `mealType`, `weekStart`, `updatedAt`, `syncStatus`
- Schema version currently 3 — Phase 5 needs version 4 migration for template tables (`MealPlanTemplates`, `MealPlanTemplateSlots`)
- GoRouter: new routes needed (`/planner`, `/planner/templates`)
- HomeScreen: needs "Meal Planner" card added to home (follows existing Card/ListTile pattern)
- `recipeSearchPageProvider` and `recipeDetailProvider` can be reused in recipe picker context
- Auth: `userId` from `authStateProvider` needed for meal plan CRUD operations

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-weekly-meal-planner*
*Context gathered: 2026-03-05*
