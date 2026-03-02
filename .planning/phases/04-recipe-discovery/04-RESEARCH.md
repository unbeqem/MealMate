# Phase 4: Recipe Discovery - Research

**Researched:** 2026-03-02
**Domain:** Spoonacular REST API, Flutter Dio HTTP client, Freezed models, Drift cache layer, Riverpod 3.x pagination and state
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| RECP-01 | User can browse recipes from external API with search by name, ingredient, cuisine, and cook time | Spoonacular `complexSearch` endpoint supports all four filter axes; Riverpod `FutureProvider.family` with page param enables paginated browsing |
| RECP-02 | User can view recipe details including ingredients list, step-by-step instructions, cook time, and servings | Spoonacular `GET /recipes/{id}/information` returns `extendedIngredients`, `analyzedInstructions`, `readyInMinutes`, `servings`; Freezed model maps directly |
| RECP-03 | User can scale recipe serving size and see adjusted ingredient quantities | Pure math: `scaledAmount = (original.amount / originalServings) * targetServings`; driven by local `Notifier` holding `int selectedServings` state |
| RECP-04 | User can discover recipes based on selected available ingredients ("use what you have") | Spoonacular `GET /recipes/findByIngredients` accepts comma-separated ingredient names; response includes `usedIngredients` / `missedIngredients` arrays |
</phase_requirements>

---

## Summary

Phase 4 is entirely driven by the Spoonacular REST API proxied through a Supabase Edge Function, with Drift as an offline read cache. The architecture is: Flutter app calls Edge Function (via `supabase.functions.invoke`) → Edge Function appends the Spoonacular API key and calls Spoonacular → response is returned to the app → the repository writes it to a Drift `cached_recipes` table with a `cached_at` timestamp → the UI reads from Drift, never from the network directly.

The three-plan structure maps cleanly to three technical concerns: (1) the data layer (API client + Freezed model + Drift schema), (2) the browse/search screen with pagination, and (3) the recipe detail screen with the serving scaler. Each layer is independently testable. The serving scaler is pure arithmetic — no third-party library is needed. Riverpod 3.x (AsyncNotifier + code generation) is the correct state management choice; `StateNotifierProvider` is now legacy.

The critical point cost to budget for is that `addRecipeInformation=true` on `complexSearch` adds 0.025 points per result. With 1,500 daily points on the Cook plan, a page of 20 results with full info costs 1 + (20 × 0.025) = 1.5 points, so ~1,000 full-info pages are possible per day before overage. For MVP this is sufficient; for production, return only `id`, `title`, `image` from `complexSearch` and fetch details lazily via `getRecipeInformation` when the user opens a recipe card.

**Primary recommendation:** Build a thin `RecipeRepository` that wraps the Edge Function call with a Dio client, maps responses to `@freezed` models, and writes to Drift. Every screen reads from Drift only — making offline a consequence of correct architecture, not an afterthought.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `dio` | 5.9.2 | HTTP client for Edge Function calls | Interceptor support for auth tokens, BaseOptions for base URL/timeout, standard Flutter HTTP library |
| `freezed` | 3.2.5 | Immutable Recipe, Ingredient, Instruction models | Generates `fromJson`/`toJson`, `copyWith`, equality — eliminates manual boilerplate |
| `freezed_annotation` | matches freezed | Annotations for code gen | Required companion to freezed |
| `json_serializable` | latest compatible | JSON serialization code gen | Required by freezed for `fromJson`/`toJson` |
| `drift` | 2.32.0 | SQLite-backed local cache for recipes | Type-safe queries, `.watch()` streams for reactive UI, established in project from Phase 1 |
| `riverpod` | 3.x (with codegen) | State management for search, pagination, detail state | Project standard; AsyncNotifier is the correct async pattern; codegen reduces boilerplate |
| `riverpod_annotation` | 3.x | `@riverpod` annotation for code gen | Project standard |
| `cached_network_image` | 3.4.1 | Recipe thumbnail display with disk cache | Prevents re-download, shows placeholder/error widget, built-in offline fallback |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `build_runner` | latest | Code generation runner | Required for freezed + riverpod + drift codegen |
| `supabase_flutter` | project version | `supabase.functions.invoke()` to call Edge Function proxy | Used instead of calling Spoonacular directly from the app |
| `connectivity_plus` | project version | Detect offline state for offline indicator | Show "cached" indicator on recipe detail when offline |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Supabase Edge Function proxy | Call Spoonacular directly from app | Direct call exposes API key in Flutter bundle — ruled out in STATE.md; Edge Function is the locked decision |
| `cached_network_image` | `flutter_cache_manager` directly | `cached_network_image` wraps it with a widget — simpler for recipe cards |
| `drift` for recipe cache | `hive` for recipe cache | Drift is already the project DB (Phase 1); using two databases adds complexity with no benefit |
| Riverpod codegen | Manual provider declaration | Codegen is the Riverpod 3.x recommended path; removes auto-dispose and family boilerplate |

**Installation (additions for this phase, on top of Phase 1 baseline):**
```bash
flutter pub add dio freezed_annotation json_annotation riverpod_annotation cached_network_image
flutter pub add --dev freezed json_serializable build_runner riverpod_generator
```

---

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── features/
│   └── recipes/
│       ├── data/
│       │   ├── spoonacular_client.dart        # Dio client → Edge Function proxy
│       │   ├── recipe_repository.dart         # Fetch + cache coordination
│       │   └── recipe_cache_dao.dart          # Drift DAO for cached_recipes table
│       ├── domain/
│       │   ├── recipe.dart                    # @freezed Recipe model
│       │   ├── recipe.freezed.dart            # generated
│       │   ├── recipe.g.dart                  # generated
│       │   ├── extended_ingredient.dart       # @freezed ingredient sub-model
│       │   └── analyzed_instruction.dart      # @freezed step sub-model
│       └── presentation/
│           ├── recipe_browse_screen.dart      # search bar + filter chips + paginated list
│           ├── recipe_detail_screen.dart      # ingredients, steps, serving scaler
│           ├── recipe_card.dart               # thumbnail card widget
│           ├── providers/
│           │   ├── recipe_search_provider.dart    # @riverpod AsyncNotifier for search
│           │   └── recipe_detail_provider.dart    # @riverpod for detail + serving state
│           └── widgets/
│               ├── filter_chips_row.dart
│               ├── serving_scaler_widget.dart
│               └── ingredient_list_tile.dart
```

### Pattern 1: Edge Function Proxy Client (Spoonacular via Supabase)

**What:** The `SpoonacularClient` calls `supabase.functions.invoke('spoonacular-proxy')` passing the path and query params in the body. The Edge Function (Deno/TypeScript) reads the Spoonacular API key from an environment variable and forwards the call.
**When to use:** Any time recipe data is needed from Spoonacular. Never call Spoonacular directly from the Flutter bundle.

```dart
// Source: Supabase Dart reference https://supabase.com/docs/reference/dart/functions-invoke
// lib/features/recipes/data/spoonacular_client.dart

class SpoonacularClient {
  final SupabaseClient _supabase;

  SpoonacularClient(this._supabase);

  Future<Map<String, dynamic>> complexSearch({
    String? query,
    String? cuisine,
    int? maxReadyTime,
    String? includeIngredients,
    int offset = 0,
    int number = 20,
  }) async {
    final response = await _supabase.functions.invoke(
      'spoonacular-proxy',
      body: {
        'path': '/recipes/complexSearch',
        'params': {
          if (query != null) 'query': query,
          if (cuisine != null) 'cuisine': cuisine,
          if (maxReadyTime != null) 'maxReadyTime': maxReadyTime,
          if (includeIngredients != null) 'includeIngredients': includeIngredients,
          'offset': offset,
          'number': number,
          // Do NOT pass addRecipeInformation here — fetch detail lazily
        },
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRecipeInformation(int recipeId) async {
    final response = await _supabase.functions.invoke(
      'spoonacular-proxy',
      body: {
        'path': '/recipes/$recipeId/information',
        'params': {'includeNutrition': false},
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> findByIngredients(List<String> ingredients) async {
    final response = await _supabase.functions.invoke(
      'spoonacular-proxy',
      body: {
        'path': '/recipes/findByIngredients',
        'params': {
          'ingredients': ingredients.join(','),
          'number': 20,
          'ranking': 1, // maximize used ingredients
          'ignorePantry': true,
        },
      },
    );
    return response.data as List<dynamic>;
  }
}
```

The corresponding Edge Function (TypeScript/Deno) structure:
```typescript
// supabase/functions/spoonacular-proxy/index.ts
Deno.serve(async (req) => {
  const { path, params } = await req.json();
  const apiKey = Deno.env.get('SPOONACULAR_API_KEY');
  const url = new URL(`https://api.spoonacular.com${path}`);
  url.searchParams.set('apiKey', apiKey!);
  Object.entries(params ?? {}).forEach(([k, v]) =>
    url.searchParams.set(k, String(v))
  );
  const upstream = await fetch(url.toString());
  const data = await upstream.json();
  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

### Pattern 2: Freezed Recipe Model

**What:** A `@freezed` sealed class that mirrors the Spoonacular `getRecipeInformation` response. Sub-models for `ExtendedIngredient` and `AnalyzedInstruction` are also `@freezed`.
**When to use:** Every time recipe data is passed between layers.

```dart
// Source: Freezed pub.dev https://pub.dev/packages/freezed (v3.2.5)
// lib/features/recipes/domain/recipe.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

@freezed
sealed class Recipe with _$Recipe {
  const factory Recipe({
    required int id,
    required String title,
    String? image,
    required int servings,
    required int readyInMinutes,
    @Default([]) List<ExtendedIngredient> extendedIngredients,
    @Default([]) List<AnalyzedInstruction> analyzedInstructions,
    // summary from complexSearch (lightweight, no ingredients/instructions)
    @Default(false) bool isSummaryOnly,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}

@freezed
sealed class ExtendedIngredient with _$ExtendedIngredient {
  const factory ExtendedIngredient({
    required int id,
    required String name,
    required double amount,
    required String unit,
    String? original, // human-readable string e.g. "2 cups chopped onion"
  }) = _ExtendedIngredient;

  factory ExtendedIngredient.fromJson(Map<String, dynamic> json) =>
      _$ExtendedIngredientFromJson(json);
}

@freezed
sealed class AnalyzedInstruction with _$AnalyzedInstruction {
  const factory AnalyzedInstruction({
    @Default('') String name,
    @Default([]) List<InstructionStep> steps,
  }) = _AnalyzedInstruction;

  factory AnalyzedInstruction.fromJson(Map<String, dynamic> json) =>
      _$AnalyzedInstructionFromJson(json);
}

@freezed
sealed class InstructionStep with _$InstructionStep {
  const factory InstructionStep({
    required int number,
    required String step,
  }) = _InstructionStep;

  factory InstructionStep.fromJson(Map<String, dynamic> json) =>
      _$InstructionStepFromJson(json);
}
```

### Pattern 3: Drift Cache Table for Recipes

**What:** Drift table storing recipes as raw JSON text plus a `cached_at` timestamp. The repository checks cache freshness before hitting the API.
**When to use:** On every recipe detail load — check Drift first, call Edge Function only on cache miss.

```dart
// Source: Drift docs https://drift.simonbinder.eu/docs/getting-started/
// lib/features/recipes/data/recipe_cache_dao.dart (table definition in app_database.dart from Phase 1)

// Table definition (add to app_database.dart alongside other Phase 1 tables):
class CachedRecipes extends Table {
  IntColumn get id => integer()(); // Spoonacular recipe id (not UUID — external key)
  TextColumn get title => text()();
  TextColumn get image => text().nullable()();
  TextColumn get jsonData => text()(); // full JSON from getRecipeInformation
  BoolColumn get isSummaryOnly => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// DAO
part of 'app_database.dart';

@DriftAccessor(tables: [CachedRecipes])
class RecipeCacheDao extends DatabaseAccessor<AppDatabase>
    with _$RecipeCacheDaoMixin {
  RecipeCacheDao(super.db);

  static const Duration _ttl = Duration(hours: 24);

  Future<CachedRecipe?> getById(int id) =>
      (select(cachedRecipes)..where((r) => r.id.equals(id))).getSingleOrNull();

  bool isFresh(CachedRecipe row) =>
      DateTime.now().difference(row.cachedAt) < _ttl;

  Future<void> upsert(CachedRecipe row) =>
      into(cachedRecipes).insertOnConflictUpdate(row);

  Future<List<CachedRecipe>> getSummaryPage(int offset, int limit) =>
      (select(cachedRecipes)
            ..where((r) => r.isSummaryOnly.equals(true))
            ..limit(limit, offset: offset))
          .get();
}
```

### Pattern 4: Riverpod 3.x Pagination for Browse Screen

**What:** A `FutureProvider.family` (or `@riverpod` equivalent) keyed by `(query, cuisine, maxReadyTime, page)` tuple. `ListView.builder` calculates which page each index falls on and watches the corresponding provider.
**When to use:** Recipe browse screen — enables cache-per-page with Riverpod and infinite scroll without a third-party package.

```dart
// Source: https://codewithandrea.com/articles/flutter-riverpod-pagination/
// lib/features/recipes/presentation/providers/recipe_search_provider.dart

part 'recipe_search_provider.g.dart';

@riverpod
Future<RecipeSearchResult> recipeSearchPage(
  Ref ref, {
  required String query,
  String? cuisine,
  int? maxReadyTime,
  String? includeIngredients,
  required int page,
}) async {
  const int pageSize = 20;
  final client = ref.watch(spoonacularClientProvider);
  final raw = await client.complexSearch(
    query: query,
    cuisine: cuisine,
    maxReadyTime: maxReadyTime,
    includeIngredients: includeIngredients,
    offset: page * pageSize,
    number: pageSize,
  );
  return RecipeSearchResult.fromJson(raw);
}

// Use in ListView.builder:
// final page = index ~/ pageSize;
// final indexInPage = index % pageSize;
// final result = ref.watch(recipeSearchPageProvider(query: ..., page: page));
```

### Pattern 5: Serving Scaler — Pure Local State

**What:** A `Notifier` holding `selectedServings` as an `int`. The UI computes scaled amounts as `(ingredient.amount / recipe.servings) * selectedServings` at build time. No API call, no cache update.
**When to use:** Recipe detail screen only. Do not persist scaled state — it is ephemeral UI state.

```dart
// lib/features/recipes/presentation/providers/recipe_detail_provider.dart

part 'recipe_detail_provider.g.dart';

@riverpod
class ServingSizeNotifier extends _$ServingSizeNotifier {
  @override
  int build(int originalServings) => originalServings;

  void increment() => state = state + 1;
  void decrement() {
    if (state > 1) state = state - 1;
  }
  void setTo(int value) {
    if (value >= 1) state = value;
  }
}

// In widget:
// final servings = ref.watch(servingSizeNotifierProvider(recipe.servings));
// final scaledAmount = (ingredient.amount / recipe.servings) * servings;
```

### Anti-Patterns to Avoid

- **Calling Spoonacular directly from the Flutter app:** Embeds the API key in the APK/IPA, which is extractable. Always route through the Edge Function proxy.
- **Fetching full recipe info in complexSearch:** Adding `addRecipeInformation=true` to every search result multiplies point consumption (0.025 pts/result). Fetch details lazily on tap.
- **Storing scaled ingredient amounts in Drift:** Scaling is ephemeral UI state. Store only original amounts; scale at render time.
- **Using `StateNotifierProvider` for the serving scaler:** Riverpod 3.x marks it as legacy (moved to `riverpod/legacy.dart`). Use `Notifier` or `@riverpod` annotation.
- **Re-fetching detail on every navigation:** The Drift cache (24-hour TTL) should serve most detail opens without network. Only bypass cache when TTL is expired or item is missing.
- **findByIngredients with full ingredient objects:** This endpoint takes plain ingredient name strings (e.g., `"chicken,rice"`), not ingredient IDs. Map `INGR-05` selected ingredients to their name strings before calling.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP client with interceptors | Custom Dart `http` wrapper | `dio` 5.9.2 | Interceptors for auth headers, timeout config, retry logic already built in |
| Image disk caching | Manual `File` cache management | `cached_network_image` 3.4.1 | Handles memory + disk cache, placeholder widget, error widget, offline read |
| Immutable model boilerplate | Hand-written `copyWith`, `==`, `hashCode`, `fromJson` | `freezed` 3.2.5 | Recipe models have 8+ fields and nested sub-models — hand-rolling is error-prone |
| Pagination tracking | Manual `offset` counter in a `StatefulWidget` | Riverpod `FutureProvider.family` with `page` key | Riverpod caches each page separately; invalidation is `ref.invalidate` |
| API key proxy | Custom server endpoint | Supabase Edge Function | Already scaffolded in Phase 1 (plan 01-05); Deno runtime, global edge, environment variables for secrets |
| JSON serialization | Manual `Map<String, dynamic>` parsing for nested models | `json_serializable` (via freezed) | `extendedIngredients` is a list of objects; manual parsing accumulates bugs |

**Key insight:** The Spoonacular response structures are deeply nested (`analyzedInstructions[].steps[].ingredients[]`). Manual JSON parsing at this depth is where most bugs originate in recipe apps.

---

## Common Pitfalls

### Pitfall 1: Point Quota Bleed from addRecipeInformation

**What goes wrong:** Developer adds `addRecipeInformation=true` to every complexSearch call to avoid a second API call. With 20 results per page, this adds 0.5 points per search. At 10 searches, 5 points are consumed. Heavy use burns the 1,500 daily quota quickly.
**Why it happens:** Convenience optimization that ignores cost model.
**How to avoid:** Return only `{id, title, image}` from `complexSearch`. Cache the summary in Drift with `isSummaryOnly = true`. When the user taps a recipe, check Drift for a full cached entry; if missing or stale, call `getRecipeInformation` (1 point) to fetch the full record.
**Warning signs:** Daily quota exhausted before end of business during development testing.

### Pitfall 2: Spoonacular 402 Error Not Mapped

**What goes wrong:** When daily quota is exhausted, Spoonacular returns HTTP 402 "Payment Required". If the app doesn't handle this specifically, it surfaces as a generic error or crash.
**Why it happens:** 402 is uncommon — most error handling focuses on 400, 401, 404, 5xx.
**How to avoid:** In the Edge Function, pass the Spoonacular status code back in the response body or as a custom header. In the Dio error handler, catch 402 and display "Daily recipe limit reached. Try again tomorrow."
**Warning signs:** App shows generic "Something went wrong" when quota is hit.

### Pitfall 3: findByIngredients Returns Summary, Not Full Detail

**What goes wrong:** Developer assumes `findByIngredients` returns the same response shape as `getRecipeInformation`. It does not. It returns `{id, title, image, usedIngredients[], missedIngredients[], usedIngredientCount, missedIngredientCount}` — no `extendedIngredients`, no instructions.
**Why it happens:** Endpoint names sound similar; documentation not checked.
**How to avoid:** After calling `findByIngredients` to get the list of matching recipe IDs, call `getRecipeInformation` for each recipe the user actually taps. Store only the summary (with `isSummaryOnly=true`) after the ingredients search.
**Warning signs:** `recipe.extendedIngredients` is always empty on the "use my ingredients" results screen.

### Pitfall 4: Drift Schema Conflict with Phase 1 Tables

**What goes wrong:** Phase 4 adds `CachedRecipes` table but the Phase 1 `AppDatabase` was initialized without it. Adding a table to an existing Drift database requires a migration, otherwise `MigrationException` at startup.
**Why it happens:** Phase 1 creates the Drift database; Phase 4 extends it. If `schemaVersion` is not bumped and a migration added, Drift throws.
**How to avoid:** Increment `schemaVersion` in `AppDatabase` when adding `CachedRecipes`. Add a migration: `onCreate` is for fresh installs; `onUpgrade` with `createTable(cachedRecipes)` handles upgrades.
**Warning signs:** App crashes immediately after Phase 4 install on a device that already ran Phase 1-3.

### Pitfall 5: Serving Scaler Floating Point Display

**What goes wrong:** Scaled amount shows as `"0.6666666666666666 cups"` instead of `"0.67 cups"` or `"2/3 cup"`.
**Why it happens:** `double` arithmetic on fractional amounts produces trailing decimals.
**How to avoid:** Format with `.toStringAsFixed(2)` and strip trailing zeros, or round to nearest common fraction (1/4, 1/3, 1/2, 2/3, 3/4). A helper function `formatAmount(double amount)` that returns a `String` handles this in one place.
**Warning signs:** Ingredient amounts on detail screen show 8+ decimal places.

### Pitfall 6: Riverpod StateNotifier Pattern in New Code

**What goes wrong:** Developer copies patterns from Phase 2/3 code written before Riverpod 3.0 and uses `StateNotifier` + `StateNotifierProvider` for the serving size scaler.
**Why it happens:** Existing codebase examples, Stack Overflow answers, and many tutorials still show the old pattern.
**How to avoid:** Use `Notifier` (extends `_$ServingSizeNotifier`) with `@riverpod` annotation. The old `StateNotifierProvider` is now in `import 'package:riverpod/legacy.dart'` — if you see that import, you're using a legacy API.
**Warning signs:** Import of `riverpod/legacy.dart` in any Phase 4 file.

---

## Code Examples

Verified patterns from official sources:

### Dio BaseOptions Setup for Edge Function Base URL
```dart
// Source: Dio pub.dev https://pub.dev/packages/dio (v5.9.2)
final options = BaseOptions(
  baseUrl: 'https://<project-ref>.supabase.co/functions/v1',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 15),
  headers: {
    'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken}',
    'apikey': supabaseAnonKey,
  },
);
final dio = Dio(options);

// Adding an auth refresh interceptor:
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
      final token = supabase.auth.currentSession?.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ),
);
```

### complexSearch Response Model
```dart
// Source: Spoonacular docs https://spoonacular.com/food-api/docs#Search-Recipes-Complex
@freezed
sealed class RecipeSearchResult with _$RecipeSearchResult {
  const factory RecipeSearchResult({
    required int offset,
    required int number,
    required int totalResults,
    @Default([]) List<RecipeSummary> results,
  }) = _RecipeSearchResult;

  factory RecipeSearchResult.fromJson(Map<String, dynamic> json) =>
      _$RecipeSearchResultFromJson(json);
}

@freezed
sealed class RecipeSummary with _$RecipeSummary {
  const factory RecipeSummary({
    required int id,
    required String title,
    String? image,
    String? imageType,
  }) = _RecipeSummary;

  factory RecipeSummary.fromJson(Map<String, dynamic> json) =>
      _$RecipeSummaryFromJson(json);
}
```

### Drift Table with cachedAt TTL Pattern
```dart
// Source: Drift docs https://drift.simonbinder.eu/docs/getting-started/
class CachedRecipes extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get image => text().nullable()();
  TextColumn get jsonData => text()(); // serialized full Recipe JSON
  BoolColumn get isSummaryOnly =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// TTL check (in DAO or Repository):
bool _isFresh(DateTime cachedAt) =>
    DateTime.now().difference(cachedAt) < const Duration(hours: 24);
```

### CachedNetworkImage for Recipe Cards
```dart
// Source: cached_network_image pub.dev https://pub.dev/packages/cached_network_image (v3.4.1)
CachedNetworkImage(
  imageUrl: recipe.image ?? '',
  width: 120,
  height: 90,
  fit: BoxFit.cover,
  placeholder: (context, url) => const ColoredBox(
    color: Color(0xFFE0E0E0),
    child: Center(child: CircularProgressIndicator()),
  ),
  errorWidget: (context, url, error) => const Icon(Icons.restaurant),
)
```

### Serving Scaler — Scaled Amount Formatting
```dart
// Pure Dart — no dependency
String formatAmount(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toInt().toString();
  }
  // Round to 2 decimal places, strip trailing zeros
  final str = amount.toStringAsFixed(2);
  return str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

// In widget:
final scaledAmount = (ingredient.amount / recipe.servings) * selectedServings;
Text('${formatAmount(scaledAmount)} ${ingredient.unit}')
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `StateNotifier` + `StateNotifierProvider` | `Notifier` / `AsyncNotifier` + `@riverpod` codegen | Riverpod 3.0 (Sep 2025) | Legacy APIs moved to `riverpod/legacy.dart`; use Notifier hierarchy for all new state |
| `freezed` abstract class syntax | `freezed` sealed class syntax | freezed ~2.4+ | `sealed` keyword enables exhaustive pattern matching; use `sealed class` |
| Direct Spoonacular call from Flutter | Supabase Edge Function proxy | Project decision (STATE.md) | API key never appears in Flutter bundle |
| `addRecipeInformation=true` in search | Lazy-load detail via `getRecipeInformation` | Best practice | Reduces point consumption significantly on browse screens |

**Deprecated/outdated:**
- `StateNotifierProvider` from `riverpod`: Still functional but legacy — import path changed to `riverpod/legacy.dart` in Riverpod 3.0; any new code should use `Notifier`
- `abstract class` syntax in freezed: Works but `sealed class` is preferred for exhaustive switch support

---

## Open Questions

1. **Drift schema version from Phase 1**
   - What we know: Phase 1 plan 01-02 creates `AppDatabase` with `schemaVersion`; CachedRecipes is a new table
   - What's unclear: The exact `schemaVersion` number established in Phase 1 (not yet built)
   - Recommendation: When implementing Phase 4, check `AppDatabase.schemaVersion`, increment it by 1, and add `createTable(cachedRecipes)` in the migration block

2. **Spoonacular cuisine and diet enumeration**
   - What we know: The `cuisine` and `diet` parameters exist on `complexSearch`
   - What's unclear: The complete list of accepted cuisine strings (e.g., "Italian", "italian", "ITALIAN" — case sensitivity)
   - Recommendation: Fetch the full list from `GET /recipes/cuisines` (if available) or hard-code the known set from Spoonacular docs at implementation time; verify case sensitivity with a test call

3. **Edge Function HTTP method for GET-like requests**
   - What we know: `supabase.functions.invoke` defaults to POST; Spoonacular endpoints are GET
   - What's unclear: Whether the Edge Function must translate POST→GET internally (it does, based on the proxy pattern above) or whether `invoke` can send GET directly
   - Recommendation: The proxy pattern (Edge Function always receives POST, calls Spoonacular via GET internally) is the correct architecture; this is not a blocker

4. **findByIngredients ingredient name format**
   - What we know: The parameter is a comma-separated string of ingredient names
   - What's unclear: Whether Spoonacular matches fuzzy (e.g., "chicken breast" vs "chicken") or requires exact canonical names
   - Recommendation: Use the `name` field from Phase 3's OpenFoodFacts ingredient objects, which are human-readable. If zero results are returned, fall back to stripping modifiers (e.g., "boneless chicken breast" → "chicken").

---

## Sources

### Primary (HIGH confidence)
- Spoonacular official docs https://spoonacular.com/food-api/docs — complexSearch parameters, response structure, findByIngredients response fields
- Spoonacular pricing page https://spoonacular.com/food-api/pricing — Cook plan 1,500 daily points, point cost formula
- Supabase Dart reference https://supabase.com/docs/reference/dart/functions-invoke — `functions.invoke()` signature and auth header pattern
- Freezed pub.dev https://pub.dev/packages/freezed — version 3.2.5, sealed class syntax, `fromJson` factory pattern
- Drift pub.dev https://pub.dev/packages/drift — version 2.32.0, table definition syntax, column types
- Dio pub.dev https://pub.dev/packages/dio — version 5.9.2, `BaseOptions`, interceptor pattern
- cached_network_image pub.dev https://pub.dev/packages/cached_network_image — version 3.4.1, widget API
- Riverpod 3.0 what's new https://riverpod.dev/docs/whats_new — legacy API list, AsyncNotifier, automatic retry

### Secondary (MEDIUM confidence)
- codewithandrea.com Flutter Riverpod pagination article — `FutureProvider.family` with page key, ListView.builder index calculation; verified against Riverpod docs
- Supabase Edge Functions quickstart https://supabase.com/docs/guides/functions/quickstart — Deno runtime, `Deno.env.get()` for secrets

### Tertiary (LOW confidence)
- Various Medium articles on Freezed + json_serializable patterns — consistent with official docs but unverified independently
- Community patterns for Drift TTL caching — widely used pattern but no single authoritative source

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions verified directly from pub.dev and official pricing pages
- Architecture (Edge Function proxy): HIGH — pattern verified against Supabase Dart reference docs
- Architecture (Riverpod pagination): HIGH — verified against codewithandrea.com (primary Riverpod resource) + Riverpod official docs
- Pitfalls (point quota): HIGH — verified against Spoonacular official pricing with exact numbers
- Pitfalls (Riverpod legacy API): HIGH — verified against Riverpod 3.0 official changelog
- Pitfalls (findByIngredients shape): MEDIUM — response structure described in official docs, schema confirmed via multiple sources, but not personally tested

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (Spoonacular pricing/quotas stable; Riverpod 3.x API stable; Drift and Dio APIs stable; re-verify if any major version bump appears in pub.dev before planning)
