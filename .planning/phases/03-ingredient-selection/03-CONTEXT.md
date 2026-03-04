# Phase 3: Ingredient Selection - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can find any ingredient they want to cook with — by searching, browsing categories, or filtering by dietary restriction — and build a personal favorites list for quick reuse. Users can select "I have these today" ingredients and hand them off to recipe discovery (Phase 4).

</domain>

<decisions>
## Implementation Decisions

### Search & Autocomplete UX
- Rich tiles for search results: each result shows ingredient name + category tag + dietary badges (vegan, GF, etc.)
- Pre-curated local list of ~200 common cooking ingredients; search matches local first, OFf API as fallback for less common items
- Inline shimmer placeholders (3-4 shimmer tiles) while loading — no full-screen spinner
- Inline action buttons on each tile: heart icon (favorite) and check icon (select today) — one-tap workflow, no bottom sheets

### Category Browsing
- Colored cards with distinct background color + icon per category — grocery store section visual feel
- Alphabetical sorting within each category
- Load all items at once (up to 50 per OFf page) with pull-to-refresh — no pagination/lazy-load
- Expand categories beyond current 10: add Baking, Nuts & Seeds, and any others Claude identifies as gaps in common cooking ingredient coverage

### "I Have These Today" Selection Flow
- Expandable pill bar at bottom: shows count + first 2-3 ingredient names as chips, tap to expand full list, "Find Recipes" CTA button when ≥1 selected
- No hard selection limit — user can select as many ingredients as they want
- "Find Recipes" navigates to recipe discovery screen (Phase 4) pre-filtered by selected ingredients — clean handoff between features
- Selections persist until user manually clears — no auto-reset at midnight

### Favorites & Daily Workflow
- Main ingredient screen uses 2 tabs: "Search/Browse" and "Favorites" — quick toggle, favorites one tap away
- When starting a new "I have these today" selection, show favorites as quick-add chips at top — one tap to add
- Animated heart icon with scale animation + light haptic feedback on favorite toggle — Instagram-like feel
- "Add all favorites" bulk action button at top of favorites list — power user shortcut to add all favorites to today's selection

### Claude's Discretion
- Exact shimmer placeholder design and animation timing
- Specific category colors and icon choices
- How to handle OFf API returning irrelevant branded products (filtering strategy details)
- Debounce timing adjustments (currently 300ms)
- Dietary filter chip visual design
- Error state handling for network failures during category browsing

</decisions>

<specifics>
## Specific Ideas

No specific external references — open to standard Flutter/Material patterns for ingredient selection. Key principles:
- Fast one-tap workflow: users should be able to search, favorite, and select ingredients with minimal taps
- Visual category browsing should feel like walking through grocery store sections
- The "I have these" bar should feel like a shopping cart — always visible, expandable for details

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Ingredient` Freezed model (`features/ingredients/domain/ingredient.dart`): id, name, category, isFavorite, dietaryFlags, cachedAt
- `IngredientFilter` Freezed model with query, category, dietaryRestrictions
- `IngredientRepository` with pull-through cache pattern (OFf → Drift)
- `OpenFoodFactsRemoteSource` with getSuggestions() and searchByCategory()
- `IngredientLocalSource` with Drift-backed storage
- 5 Riverpod providers: search, favorites, filter, category, selected-today
- 3 screens: IngredientSearchScreen, IngredientCategoryScreen, IngredientFavoritesScreen
- 3 widgets: DietaryFilterChips, IngredientTile, SelectedTodayBar

### Established Patterns
- Pull-through cache: emit cached → fetch remote → upsert local → emit fresh (used in watchIngredientsByCategory)
- Optimistic writes for favorites (flip isFavorite, mark syncStatus pending)
- ConsumerStatefulWidget pattern for screens with TextEditingController
- Feature-first directory structure: data/, domain/, presentation/{providers, screens, widgets}

### Integration Points
- go_router: `/ingredients/category/$name` route for category navigation
- Auth: userId needed for selectedToday operations (from authStateProvider)
- Phase 4 handoff: "Find Recipes" action needs to pass selected ingredient IDs to recipe discovery screen
- Drift schema: ingredients table with UUID PKs, syncStatus column for Phase 8

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-ingredient-selection*
*Context gathered: 2026-03-04*
