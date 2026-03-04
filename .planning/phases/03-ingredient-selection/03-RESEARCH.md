# Phase 3: Ingredient Selection - Research

**Researched:** 2026-03-04
**Domain:** OpenFoodFacts integration, autocomplete UI, Drift caching, Riverpod 3 state management, Flutter animation & haptics
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Search & Autocomplete UX**
- Rich tiles for search results: each result shows ingredient name + category tag + dietary badges (vegan, GF, etc.)
- Pre-curated local list of ~200 common cooking ingredients; search matches local first, OFf API as fallback for less common items
- Inline shimmer placeholders (3-4 shimmer tiles) while loading — no full-screen spinner
- Inline action buttons on each tile: heart icon (favorite) and check icon (select today) — one-tap workflow, no bottom sheets

**Category Browsing**
- Colored cards with distinct background color + icon per category — grocery store section visual feel
- Alphabetical sorting within each category
- Load all items at once (up to 50 per OFf page) with pull-to-refresh — no pagination/lazy-load
- Expand categories beyond current 10: add Baking, Nuts & Seeds, and any others Claude identifies as gaps in common cooking ingredient coverage

**"I Have These Today" Selection Flow**
- Expandable pill bar at bottom: shows count + first 2-3 ingredient names as chips, tap to expand full list, "Find Recipes" CTA button when ≥1 selected
- No hard selection limit — user can select as many ingredients as they want
- "Find Recipes" navigates to recipe discovery screen (Phase 4) pre-filtered by selected ingredients — clean handoff between features
- Selections persist until user manually clears — no auto-reset at midnight

**Favorites & Daily Workflow**
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

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INGR-01 | User can search ingredients from external API with autocomplete | `OpenFoodAPIClient.getSuggestions(TagType.INGREDIENTS)` + in-provider 300ms debounce meets 500ms UX target; local ~200-ingredient list searched first for instant results |
| INGR-02 | User can browse ingredients by category | Extended static category list (12 categories including Baking, Nuts & Seeds) with colored cards + icons; each taps to OFf-backed category screen; alphabetical sort |
| INGR-03 | User can add ingredients to favorites for quick access | `isFavorite` boolean on Drift `ingredients` table; animated heart with scale animation + `HapticFeedback.lightImpact()`; optimistic write; "add all favorites" bulk action |
| INGR-04 | User can filter ingredients by dietary restrictions (vegetarian, vegan, gluten-free, dairy-free) | `FilterChip` row; client-side filtering against Drift `dietaryFlags` JSON column; incomplete-coverage warning for GF/dairy-free |
| INGR-05 | User can select "I have these today" for recipe discovery | Expandable pill bar with ingredient name chips + "Find Recipes" CTA; `@Riverpod(keepAlive: true)` provider backed by Drift; persists until manually cleared |
</phase_requirements>

---

## Summary

Phase 3 implements the complete ingredient discovery and selection UI, building on top of the data layer (domain models, OFf remote source, Drift local source, IngredientRepository) that was fully built in Plan 03-01. Plans 03-02 and 03-03 also have skeleton widget files committed but their UI is minimal — the CONTEXT.md session (2026-03-04) defined rich UX behaviors that need to be implemented across all screens.

The primary new technical challenges for Phase 3 completion are: (1) building the tabbed ingredient screen structure (Search/Browse tab + Favorites tab) with the expandable pill bar; (2) adding animated heart + haptic feedback to IngredientTile; (3) enriching category cards with distinct colors and icons; (4) implementing the local ~200-ingredient pre-curated list for instant search; and (5) filtering OFf branded product noise from category results. The data layer (repository, providers) is already correct and tested — the remaining work is purely presentation layer.

The `shimmer` package (v3.0.0, most-used Flutter shimmer package) is the standard choice for inline shimmer placeholders. Haptic feedback is provided by Flutter's built-in `HapticFeedback.lightImpact()` from `services` — no additional package needed. Scale animation for the heart icon uses Flutter's built-in `AnimationController` or `TweenAnimationBuilder` — no external animation package required.

**Primary recommendation:** Build on the existing correct data layer. Focus on enriching the presentation layer per CONTEXT.md decisions: 2-tab main screen, expandable pill bar, shimmer tiles, colored category cards, animated heart, and the ~200-item local ingredient list for instant search.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| openfoodfacts | 3.11.0 (already in pubspec) | OFf SDK — `getSuggestions()` for autocomplete, `searchByCategory()` for category browsing | Official Dart SDK; already integrated in Phase 3 Plan 01 |
| flutter_riverpod + riverpod_annotation | 3.2.1 (already in pubspec) | All presentation state — search, favorites, filter, selected-today | Project-wide decision; providers already created in 03-01 |
| drift | 2.31.0 (already in pubspec) | Local persistence — ingredients, favorites, selected-today | Project-wide; schema v2 already built in 03-01 |
| shimmer | ^3.0.0 | Inline shimmer placeholder tiles during API loading | Most-used Flutter shimmer package; `Shimmer.fromColors()` wraps any widget skeleton |
| go_router | 17.1.0 (already in pubspec) | Route registration — `/ingredients`, `/ingredients/category/:name`, `/ingredients/favorites` | Project-wide; ingredientRoutes already wired in router.dart |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter/services | built-in | `HapticFeedback.lightImpact()` for favorite toggle feedback | No package needed — this is in the Flutter SDK |
| flutter/animation | built-in | `AnimationController` + `ScaleTransition` or `TweenAnimationBuilder` for heart animation | No package needed — native Flutter animation primitives |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `shimmer` package | Custom `ShaderMask` shimmer | Flutter docs show the custom approach; `shimmer` package saves ~50 lines and handles the animation lifecycle — use the package since no other packages are excluded |
| `TweenAnimationBuilder` for heart scale | `flutter_animate` package | `flutter_animate` is a newer dependency; `TweenAnimationBuilder` achieves the same in ~15 lines with no new dependency |
| `HapticFeedback.lightImpact()` | `haptic_feedback` package | The built-in Flutter `services` library covers all required haptic types; no package needed |

**Installation:**
```bash
flutter pub add shimmer
```
Everything else is already in `pubspec.yaml`.

---

## Architecture Patterns

### Recommended Project Structure

The existing structure from Plans 03-01/02/03 is correct. The delta for this research is:

```
lib/
├── core/
│   └── assets/
│       └── common_ingredients.dart      # Pre-curated ~200 ingredient list (static const)
├── features/
│   └── ingredients/
│       ├── data/                        # COMPLETE (03-01)
│       ├── domain/                      # COMPLETE (03-01)
│       └── presentation/
│           ├── providers/               # COMPLETE (03-01/02/03) — all 5 providers exist
│           ├── screens/
│           │   ├── ingredient_main_screen.dart    # NEW — 2-tab shell (Search/Browse + Favorites)
│           │   ├── ingredient_search_screen.dart  # UPDATE — add shimmer, quick-add favorites chips, local search
│           │   ├── ingredient_category_screen.dart # UPDATE — colored cards, alphabetical sort, pull-to-refresh
│           │   └── ingredient_favorites_screen.dart # UPDATE — "Add all" bulk action button
│           └── widgets/
│               ├── ingredient_tile.dart          # UPDATE — animated heart, dietary badges, shimmer variant
│               ├── dietary_filter_chips.dart     # EXISTS — no changes needed
│               └── selected_today_bar.dart       # UPDATE — expandable pill bar with ingredient name chips
```

### Pattern 1: 2-Tab Main Screen (INGR-01, INGR-02, INGR-03)

**What:** A `DefaultTabController` with 2 tabs ("Search/Browse" and "Favorites") as the main entry point. Both tabs share the `SelectedTodayBar` at the bottom.

**When to use:** When two related views must be one tap apart with no intermediate navigation.

**Example:**
```dart
// Source: Flutter docs — DefaultTabController
class IngredientMainScreen extends ConsumerWidget {
  const IngredientMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ingredients'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.search), text: 'Search'),
              Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            ],
          ),
        ),
        body: Column(
          children: [
            const Expanded(
              child: TabBarView(
                children: [
                  IngredientSearchScreen(),
                  IngredientFavoritesScreen(),
                ],
              ),
            ),
            const SelectedTodayBar(),
          ],
        ),
      ),
    );
  }
}
```

### Pattern 2: Local-First Search with OFf Fallback (INGR-01)

**What:** Search against a pre-curated static list of ~200 common cooking ingredients in memory first (synchronous, instant). If fewer than N results, fall back to OFf `getSuggestions()` API. The local list is a plain `List<String>` constant — no Drift query needed.

**When to use:** Any search where a curated subset covers 90%+ of use cases and API latency matters.

**Example:**
```dart
// In IngredientSearchProvider or IngredientRepository
final localResults = commonIngredients
    .where((name) => name.toLowerCase().contains(query.toLowerCase()))
    .take(10)
    .toList();

if (localResults.length >= 5) {
  return localResults; // Fast path — no API call
}

// Fallback to OFf API
final apiResults = await _remote.getSuggestions(query);
return {...localResults, ...apiResults}.toList().take(20).toList();
```

**Important:** The local list should be deduplicated with API results (use a `Set` or check `contains`).

### Pattern 3: Animated Heart with Haptic Feedback (INGR-03)

**What:** A `StatefulWidget` that uses an `AnimationController` to scale the heart icon to 1.4x then back to 1.0x over ~300ms, with a `HapticFeedback.lightImpact()` call on tap. The animation should use `Curves.elasticOut` for the scale-up phase.

**When to use:** Any "like/favorite" toggle action where instant tactile + visual feedback improves perceived responsiveness.

**Example:**
```dart
// Source: Flutter docs — AnimationController + HapticFeedback
class AnimatedHeartButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;
  const AnimatedHeartButton({required this.isFavorite, required this.onTap, super.key});

  @override
  State<AnimatedHeartButton> createState() => _AnimatedHeartButtonState();
}

class _AnimatedHeartButtonState extends State<AnimatedHeartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Icon(
          widget.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: widget.isFavorite ? Colors.red : null,
        ),
      ),
    );
  }
}
```

### Pattern 4: Shimmer Placeholder Tiles (INGR-01, INGR-02)

**What:** While OFf API is loading, show 3-4 skeleton `ListTile` shapes with a shimmer animation. Use the `shimmer` package `Shimmer.fromColors()` wrapping a dummy tile layout.

**When to use:** Any async list load — replaces `CircularProgressIndicator` for loading states per CONTEXT.md locked decision.

**Example:**
```dart
// Source: pub.dev/packages/shimmer
import 'package:shimmer/shimmer.dart';

Widget _buildShimmerList() {
  return ListView.builder(
    itemCount: 4,
    itemBuilder: (_, __) => Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white, radius: 20),
        title: Container(height: 12, width: double.infinity, color: Colors.white),
        subtitle: Container(height: 10, width: 150, color: Colors.white),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 24, height: 24, color: Colors.white),
            const SizedBox(width: 8),
            Container(width: 24, height: 24, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}
```

### Pattern 5: Expandable Pill Bar (INGR-05)

**What:** A bottom bar that shows a collapsed summary (count + first 2-3 ingredient name chips) and expands to a full list when tapped. Uses `AnimatedContainer` for the expand/collapse transition. "Find Recipes" CTA always visible.

**When to use:** When a running selection must be visible but not dominate the screen.

**Example:**
```dart
// Pattern: AnimatedContainer for expand/collapse, Consumer for state
class SelectedTodayBar extends ConsumerStatefulWidget {
  const SelectedTodayBar({super.key});

  @override
  ConsumerState<SelectedTodayBar> createState() => _SelectedTodayBarState();
}

class _SelectedTodayBarState extends ConsumerState<SelectedTodayBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final selectedAsync = ref.watch(selectedTodayProvider);
    final selectedIds = selectedAsync.value ?? {};
    if (selectedIds.isEmpty) return const SizedBox.shrink();

    // Need ingredient names — look up from a derived provider or pass names in toggle
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: _expanded ? 200 : 64,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCollapsedRow(context, selectedIds),
            if (_expanded) _buildExpandedList(context, selectedIds),
          ],
        ),
      ),
    );
  }
}
```

**Implementation note:** The expandable bar needs ingredient names, not just IDs. Two approaches:
1. Store `Map<String, String>` (id → name) in the selected-today provider alongside the ID set
2. Look up names from a `selectedIngredientsProvider` that derives from `selectedTodayProvider` + a cached ingredient lookup

Approach 1 is simpler and avoids a derived async lookup. The planner should choose this: modify `SelectedTodayNotifier` to maintain a `Map<String, String> selectedIdsWithNames` in addition to the `Set<String>`.

### Pattern 6: Colored Category Cards (INGR-02)

**What:** Each category card has a distinct `Color` background and a `MaterialIcon`. Colors should be pastel/muted (avoid eye-strain), icons should clearly evoke the category.

**When to use:** Grid browsing where visual differentiation helps users scan faster.

**Category Color + Icon Map (Claude's discretion — recommended values):**
```dart
const categoryMeta = {
  'Produce':       (color: Color(0xFF81C784), icon: Icons.eco),
  'Dairy':         (color: Color(0xFF64B5F6), icon: Icons.water_drop),
  'Meat':          (color: Color(0xFFE57373), icon: Icons.set_meal),
  'Seafood':       (color: Color(0xFF4DD0E1), icon: Icons.water),
  'Grains':        (color: Color(0xFFFFD54F), icon: Icons.grass),
  'Legumes':       (color: Color(0xFFA5D6A7), icon: Icons.spa),
  'Spices':        (color: Color(0xFFFF8A65), icon: Icons.local_fire_department),
  'Condiments':    (color: Color(0xFFCE93D8), icon: Icons.kitchen),
  'Oils':          (color: Color(0xFFFFF176), icon: Icons.opacity),
  'Beverages':     (color: Color(0xFF80DEEA), icon: Icons.local_cafe),
  'Baking':        (color: Color(0xFFBCAAA4), icon: Icons.cake),
  'Nuts & Seeds':  (color: Color(0xFFFFCC80), icon: Icons.grain),
};
```

### Pattern 7: OFf Branded Product Filtering (Claude's Discretion)

**What:** OFf `searchByCategory()` returns raw product data that includes branded products (e.g., "Heinz Diced Tomatoes 400g"). For ingredient selection, users need generic ingredient names (e.g., "Tomatoes").

**Filtering strategy (client-side, in `OpenFoodFactsRemoteSource`):**
1. Filter out products where `productName` contains a brand indicator — check if `brandsTags` is non-empty AND `productName` starts with a capitalized proper noun that matches a brand
2. Simpler heuristic: filter out products with parenthetical packaging info (contains `(`, `) `, `g`, `ml`, `oz` as suffix)
3. Deduplicate by normalized name (lowercase, strip punctuation) — keep only one result per unique base name
4. Prefer shorter names (generic names are usually shorter than branded variants)

**Recommended implementation:**
```dart
// In OpenFoodFactsRemoteSource._mapAndFilterProducts()
List<Ingredient> _filterBrandedProducts(List<Product> products) {
  final seen = <String>{};
  final result = <Ingredient>[];

  for (final product in products) {
    final name = product.productName?.trim() ?? '';
    if (name.isEmpty) continue;

    // Skip if name contains packaging indicators
    if (RegExp(r'\d+\s*(g|ml|oz|lb|kg|L)\b', caseSensitive: false).hasMatch(name)) continue;
    // Skip if name has parenthetical content typical of branded products
    if (name.contains('(') && name.contains(')')) continue;

    // Deduplicate by normalized base name
    final normalized = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    if (seen.contains(normalized)) continue;
    seen.add(normalized);

    result.add(_mapProductToIngredient(product, ''));
  }

  // Sort alphabetically (CONTEXT.md: alphabetical within each category)
  result.sort((a, b) => a.name.compareTo(b.name));
  return result;
}
```

### Anti-Patterns to Avoid

- **Full-screen spinner during loading:** CONTEXT.md locked decision — always use shimmer tiles, not `CircularProgressIndicator`
- **Calling OFf API directly from widgets:** Always go through `IngredientRepository`
- **Passing selected ingredient IDs as route arguments to Phase 4:** Phase 4 reads from `selectedTodayProvider` directly — no route params
- **Auto-disposing the selected-today provider:** Must use `@Riverpod(keepAlive: true)` so Phase 4 can read it
- **Using `StateProvider`:** Riverpod 3 — use `@riverpod` code-gen notifiers only
- **Bottom sheets for tile actions:** CONTEXT.md locked — inline heart + check icons only

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Shimmer loading animation | Custom `ShaderMask` + `AnimationController` | `shimmer` package `Shimmer.fromColors()` | 3 lines vs. ~50 lines; handles animation lifecycle and color transitions |
| Ingredient autocomplete taxonomy | Custom trie or local dictionary | `OpenFoodAPIClient.getSuggestions(TagType.INGREDIENTS)` | OFf has 175k+ ingredients in 30 languages; pre-curated local list covers common items |
| Debounce logic | Separate package or custom wrapper class | `Timer` in `AsyncNotifier` + `ref.onDispose()` | Riverpod lifecycle handles cancellation; 5 lines |
| Haptic feedback on Android/iOS | Platform channel calls | `HapticFeedback.lightImpact()` from `flutter/services.dart` | Already in Flutter SDK; one line |
| Scale animation for heart | Third-party animation package | `AnimationController` + `ScaleTransition` | No new dependency; sufficient for single-widget bounce animation |
| Category color/icon config | Runtime API call or CMS | Static `const Map` in Dart | Categories are stable; compile-time constant is instantaneous and offline-safe |

**Key insight:** The Flutter SDK and the three already-installed packages (`shimmer`, `openfoodfacts`, `flutter_riverpod`) cover every UX requirement. No new packages needed except `shimmer`.

---

## Common Pitfalls

### Pitfall 1: Shimmer replacing existing CircularProgressIndicator (breaking CONTEXT.md)
**What goes wrong:** Old loading states in `ingredient_search_screen.dart` and `ingredient_category_screen.dart` use `CircularProgressIndicator`. The CONTEXT.md decision requires shimmer tiles. If not replaced, both states exist inconsistently.
**Why it happens:** Plans 03-02 and 03-03 wrote the screens before the CONTEXT.md UX decisions were captured.
**How to avoid:** In each `AsyncLoading` branch of `.when()`, replace `CircularProgressIndicator` with the shimmer tile builder. Check every `.when()` call in the three ingredient screens.
**Warning signs:** `CircularProgressIndicator` visible in any ingredient screen during a loading state.

### Pitfall 2: SelectedTodayBar needs ingredient names, not just IDs
**What goes wrong:** The expandable pill bar shows ingredient IDs instead of names in the chips, or crashes because it has IDs but no name lookup.
**Why it happens:** `SelectedTodayNotifier` only stores `Set<String>` of IDs. The bar needs names for chips (e.g., "Tomatoes, Onions, +3 more").
**Why it happens:** The CONTEXT.md decision to show ingredient names was added after the provider was designed.
**How to avoid:** Extend `SelectedTodayNotifier` to also maintain a `Map<String, String>` mapping (id → name). The `toggle(ingredientId, {required String name})` method signature should be updated to accept the display name at toggle time.
**Warning signs:** Pill chips showing UUIDs or empty labels.

### Pitfall 3: OFf API rate limit exceeded during category load
**What goes wrong:** User rapidly taps between categories. Each category load fires a new OFf `searchProducts()` call. With the 10 req/min limit, the 11th call within a minute gets a 429 response.
**Why it happens:** `watchIngredientsByCategory` always attempts a remote fetch unless a recent cache exists.
**How to avoid:** In `IngredientRepository.watchIngredientsByCategory()`, check `cachedAt` before fetching — if cache is less than 1 hour old, skip the remote call. "Up to 50 per OFf page with pull-to-refresh" means the user explicitly triggers a fresh fetch, not automatic re-fetching.
**Warning signs:** `429 Too Many Requests` errors in debug console.

### Pitfall 4: Category screen passes OFf tag to `ingredientsByCategoryProvider` instead of display name
**What goes wrong:** `IngredientCategoryScreen` receives `categoryName` (e.g., "Produce") via route param but may pass the OFf tag (e.g., "en:fruits-and-vegetables") to the provider, breaking the Drift query which filters by display name.
**Why it happens:** The route param is the display name, but `watchIngredientsByCategory` uses display name for Drift AND maps to OFf tag internally. Passing the OFf tag directly bypasses the mapping.
**How to avoid:** Always pass the display name to `ingredientsByCategoryProvider`. The repository handles OFf tag lookup internally via `_getCategoryTag()`.
**Warning signs:** Category screen shows empty results despite data being in Drift.

### Pitfall 5: Animated heart AnimationController not disposed
**What goes wrong:** `AnimationController` created in a `State` object is not disposed in `dispose()`. Flutter debug mode prints "A ColorTween's begin value should not be null" or "flutter_animate is leaking".
**Why it happens:** `AnimationController` requires explicit `dispose()` — it does not auto-dispose with widget teardown.
**How to avoid:** Always call `_controller.dispose()` in the `State.dispose()` override.
**Warning signs:** "A ColorTween's begin value should not be null" or animation-leak errors in debug console.

### Pitfall 6: "Add all favorites" trigger logic
**What goes wrong:** "Add all favorites" calls `addSelectedToday` for each favorite individually via N separate Drift inserts, each triggering a provider rebuild. UI flickers N times.
**Why it happens:** Using the existing single-item `toggle()` method in a loop.
**How to avoid:** Add a dedicated `addAll(List<Ingredient> ingredients)` method to `SelectedTodayNotifier` that builds the full updated set in memory first, calls `upsertAll` on the repository once, then updates state once. This is a single state update, not N.
**Warning signs:** Visible list flicker or N rapid UI rebuilds when "Add all" is tapped.

### Pitfall 7: Riverpod 3 `ref.mounted` omission after async gap
**What goes wrong:** `state = AsyncData(result)` is called after the provider has been disposed (user navigated away during the API call). Riverpod 3 throws `StateError`.
**Why it happens:** Riverpod 3 breaking change vs. Riverpod 2 — post-disposal state assignment now throws.
**How to avoid:** Add `if (!ref.mounted) return;` after every `await` in any `AsyncNotifier`.
**Warning signs:** `StateError: The provider has already been disposed` in test logs.

---

## Code Examples

### Local Ingredient Search (INGR-01 fast path)
```dart
// Source: Pattern 2 in this document — local list first
// File: lib/core/assets/common_ingredients.dart
const List<String> commonIngredients = [
  'Apple', 'Apricot', 'Asparagus', 'Avocado', 'Banana', 'Basil', 'Bell Pepper',
  'Blackberry', 'Blueberry', 'Broccoli', 'Brussels Sprouts', 'Butter', 'Cabbage',
  'Carrot', 'Cauliflower', 'Celery', 'Cheddar Cheese', 'Cherry', 'Chicken',
  'Chickpeas', 'Cilantro', 'Coconut Milk', 'Corn', 'Cream Cheese', 'Cucumber',
  'Dill', 'Egg', 'Eggplant', 'Feta Cheese', 'Garlic', 'Ginger', 'Greek Yogurt',
  'Green Beans', 'Ground Beef', 'Ground Turkey', 'Ham', 'Heavy Cream', 'Honey',
  'Jalapeño', 'Kale', 'Lamb', 'Leek', 'Lemon', 'Lentils', 'Lettuce', 'Lime',
  'Mango', 'Milk', 'Mint', 'Mozzarella', 'Mushroom', 'Oats', 'Olive Oil',
  'Onion', 'Orange', 'Oregano', 'Parmesan', 'Parsley', 'Peach', 'Pear',
  'Peas', 'Pecan', 'Pineapple', 'Pork', 'Potato', 'Pumpkin', 'Quinoa',
  'Raspberry', 'Rice', 'Rosemary', 'Salmon', 'Scallion', 'Shrimp', 'Sour Cream',
  'Soy Sauce', 'Spinach', 'Strawberry', 'Sweet Potato', 'Thyme', 'Tofu',
  'Tomato', 'Tuna', 'Turkey', 'Turmeric', 'Vanilla', 'Walnut', 'Watermelon',
  'Whole Wheat Flour', 'Yogurt', 'Zucchini',
  // Baking
  'All-Purpose Flour', 'Baking Powder', 'Baking Soda', 'Brown Sugar', 'Butter',
  'Cocoa Powder', 'Cornstarch', 'Cream of Tartar', 'Powdered Sugar', 'White Sugar',
  'Yeast',
  // Nuts & Seeds
  'Almond', 'Cashew', 'Chia Seeds', 'Flaxseed', 'Hemp Seeds', 'Macadamia',
  'Peanut', 'Pine Nut', 'Pistachio', 'Pumpkin Seeds', 'Sesame Seeds', 'Sunflower Seeds',
  // ... extend to ~200 total
];
```

### Extended Category Map (INGR-02 — adds Baking, Nuts & Seeds)
```dart
// Source: Locked decision in CONTEXT.md — extend beyond 10 categories
// File: lib/features/ingredients/data/openfoodfacts_remote_source.dart
const ingredientCategories = {
  'Produce':       'en:fruits-and-vegetables',
  'Dairy':         'en:dairies',
  'Meat':          'en:meats',
  'Seafood':       'en:seafood',
  'Grains':        'en:cereals-and-potatoes',
  'Legumes':       'en:legumes-and-their-products',
  'Spices':        'en:spices',
  'Condiments':    'en:sauces',
  'Oils':          'en:fats',
  'Beverages':     'en:beverages',
  'Baking':        'en:baking-preparations',      // NEW
  'Nuts & Seeds':  'en:nuts-and-their-products',  // NEW
};
```

### Add All Favorites to Today (INGR-03 + INGR-05 bulk action)
```dart
// In SelectedTodayNotifier — add dedicated batch method
Future<void> addAll(List<Ingredient> ingredients) async {
  final repo = ref.read(ingredientRepositoryProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final current = state.value ?? {};
  final updated = Map<String, String>.from(/* current id->name map */);

  for (final ingredient in ingredients) {
    if (!current.contains(ingredient.id)) {
      await repo.addSelectedToday(ingredient.id, user.id);
      updated[ingredient.id] = ingredient.name;
    }
  }

  if (!ref.mounted) return;
  state = AsyncData(updated.keys.toSet());
}
```

### Pull-to-Refresh for Category Screen
```dart
// Source: Flutter docs — RefreshIndicator
@override
Widget build(BuildContext context, WidgetRef ref) {
  final ingredientsAsync = ref.watch(ingredientsByCategoryProvider(categoryName));

  return Scaffold(
    body: ingredientsAsync.when(
      loading: _buildShimmerList,
      error: (e, _) => _buildErrorState(context, ref, e),
      data: (ingredients) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ingredientsByCategoryProvider(categoryName));
          await ref.read(ingredientsByCategoryProvider(categoryName).future);
        },
        child: ListView.builder(/* ... */),
      ),
    ),
  );
}
```

### OFf User-Agent Configuration (must be called before any OFf API call)
```dart
// Source: pub.dev/packages/openfoodfacts README
// File: lib/core/config/openfoodfacts_config.dart
void configureOpenFoodFacts() {
  OpenFoodAPIConfiguration.userAgent = UserAgent(
    name: 'MealMate',
    version: '1.0.0',
  );
  OpenFoodAPIConfiguration.globalLanguages = [OpenFoodFactsLanguage.ENGLISH];
  OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.USA;
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `AutoDisposeAsyncNotifier`, `FamilyNotifier` | Single `Notifier` (auto-dispose and family are constructor params) | Riverpod 3.0, Sep 2025 | Remove all `AutoDispose*` type annotations; already done in existing providers |
| `StateProvider` for simple state | `@riverpod` code-gen notifier | Riverpod 3.0, Sep 2025 | Do not use `StateProvider` in new code |
| Generic `Ref` vs provider-specific Ref | Generic `Ref ref` parameter everywhere | Riverpod 3.0 | All `@riverpod` functions already use `Ref ref` in this project |
| Full-screen spinner during async load | Inline shimmer tile placeholders | UX best practice | Replace all `CircularProgressIndicator` in `.when(loading:)` branches |
| Single-screen ingredient UI | 2-tab screen (Search/Browse + Favorites) | CONTEXT.md decision, 2026-03-04 | Need new `IngredientMainScreen` wrapper; existing screens become tab children |

**Deprecated/outdated in this project:**
- `AutoDisposeNotifier` / `FamilyNotifier`: Not used anywhere — all providers are Riverpod 3 style.
- `StateNotifierProvider`: Not present in codebase.
- `CircularProgressIndicator` in ingredient loading states: Replace with shimmer per CONTEXT.md.

---

## Existing Implementation Status

### What 03-01 Built (COMPLETE, tests pass)
- `Ingredient` and `IngredientFilter` Freezed domain models
- `OpenFoodFactsRemoteSource` with `getSuggestions()` and `searchByCategory()` (10 categories)
- `IngredientLocalSource` with full Drift CRUD, dietary filter, favorites, selected-today
- `IngredientRepository` with pull-through cache pattern
- `ingredientRepositoryProvider` and `appDatabaseProvider`
- Drift schema v2: `ingredients` table (isFavorite, dietaryFlags, cachedAt) + `selectedTodayIngredients` table
- OFf SDK configured with MealMate User-Agent

### What 03-02 and 03-03 Built (SKELETON — needs UX enrichment)
All 5 providers exist and are correct. All 3 screens and 3 widgets have working skeleton implementations. Routes are registered. Tests for `selectedTodayProvider` and `ingredientRepository` pass.

**What is missing vs. CONTEXT.md locked decisions:**
1. `IngredientMainScreen` with 2-tab structure (Search/Browse + Favorites) — not yet created
2. Shimmer placeholders — screens still use `CircularProgressIndicator`
3. Animated heart + haptic feedback — `IngredientTile` uses plain `IconButton`
4. Dietary badges on tiles — `IngredientTile` does not show dietary flag chips
5. Expandable pill bar — `SelectedTodayBar` shows simple count row, not expandable with ingredient name chips
6. Colored category cards with icons — `IngredientSearchScreen` category grid uses plain `Card` with text only
7. Local ~200-ingredient list — search goes straight to OFf API, no local fast path
8. 2 new categories: Baking, Nuts & Seeds — `ingredientCategories` map has only 10 entries
9. "Quick-add favorites chips" at top of search screen — not implemented
10. "Add all favorites" bulk action — not implemented
11. Alphabetical sort within category — not implemented (OFf API order, not sorted)
12. Pull-to-refresh on category screen — not implemented

---

## Open Questions

1. **SelectedTodayNotifier state shape for pill bar ingredient names**
   - What we know: The bar needs ingredient names (not just IDs) for the chip display. Current `SelectedTodayNotifier` stores only `Set<String>` of IDs.
   - What's unclear: Whether to store `Map<String, String>` (id → name) in the notifier, or derive names from a separate provider watching both `selectedTodayProvider` and a cached ingredient lookup.
   - Recommendation: Extend `SelectedTodayNotifier` to maintain a `Map<String, String>` alongside the Set. The `toggle(id, {required String name})` signature accepts the name at toggle time. This is the simplest approach and avoids an async lookup chain.

2. **OFf `en:baking-preparations` and `en:nuts-and-their-products` tag validity**
   - What we know: These are the best-match OFf taxonomy tags for "Baking" and "Nuts & Seeds" based on OFf documentation review.
   - What's unclear: Whether these tags return enough products (vs. returning 0-5 results in the US country filter).
   - Recommendation: Implement them, but if initial testing shows sparse results, fall back to local-only for these two categories (the curated list has sufficient coverage for baking and nuts).

3. **Home screen navigation entry point**
   - What we know: `HomeScreen` is currently a placeholder (`Text('Home — MealMate')`). Ingredient feature needs to be accessible from home.
   - What's unclear: Whether Phase 3 should update HomeScreen to add navigation to ingredients, or whether this is deferred to a later phase.
   - Recommendation: Add a "Find Ingredients" card/button to HomeScreen that navigates to `/ingredients`. This is the minimum viable entry point without requiring a full navigation structure.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) + mocktail 1.0.4 |
| Config file | none — standard `flutter test` discovery |
| Quick run command | `flutter test test/features/ingredients/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INGR-01 | `searchSuggestions` returns results from OFf | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | Yes |
| INGR-01 | Local list matches before API call | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | No — Wave 0 gap |
| INGR-02 | `watchIngredientsByCategory` emits cached then fresh | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | Partial (pull-through tested) |
| INGR-03 | `toggleFavorite` flips isFavorite and sets syncStatus | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | Yes |
| INGR-04 | `filterByDietary` returns only matching-flag ingredients | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | Yes |
| INGR-05 | `toggle()` adds/removes IDs from selected-today set | unit | `flutter test test/features/ingredients/presentation/providers/selected_today_provider_test.dart` | Yes |
| INGR-05 | `clearAll()` empties state and Drift | unit | `flutter test test/features/ingredients/presentation/providers/selected_today_provider_test.dart` | Yes |
| INGR-05 | Selected-today scoped to today's date | unit | `flutter test test/features/ingredients/data/ingredient_repository_test.dart` | Yes |

### Sampling Rate
- **Per task commit:** `flutter test test/features/ingredients/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/features/ingredients/data/ingredient_repository_test.dart` — add test for local-first search (local list matched before OFf API call) — covers INGR-01 fast path
- [ ] `test/features/ingredients/data/ingredient_repository_test.dart` — add test for alphabetical sort within category
- [ ] No framework install needed — `flutter_test` and `mocktail` already in `pubspec.yaml`

---

## Sources

### Primary (HIGH confidence)
- `pub.dev/packages/openfoodfacts` (v3.11.0 in pubspec) — SDK already integrated; `getSuggestions` and `searchByCategory` verified working in Plan 03-01
- `pub.dev/packages/shimmer` — `Shimmer.fromColors()` API, latest version 3.0.0
- `api.flutter.dev/flutter/services/HapticFeedback/lightImpact.html` — `HapticFeedback.lightImpact()` official API docs
- `docs.flutter.dev/ui/animations` — `AnimationController` + `ScaleTransition` native Flutter animation
- Existing codebase — Plans 03-01/02/03 already executed; all files read directly

### Secondary (MEDIUM confidence)
- `pub.dev/packages/shimmer/versions` — version history confirms 3.0.0 is current stable
- `support.openfoodfacts.org` — rate limits: 10 req/min search, 2 req/min facet queries; User-Agent requirement
- WebSearch results for OFf branded product filtering — no single official source; filtering strategy is client-side heuristic (Claude's discretion per CONTEXT.md)

### Tertiary (LOW confidence)
- OFf taxonomy tags for `en:baking-preparations` and `en:nuts-and-their-products` — inferred from OFf taxonomy structure; should be verified against live API during implementation

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already in pubspec and verified working; `shimmer` is the only new addition
- Architecture: HIGH — data layer is complete and tested; UX patterns are locked in CONTEXT.md; existing code read directly
- Pitfalls: HIGH — identified from reading actual existing code and comparing against CONTEXT.md decisions; not speculation
- Missing features: HIGH — compared actual file contents line-by-line against CONTEXT.md decisions

**Research date:** 2026-03-04
**Valid until:** 2026-04-04 (stable Flutter/Riverpod/OFf SDK versions; shimmer package is mature)
