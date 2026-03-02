# Phase 3: Ingredient Selection - Research

**Researched:** 2026-03-02
**Domain:** External API integration (OpenFoodFacts), autocomplete UI, Drift caching, Riverpod 3 state management
**Confidence:** MEDIUM-HIGH

---

## Summary

Phase 3 builds the ingredient data layer and selection UI on top of the Foundation (Phase 1) and Auth (Phase 2) scaffolding. The two primary technical domains are (1) integrating the OpenFoodFacts Dart SDK for autocomplete search and (2) managing ingredient state — favorites, dietary filters, and the ephemeral "I have these today" selection — with Riverpod 3 and Drift.

The OpenFoodFacts Dart package (`openfoodfacts` 3.30.x) provides a first-class `getSuggestions()` method backed by the v3 taxonomy suggestions endpoint. This is the correct primitive for INGR-01 autocomplete; it returns canonical ingredient strings, not products. Category browsing (INGR-02) cannot be driven purely from the live API within the rate limits (2 req/min for facet queries) — a curated static category list with on-demand API calls is the appropriate strategy. Dietary filtering (INGR-04) is supported via `IngredientsAnalysisParameter` for vegan/vegetarian and via `labels_tags` for gluten-free and dairy-free, but because the API returns products (not ingredient names), filtering must be applied at the Drift cache layer for the ingredient selection context.

Riverpod 3 (released September 2025) is the correct version to target. It consolidates `AutoDisposeNotifier`/`FamilyNotifier` into a single `Notifier`, moves legacy providers to `riverpod/legacy.dart`, and adds a mandatory `Ref.mounted` check after async gaps. The debounce-within-provider pattern (using `Future.delayed` + `ref.onDispose`) is idiomatic for driving autocomplete without an external debounce library.

**Primary recommendation:** Use `OpenFoodAPIClient.getSuggestions(TagType.INGREDIENTS, ...)` for autocomplete, a static category seed list for browsing, `IngredientsAnalysisParameter` for API-side dietary filtering where applicable, Drift for all persistence, and Riverpod 3 `AsyncNotifier` with in-provider debounce for the search state.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INGR-01 | User can search ingredients from external API with autocomplete | `OpenFoodAPIClient.getSuggestions(TagType.INGREDIENTS)` + in-provider debounce at ~300ms to meet 500ms UX target |
| INGR-02 | User can browse ingredients by category | Static category list (produce, dairy, meat, grains, seafood, legumes, spices, condiments) seeded at app start; each category triggers a filtered OpenFoodFacts product search using `categories_tags` |
| INGR-03 | User can add ingredients to favorites for quick access | `is_favorite` boolean column on `ingredients` Drift table; toggled via `IngredientRepository`; synced to Supabase via `sync_status` pattern from Phase 1 schema |
| INGR-04 | User can filter ingredients by dietary restrictions (vegetarian, vegan, gluten-free, dairy-free) | `IngredientsAnalysisParameter` for vegan/vegetarian in API queries; gluten-free/dairy-free applied as Drift WHERE clause against `dietary_flags` JSON column populated at cache-write time |
| INGR-05 | User can select "I have these today" for recipe discovery | Ephemeral `Set<String>` of ingredient IDs in a Riverpod `Notifier`; persisted to a `selected_today_ingredients` Drift table so Phase 4 can query it; cleared on a new day |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| openfoodfacts | 3.30.2 | OpenFoodFacts API wrapper — ingredient autocomplete, product search, dietary tag parsing | Official Dart SDK published by openfoodfacts.org; provides type-safe API over raw HTTP; used by the official OFf Flutter app (smooth-app) |
| flutter_riverpod + riverpod_annotation | 3.x (released Sep 2025) | State management — search query, favorites, filters, selected-today set | Project-wide decision (see STATE.md); Riverpod 3 consolidates the notifier API and is the current stable release |
| riverpod_generator | 3.x | Code-gen for `@riverpod` annotations; removes boilerplate | Pairs with riverpod_annotation; project already adopted code-gen pattern |
| drift | latest (2.x) | Local SQLite — caches fetched ingredients, persists favorites and selected-today | Project-wide decision; Phase 1 already defines the schema skeleton |
| dio | 5.x | HTTP client for any direct REST calls not covered by the OFf SDK | Project-wide decision; already used for Spoonacular proxy |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| freezed + freezed_annotation | 2.x | Immutable value objects for `Ingredient`, `IngredientFilter` models | All domain models in this project use freezed (project convention) |
| json_serializable | 4.x | JSON ↔ model serialization for OFf API responses | Pairs with freezed for JSON round-tripping |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| openfoodfacts SDK | Raw Dio + manual parsing | Raw approach is ~300 lines of parsing code; SDK handles encoding, language negotiation, pagination, and rate-limit headers |
| In-provider debounce via `Future.delayed` | `flutter_typeahead` package | `flutter_typeahead` 5.2.0 was published 2 years ago and adds a UI dependency; in-provider debounce keeps UI layer thin and is the Riverpod-idiomatic approach |
| Static category list | API-driven category taxonomy | Facet queries are rate-limited to 2/min; static list is instantaneous, offline-safe, and covers 90% of ingredient categories |

**Installation:**
```bash
flutter pub add openfoodfacts flutter_riverpod riverpod_annotation riverpod_generator drift drift_flutter freezed_annotation json_serializable dio
flutter pub add --dev build_runner drift_dev freezed
```

---

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── features/
│   └── ingredients/
│       ├── data/
│       │   ├── ingredient_repository.dart       # Single source of truth
│       │   ├── openfoodfacts_remote_source.dart  # OFf SDK calls
│       │   └── ingredient_local_source.dart      # Drift queries
│       ├── domain/
│       │   ├── ingredient.dart                   # freezed model
│       │   └── ingredient_filter.dart            # freezed model for dietary filters
│       └── presentation/
│           ├── ingredient_search_screen.dart
│           ├── ingredient_category_screen.dart
│           ├── ingredient_favorites_screen.dart
│           └── providers/
│               ├── ingredient_search_provider.dart
│               ├── ingredient_favorites_provider.dart
│               ├── ingredient_filter_provider.dart
│               └── selected_today_provider.dart
```

### Pattern 1: Debounced Async Search Provider (INGR-01)

**What:** An `AsyncNotifier` that holds the query string and debounces API calls using `Future.delayed` + `ref.onDispose`. The widget layer only updates the query string; the provider handles timing and cancellation.

**When to use:** Any user-input-driven API call where you must suppress intermediate requests.

**Example:**
```dart
// Source: Riverpod 3 docs + riverpod.dev/docs/whats_new
@riverpod
class IngredientSearch extends _$IngredientSearch {
  Timer? _debounce;

  @override
  FutureOr<List<String>> build() => [];

  Future<void> search(String query) async {
    _debounce?.cancel();
    if (query.length < 2) {
      state = const AsyncData([]);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(
        () => OpenFoodAPIClient.getSuggestions(
          TagType.INGREDIENTS,
          input: query,
          language: OpenFoodFactsLanguage.ENGLISH,
          limit: 20,
        ),
      );
    });

    ref.onDispose(() => _debounce?.cancel());
  }
}
```

The 300ms debounce is below the 500ms UX target from INGR-01 success criteria, giving a comfortable margin for network latency.

### Pattern 2: Pull-Through Cache in IngredientRepository (INGR-01, INGR-02)

**What:** Repository checks Drift first. On miss, calls the remote source, writes to Drift, then returns. All reads flow through the repository — the presentation layer never touches OFf SDK directly.

**When to use:** Any data that should be available offline after first fetch.

**Example:**
```dart
// Source: Flutter offline-first docs (docs.flutter.dev/app-architecture/design-patterns/offline-first)
Stream<List<Ingredient>> watchIngredientsByCategory(String category) async* {
  // 1. Emit cached data immediately
  yield await _localSource.getIngredientsByCategory(category);

  // 2. Fetch fresh data and update cache
  try {
    final remote = await _remoteSource.fetchByCategory(category);
    await _localSource.upsertAll(remote);
    yield remote;
  } catch (_) {
    // Cached data already emitted; silent failure is acceptable here
  }
}
```

### Pattern 3: Favorite Toggle with Optimistic Write (INGR-03)

**What:** Write the toggled state to Drift immediately (optimistic), then sync to Supabase asynchronously via the `sync_status` pattern established in Phase 1. Never wait for Supabase confirmation before updating the UI.

**When to use:** Any user-initiated persistence action that must feel instant.

**Example:**
```dart
// Pattern consistent with Phase 1 sync_status column on all tables
Future<void> toggleFavorite(String ingredientId) async {
  final current = await _localSource.getIngredient(ingredientId);
  final updated = current.copyWith(
    isFavorite: !current.isFavorite,
    syncStatus: SyncStatus.pending,
    updatedAt: DateTime.now(),
  );
  await _localSource.upsert(updated);
  // Supabase sync is handled by Phase 8 PowerSync; not triggered here
}
```

### Pattern 4: Ephemeral "Selected Today" Set (INGR-05)

**What:** A `Notifier<Set<String>>` managing a set of selected ingredient IDs in memory. Persisted to a lightweight `selected_today_ingredients` table in Drift (one row per ID + date) so Phase 4 can query "what did the user select today?" without passing state between routes.

**When to use:** Any cross-feature ephemeral selection that must survive navigation but not outlive the day.

**Example:**
```dart
@riverpod
class SelectedTodayIngredients extends _$SelectedTodayIngredients {
  @override
  Set<String> build() {
    // Load today's persisted selections on first build
    ref.listen(todayPersistedSelectionsProvider, (_, next) {
      state = next.valueOrNull?.toSet() ?? {};
    });
    return {};
  }

  void toggle(String ingredientId) {
    final updated = Set<String>.from(state);
    if (updated.contains(ingredientId)) {
      updated.remove(ingredientId);
      _repository.removeSelectedToday(ingredientId);
    } else {
      updated.add(ingredientId);
      _repository.addSelectedToday(ingredientId);
    }
    state = updated;
  }
}
```

### Anti-Patterns to Avoid

- **Calling OFf SDK directly from widgets:** Always route through the repository. Bypassing the cache layer breaks offline support and makes testing difficult.
- **Using `searchProducts()` for the autocomplete field:** `searchProducts()` returns full `Product` objects with barcode, images, and nutritional data — expensive and unnecessary for a name-completion field. Use `getSuggestions(TagType.INGREDIENTS)` instead, which returns a plain `List<String>`.
- **Storing "selected today" in route arguments:** Phase 4 needs this list for recipe discovery. It must be global state (Riverpod provider + Drift), not ephemeral navigation state.
- **Using `StateProvider` for search query:** `StateProvider` is in `riverpod/legacy.dart` in Riverpod 3. Use `Notifier` instead.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ingredient name autocomplete | Custom trie/search algorithm | `OpenFoodAPIClient.getSuggestions(TagType.INGREDIENTS)` | OFf taxonomy has ~175k ingredients across 30 languages with synonyms; replicating it locally is infeasible |
| Debounce logic | Custom `Timer` wrapper class or separate package | `Timer` within `AsyncNotifier.search()` + `ref.onDispose()` | Riverpod's lifecycle already handles cancellation; the pattern is 5 lines |
| HTTP retry/timeout | Custom retry interceptor | Dio's built-in `BaseOptions.connectTimeout` + `receiveTimeout` (5s each) | Phase 1 already configures the Dio singleton; add timeout to shared config |
| Category taxonomy | Parsing OFf's full taxonomy dump | Static Dart enum/list of ~10 top-level categories | OFf facet endpoint is rate-limited to 2 req/min; a static list is instantaneous and covers all INGR-02 requirements |
| Dietary flag parsing | String-matching ingredient names | `IngredientsAnalysisParameter` from the openfoodfacts package | OFf already computes `en:vegan`, `en:vegetarian` tags; store them on cache-write |

**Key insight:** The OpenFoodFacts Dart SDK handles encoding, language negotiation, pagination, and error parsing. Raw Dio calls into the OFf REST API require ~300 lines of infrastructure code that has already been written and tested in the official SDK.

---

## Common Pitfalls

### Pitfall 1: Confusing `getSuggestions` (ingredient names) with `searchProducts` (food products)
**What goes wrong:** Developer uses `searchProducts()` to power the autocomplete dropdown. Returns branded food products (e.g., "Heinz Tomato Ketchup") rather than ingredient names (e.g., "tomato"). UI is cluttered and confusing.
**Why it happens:** Both methods accept a text query; the distinction is easy to miss.
**How to avoid:** `getSuggestions(TagType.INGREDIENTS)` returns `List<String>` of canonical ingredient names. Use this for autocomplete. `searchProducts()` is for Phase 4 recipe discovery.
**Warning signs:** Autocomplete results show brand names and barcodes in debug logs.

### Pitfall 2: Violating the 10 req/min search rate limit during development
**What goes wrong:** Fast keyboard typing during testing fires an API call per keystroke. In a real session with multiple testers, the IP gets temporarily banned.
**Why it happens:** Debounce not implemented or set too short.
**How to avoid:** 300ms debounce in the search provider (see Pattern 1). Require minimum 2 characters before firing. Cache results in Drift so repeat queries are free.
**Warning signs:** `429 Too Many Requests` errors in debug console; OFf SDK throws `NetworkException`.

### Pitfall 3: `Ref.mounted` omission crashing after async gap (Riverpod 3)
**What goes wrong:** `state = AsyncData(result)` is called after the provider has been disposed (user navigated away during the network call). In Riverpod 3, this throws instead of silently failing.
**Why it happens:** Riverpod 3 breaking change — post-disposal interactions now throw.
**How to avoid:** Check `ref.mounted` (or use `AsyncValue.guard`) after every `await` in a notifier.
**Warning signs:** `StateError: The provider ... has already been disposed` in test logs.

### Pitfall 4: "Selected today" state lost on navigation
**What goes wrong:** Phase 4 recipe discovery screen receives no ingredients because the selection state only lived in a local `StatefulWidget` rather than a global provider.
**Why it happens:** Developer treats INGR-05 as a local UI concern rather than a cross-feature contract.
**How to avoid:** `SelectedTodayIngredients` must be a root-level Riverpod provider backed by Drift persistence (see Pattern 4).
**Warning signs:** Recipe discovery screen receives an empty ingredient list despite user having made selections.

### Pitfall 5: Dietary filtering returning incorrect results for gluten-free/dairy-free
**What goes wrong:** `IngredientsAnalysisParameter` only supports vegan, vegetarian, and palm-oil-free. Gluten-free and dairy-free are label-based (`labels_tags=en:gluten-free`), not ingredient-analysis-based.
**Why it happens:** Developer assumes all four dietary filters use the same API parameter family.
**How to avoid:** At cache-write time, parse both `ingredientsAnalysisTags` (for vegan/vegetarian) AND `labelsTags` (for gluten-free, dairy-free) from the OFf product response. Store a `dietary_flags` bitmask or JSON array on the Drift `ingredients` row. Filter in Drift, not the API, for the ingredient selection context.
**Warning signs:** Gluten-free filter chip shows no results despite the user searching for "oats."

### Pitfall 6: OFf User-Agent missing — silent blocking
**What goes wrong:** API calls fail intermittently or are blocked without a clear error message.
**Why it happens:** OFf requires a custom User-Agent identifying the app; missing it violates ToS and may result in IP rate-limit enforcement.
**How to avoid:** Set at app startup, before any OFf call:
```dart
OpenFoodAPIConfiguration.userAgent = UserAgent(
  name: 'MealMate',
  version: '1.0.0',
  url: 'https://github.com/your-org/mealmate',
);
```
**Warning signs:** Intermittent 403 or connection-refused errors from OFf endpoints.

---

## Code Examples

Verified patterns from official sources:

### Ingredient Autocomplete (INGR-01)
```dart
// Source: pub.dev/documentation/openfoodfacts — getSuggestions method signature
final List<String> suggestions = await OpenFoodAPIClient.getSuggestions(
  TagType.INGREDIENTS,
  input: 'tom',
  language: OpenFoodFactsLanguage.ENGLISH,
  country: OpenFoodFactsCountry.USA,
  limit: 25,
);
// Returns: ["tomato", "tomato paste", "tomato sauce", "cherry tomatoes", ...]
```

### Dietary Filter via IngredientsAnalysisParameter (INGR-04 — vegan/vegetarian)
```dart
// Source: github.com/openfoodfacts/openfoodfacts-dart/issues/524
// IngredientsAnalysisParameter added in dart SDK to support ingredients_analysis_tags=en:vegan
final config = ProductSearchQueryConfiguration(
  parametersList: [
    IngredientsAnalysisParameter(
      veganStatus: IngredientsAnalysisTags.VEGAN,
    ),
    TagFilter.fromType(
      tagFilterType: TagFilterType.CATEGORIES,
      tagName: 'en:vegetables',
    ),
  ],
  fields: [ProductField.NAME, ProductField.INGREDIENTS_ANALYSIS_TAGS, ProductField.LABELS_TAGS],
  language: OpenFoodFactsLanguage.ENGLISH,
);
final result = await OpenFoodAPIClient.searchProducts(user, config);
```

### Drift Ingredient Table Schema (INGR-01 through INGR-04)
```dart
// Extend Phase 1 skeleton with ingredient-specific columns
class Ingredients extends Table {
  TextColumn get id => text()();                         // UUID v4
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();        // produce, dairy, etc.
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get dietaryFlags => text().nullable()();    // JSON: ["vegan","gluten-free"]
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Riverpod 3 Mounted Check (post-async state update)
```dart
// Source: riverpod.dev/docs/whats_new — Ref.mounted is mandatory in Riverpod 3
Future<void> loadFavorites() async {
  state = const AsyncLoading();
  final result = await _repository.getFavorites();
  if (!ref.mounted) return; // REQUIRED in Riverpod 3
  state = AsyncData(result);
}
```

### OFf SDK Configuration (app startup)
```dart
// Source: pub.dev/packages/openfoodfacts — README configuration section
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
| `AutoDisposeAsyncNotifier`, `FamilyNotifier` | Single `Notifier` class (auto-dispose and family are constructor params) | Riverpod 3.0, Sep 2025 | Remove all `AutoDispose*` type annotations; use unified `Notifier` |
| `StateProvider` for simple state | `Notifier` — `StateProvider` moved to `riverpod/legacy.dart` | Riverpod 3.0, Sep 2025 | Use `@riverpod`-generated notifiers even for simple toggle/filter state |
| `ExampleRef`, `FutureProviderRef` (provider-specific Ref types) | Generic `Ref` parameter | Riverpod 3.0, Sep 2025 | All `@riverpod` functions use `Ref ref` not `IngredientSearchRef ref` |
| `flutter_typeahead` for autocomplete UI | Flutter's native `Autocomplete<T>` widget or plain `TextField` + overlay | Flutter 3.x stable | `flutter_typeahead` 5.2.0 published 2 years ago and unmaintained-feeling; native widget covers the use case |
| Custom debounce class | `Timer` + `ref.onDispose()` inside `AsyncNotifier` | Riverpod 2+ | No extra package dependency; lifecycle-aware cancellation is automatic |

**Deprecated/outdated:**
- `StateNotifierProvider` and `StateProvider`: Moved to `package:riverpod/legacy.dart` in Riverpod 3. Do not use in new code.
- `AutoDisposeNotifier` / `AutoDisposeFamilyNotifier` / `FamilyNotifier`: Removed as separate classes. Use `Notifier` directly.
- `openfoodfacts` SDK versions below 3.x: Breaking API changes; always target the latest 3.x release.

---

## Open Questions

1. **Is the OFf ingredient taxonomy rich enough for the category browsing UX?**
   - What we know: `getSuggestions(TagType.CATEGORIES)` returns OFf food categories, but they are database-oriented (e.g., `en:plant-based-foods-and-beverages`) not user-friendly (e.g., "Produce").
   - What's unclear: Whether the planner should map OFf categories to human-readable labels, or maintain a fully static curated list with no OFf API dependency for browsing.
   - Recommendation: Use a static curated list of ~10 categories with associated OFf `categories_tags` values for API filtering. Eliminates runtime API dependency for browsing and keeps the UX predictable.

2. **Gluten-free and dairy-free label coverage in OFf**
   - What we know: These are stored as `labels_tags` (e.g., `en:gluten-free`) on OFf products, not `ingredients_analysis_tags`. Coverage is incomplete — many products don't have these labels populated.
   - What's unclear: Whether the filtering should be surfaced as a prominent filter chip given incomplete data, or documented as "best-effort."
   - Recommendation: Implement the filter but display a "Results may be incomplete" footnote when active. This matches how major recipe apps handle dietary metadata from crowd-sourced databases.

3. **Drift schema alignment with Phase 1**
   - What we know: Phase 1 defines the `ingredients` table skeleton with `sync_status` and `updated_at`. Phase 3 needs to add `is_favorite`, `category`, `dietary_flags`, and `cached_at`.
   - What's unclear: Whether Phase 1 planning has locked column names that might conflict.
   - Recommendation: Phase 3 plan should include a migration (Drift `Migrator`) to add columns to the Phase 1 schema rather than recreating it. Verify column names in Phase 1 PLAN.md before writing migration code.

---

## Sources

### Primary (HIGH confidence)
- `pub.dev/packages/openfoodfacts` (v3.30.2) — version, feature list, `getSuggestions` signature
- `pub.dev/documentation/openfoodfacts/latest/openfoodfacts/OpenFoodAPIClient/getSuggestions.html` — exact method signature and parameter names
- `riverpod.dev/docs/whats_new` — Riverpod 3.0 breaking changes: `Ref.mounted`, unified `Notifier`, legacy providers
- `docs.flutter.dev/app-architecture/design-patterns/offline-first` — repository pattern, stream-based cache, write-local-first

### Secondary (MEDIUM confidence)
- `github.com/openfoodfacts/openfoodfacts-dart/issues/524` — confirms `IngredientsAnalysisParameter` class for vegan/vegetarian filtering; PR merged
- `support.openfoodfacts.org/help/en-gb/12-api-data-reuse/94-are-there-conditions-to-use-the-api` — User-Agent requirement and ODbL attribution obligation
- `github.com/openfoodfacts/openfoodfacts-server/issues/8818` — rate limits: 10 req/min search, 2 req/min facet queries

### Tertiary (LOW confidence)
- Multiple WebSearch results for Riverpod 3 + debounce patterns — no single authoritative code example found; Pattern 1 above synthesizes from multiple sources and Riverpod 3 lifecycle docs

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — OFf SDK version verified on pub.dev; Riverpod 3 release verified on riverpod.dev; Drift and Dio are project-confirmed decisions
- Architecture: MEDIUM — repository pattern from official Flutter docs; debounce pattern synthesized from Riverpod 3 docs + community; no single authoritative example for the full combined pattern
- Pitfalls: MEDIUM-HIGH — rate limits from official OFf GitHub issue; Riverpod 3 mounted requirement from official release notes; dietary filter behavior from SDK GitHub PR

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (OFf SDK and Riverpod release at moderate velocity; re-verify minor version bumps before implementation)
