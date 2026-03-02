# Architecture Research

**Domain:** Offline-first mobile meal planning app (Flutter + Supabase)
**Researched:** 2026-03-02
**Confidence:** HIGH (official Flutter docs + verified community sources)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI LAYER (Flutter)                        │
├────────────────┬────────────────┬────────────────┬──────────────┤
│  IngredientUI  │  RecipeUI      │  MealPlannerUI │  ShoppingUI  │
│  (screens,     │  (screens,     │  (screens,     │  (screens,   │
│   widgets)     │   widgets)     │   widgets)     │   widgets)   │
└───────┬────────┴────────┬───────┴────────┬───────┴──────┬───────┘
        │ observes        │ observes       │ observes     │ observes
┌───────▼────────┬────────▼───────┬────────▼───────┬──────▼───────┐
│                        STATE LAYER (Riverpod)                    │
│  IngredientNotifier  RecipeNotifier  MealPlanNotifier  ShopNotif │
│  (AsyncNotifier)     (AsyncNotifier) (AsyncNotifier)  (Notifier) │
└───────┬────────┴────────┬───────┴────────┬───────┴──────┬───────┘
        │                 │                │              │
        └────────────┬────┘                └──────────────┘
                     │ reads/writes to
┌────────────────────▼────────────────────────────────────────────┐
│                     REPOSITORY LAYER                             │
│  IngredientRepo   RecipeRepo   MealPlanRepo   ShoppingListRepo   │
│  (single source of truth — reads local, syncs remote)           │
└──────────┬────────────────┬────────────────────────────────────-┘
           │                │
     ┌─────▼──────┐  ┌──────▼────────────────────────────────────┐
     │LOCAL STORE │  │            REMOTE SERVICES                 │
     │            │  ├───────────────┬────────────────┬───────────┤
     │ drift/SQLite│  │ SupabaseClient│ RecipeAPIClient│ LLMClient │
     │ (primary   │  │ (auth, sync,  │ (Spoonacular/  │ (OpenAI/  │
     │  source of │  │  realtime)    │  Edamam)       │  Gemini)  │
     │  truth)    │  └───────────────┴────────────────┴───────────┘
     └─────┬──────┘
           │ synced by
     ┌─────▼──────────────────────────────────────────────────────┐
     │                     SYNC ENGINE                             │
     │  PowerSync (or manual queue) — watches connectivity,        │
     │  queues local writes, uploads to Supabase, resolves LWW     │
     └────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Communicates With |
|-----------|----------------|-------------------|
| UI Screens | Render state, capture user intent | ViewModels/Notifiers only |
| Riverpod Notifiers | Transform repository data into UI state, handle commands | Repositories |
| IngredientRepository | CRUD for ingredient catalog + favorites | Local SQLite, Supabase |
| RecipeRepository | Recipe search, AI generation, caching | Local SQLite, Recipe APIs, LLM Service |
| MealPlanRepository | Weekly plan CRUD, 7-day slot management | Local SQLite, Supabase |
| ShoppingListRepository | Aggregate ingredients, deduplicate, normalize units | MealPlanRepo, IngredientRepo, Local SQLite |
| Local SQLite (Drift) | Offline-first persistent store, primary source of truth | All repositories |
| Supabase Client | Auth, remote PostgreSQL sync, RLS enforcement | Repositories (via sync) |
| RecipeAPIClient | External recipe search (Spoonacular/Edamam) | RecipeRepository |
| LLMClient | AI recipe generation from selected ingredients | RecipeRepository |
| Sync Engine | Background sync, upload queue, conflict resolution | Local SQLite, Supabase |
| go_router | Declarative navigation, deep linking, auth guards | UI Screens |

## Recommended Project Structure

```
lib/
├── app/
│   ├── app.dart                    # MaterialApp + ProviderScope root
│   ├── router.dart                 # go_router configuration, guards
│   └── theme.dart                  # App-wide theming
│
├── core/
│   ├── database/
│   │   ├── app_database.dart       # Drift database definition
│   │   └── tables/                 # Drift table definitions
│   ├── sync/
│   │   ├── sync_engine.dart        # PowerSync or manual sync manager
│   │   └── connectivity_service.dart
│   ├── supabase/
│   │   └── supabase_client.dart    # Supabase init + client singleton
│   └── error/
│       └── app_exception.dart      # Domain error types
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── auth_service.dart   # Wraps Supabase auth
│   │   ├── domain/
│   │   │   └── user.dart
│   │   └── presentation/
│   │       ├── auth_notifier.dart
│   │       └── screens/
│   │
│   ├── ingredients/
│   │   ├── data/
│   │   │   ├── ingredient_repository.dart
│   │   │   └── ingredient_api_service.dart   # External ingredient API
│   │   ├── domain/
│   │   │   └── ingredient.dart
│   │   └── presentation/
│   │       ├── ingredients_notifier.dart
│   │       └── screens/
│   │
│   ├── recipes/
│   │   ├── data/
│   │   │   ├── recipe_repository.dart
│   │   │   ├── recipe_api_service.dart       # Spoonacular/Edamam
│   │   │   └── llm_recipe_service.dart       # AI generation
│   │   ├── domain/
│   │   │   └── recipe.dart
│   │   └── presentation/
│   │       ├── recipes_notifier.dart
│   │       └── screens/
│   │
│   ├── meal_plan/
│   │   ├── data/
│   │   │   └── meal_plan_repository.dart
│   │   ├── domain/
│   │   │   ├── meal_plan.dart
│   │   │   └── meal_slot.dart
│   │   └── presentation/
│   │       ├── meal_plan_notifier.dart
│   │       └── screens/
│   │
│   └── shopping_list/
│       ├── data/
│       │   ├── shopping_list_repository.dart
│       │   └── unit_normalizer.dart          # g/kg/ml/L normalization
│       ├── domain/
│       │   └── shopping_item.dart
│       └── presentation/
│           ├── shopping_list_notifier.dart
│           └── screens/
│
└── shared/
    ├── widgets/                    # Reusable UI components
    ├── extensions/                 # Dart extension methods
    └── utils/                      # Formatters, validators
```

### Structure Rationale

- **feature-first within lib/features/:** Each feature (auth, ingredients, recipes, meal_plan, shopping_list) is independently navigable and testable. Matches how teams work in parallel.
- **core/:** Cross-cutting infrastructure (database, sync, supabase client) that features consume but don't own.
- **data/domain/presentation/ within each feature:** Classic clean architecture layers scoped to the feature boundary rather than globally. Keeps related code co-located.
- **shared/:** Only for truly cross-feature reusable components — resist moving things here prematurely.

## Architectural Patterns

### Pattern 1: Offline-First with Local SQLite as Primary Source of Truth

**What:** All reads and writes go to the local SQLite database (via Drift). The sync engine pushes local writes to Supabase in the background. The UI never talks to remote services directly.

**When to use:** Always, for all persistent data (meal plans, shopping lists, ingredients, cached recipes).

**Trade-offs:**
- Pro: App works identically online and offline. Zero latency for reads/writes.
- Pro: Sync is decoupled from UI — no loading spinners for basic operations.
- Con: Conflict resolution requires a defined strategy (use LWW with `updated_at` timestamps).
- Con: More complex initial setup than a simple REST-and-display approach.

**Example:**
```dart
// Repository writes locally first — sync happens in background
class MealPlanRepository {
  final AppDatabase _db;
  final SyncEngine _sync;

  Future<void> assignRecipeToSlot(String recipeId, MealSlot slot) async {
    // Write to local SQLite immediately
    await _db.mealPlanDao.upsert(MealPlanEntry(
      recipeId: recipeId,
      slot: slot,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    ));
    // Sync engine picks this up and sends to Supabase in background
    _sync.scheduleUpload();
  }

  Stream<List<MealPlanEntry>> watchWeeklyPlan(DateTime weekStart) {
    // Always returns a Stream from local DB — instant, always available
    return _db.mealPlanDao.watchWeek(weekStart);
  }
}
```

### Pattern 2: Repository as Single Source of Truth Boundary

**What:** Repositories own the decision of where data comes from (local cache, remote API, LLM). Notifiers never talk to services or databases directly — only repositories.

**When to use:** All data access. This is the mandatory boundary.

**Trade-offs:**
- Pro: Testable — mock the repository to test any notifier.
- Pro: Swap implementation (e.g., change recipe API) without touching UI.
- Con: Adds an abstraction layer. Worth it at this scale.

**Example:**
```dart
// Notifier only knows about repository interface
@riverpod
class RecipesNotifier extends _$RecipesNotifier {
  @override
  Future<List<Recipe>> build() async {
    return ref.watch(recipeRepositoryProvider).getRecommendations(
      ingredients: ref.watch(selectedIngredientsProvider),
    );
  }

  Future<void> generateWithAI(List<Ingredient> ingredients) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(recipeRepositoryProvider).generateAIRecipe(ingredients),
    );
  }
}
```

### Pattern 3: Sync Status Tracking on Every Persisted Row

**What:** Every table that syncs to Supabase carries a `sync_status` column (`pending | synced | failed`) and an `updated_at` timestamp. The sync engine uses these to drive uploads and conflict resolution.

**When to use:** All tables with remote sync (meal_plans, shopping_list_items, user_ingredients).

**Trade-offs:**
- Pro: Transparent sync state — UI can show "syncing..." badges when offline.
- Pro: Conflict resolution via LWW: compare `updated_at` on both sides, keep latest.
- Con: Schema overhead — every synced table needs these extra columns.

**Example:**
```dart
// Drift table definition with sync metadata
class MealPlanEntries extends Table {
  TextColumn get id => text().clientDefault(() => uuid.v4())();
  TextColumn get userId => text()();
  TextColumn get recipeId => text()();
  TextColumn get dayOfWeek => text()();
  TextColumn get mealType => text()(); // breakfast/lunch/dinner
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
}
```

### Pattern 4: Recipe API + LLM Behind a Single Repository Interface

**What:** `RecipeRepository.getRecommendations()` decides whether to hit the external API or the LLM based on context (user wants AI generation vs. browsing). Results from both are cached in SQLite with a `source` column.

**When to use:** Recipe retrieval in all cases.

**Trade-offs:**
- Pro: UI doesn't need to know about two recipe sources.
- Pro: AI-generated recipes become indistinguishable from API recipes once cached.
- Con: Repository becomes more complex — use a `RecipeSource` enum to keep branching explicit.

## Data Flow

### Request Flow: User Adds Recipe to Meal Planner

```
User taps "Add to Tuesday Lunch"
    ↓
MealPlannerScreen (captures tap) → MealPlanNotifier.assignRecipe(recipe, slot)
    ↓
MealPlanRepository.assignRecipeToSlot(recipeId, slot)
    ↓
Drift AppDatabase (write locally, sync_status = pending)
    ↓
MealPlanRepository Stream emits updated state
    ↑
MealPlanNotifier (AsyncValue<List<MealPlanEntry>> rebuilt)
    ↑
MealPlannerScreen (UI updates instantly — no waiting for network)

[Background]:
SyncEngine polls pending rows → uploads to Supabase via POST
Supabase confirms → local sync_status updated to "synced"
```

### Request Flow: AI Recipe Generation

```
User selects ingredients + taps "Generate Recipe"
    ↓
RecipesScreen → RecipesNotifier.generateWithAI(selectedIngredients)
    ↓
RecipeRepository.generateAIRecipe(ingredients)
    ↓
LLMClient.generate(prompt with ingredients)   [network call — show loading]
    ↓
RecipeRepository caches response in local SQLite (source = "ai_generated")
    ↓
Returns Recipe domain object
    ↑
RecipesNotifier state updated → RecipesScreen shows new recipe
```

### Request Flow: App Launch Offline

```
App launches with no connectivity
    ↓
SyncEngine detects offline → sets sync to paused
    ↓
All repositories read from local SQLite only
    ↓
UI renders from cached data — full functionality
    ↓
Connectivity restored → SyncEngine resumes
    ↓
Uploads pending local changes → downloads remote changes
    ↓
LWW conflict resolution: keep row with latest updated_at
    ↓
Drift streams emit updates → UI auto-refreshes
```

### State Management Flow

```
Supabase Auth State Change
    ↓
AuthNotifier (Riverpod) updates auth state
    ↓
go_router redirect triggers (AuthGuard) → routes to login or home
    ↓
User-scoped providers invalidated → Riverpod ref.invalidate()
    ↓
Repositories fetch fresh user-scoped data from local SQLite
```

### Key Data Flows Summary

1. **Read path:** UI → Notifier → Repository → SQLite (always local, always fast)
2. **Write path:** UI → Notifier → Repository → SQLite (local) → SyncEngine → Supabase (background)
3. **Recipe discovery path:** Notifier → Repository → RecipeAPI OR LLM → SQLite cache → Notifier stream
4. **Shopping list generation:** MealPlanRepository → ShoppingListRepository → unit normalization → deduplication → SQLite
5. **Auth state changes:** Supabase auth stream → AuthNotifier → go_router guards → provider invalidation

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Supabase Auth | `supabase_flutter` SDK, session stored locally | Use `onAuthStateChange` stream to drive AuthNotifier |
| Supabase PostgreSQL | `supabase_flutter` for sync writes; never for reads | All reads go through local SQLite; use Supabase only as sync target |
| Supabase Realtime | Optional: subscribe to remote changes pushed by other devices | Needed for multi-device sync to feel instant; without it, sync only on app foreground |
| Recipe API (Spoonacular/Edamam) | REST client wrapped in `RecipeAPIService` | Cache all responses in SQLite; never re-fetch what's cached |
| LLM (OpenAI/Gemini) | REST client in `LLMRecipeService` | Always requires connectivity; show explicit loading state |
| PowerSync | SDK wraps Drift database; handles WAL → SQLite sync | Recommended for Supabase offline-first; eliminates manual sync queue |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| UI Screen ↔ Notifier | Riverpod `ref.watch` / `ref.read` | Notifiers exposed as `@riverpod` generated providers |
| Notifier ↔ Repository | Direct method calls via Riverpod provider injection | Repositories also exposed as Riverpod providers |
| Repository ↔ Drift DB | Drift DAO methods (type-safe, compile-checked) | One DAO per feature table group |
| Repository ↔ External API | Service class wrapping http/Dio | Network errors mapped to domain exceptions at this boundary |
| SyncEngine ↔ Drift | Queries `sync_status = pending` rows | Sync engine lives in core/, accessed by all repositories |
| SyncEngine ↔ Supabase | Supabase client upsert with `updated_at` | Server-side `updated_at` used for LWW resolution |

## Suggested Build Order

Build order flows from infrastructure dependencies upward. Each layer must exist before the layer above it can be implemented.

```
Phase 1: Infrastructure Foundation
├── Drift database schema (all tables with sync_status columns)
├── Supabase project setup (tables, RLS policies, auth)
├── Auth feature (login/register screens + AuthNotifier)
└── go_router with auth guard

Phase 2: Core Data Features (no sync yet)
├── Ingredient catalog (local CRUD + Supabase ingredient API)
├── Recipe browsing (external API + SQLite cache)
└── Basic recipe display

Phase 3: Core Planning Features
├── Weekly meal planner (7x3 grid + assign recipes to slots)
└── Shopping list generation (aggregate + unit normalization)

Phase 4: AI + Advanced Recipe
├── LLM recipe generation from selected ingredients
└── AI recipe caching into existing Recipe model

Phase 5: Offline Sync
├── SyncEngine implementation (connectivity detection + upload queue)
├── PowerSync integration OR manual sync queue
├── LWW conflict resolution
└── Sync status UI indicators

Phase 6: Polish
├── Offline indicators, sync status badges
├── Error handling and retry UI
└── Performance: pagination, lazy loading, image caching
```

**Rationale for this order:**
- Auth before everything else — Supabase RLS requires authenticated requests; all user data is scoped by user ID.
- Local DB schema first — Drift tables define the domain model that all features build on. Changing schema later is painful.
- Sync added after features work locally — testing sync against features that don't work yet creates two failure modes at once. Build features offline-first, then layer sync on top.
- LLM after basic recipe browsing — AI generation is an enhancement; the recipe display and caching infrastructure must exist first.
- Shopping list depends on meal plan — aggregation logic requires meal plan to have recipes with ingredients attached.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users | Current architecture is fine. Supabase free tier handles this. Single Supabase project, no CDN. |
| 1k-100k users | Recipe API cache aggressively (popular recipes will be re-requested). Add CDN for recipe images. Consider Supabase Pro with connection pooling via PgBouncer. |
| 100k+ users | Move LLM calls to a server-side function (Supabase Edge Functions) to protect API keys and add rate limiting. Recipe catalog becomes a shared read-only table (not per-user). Consider separating ingredient data API from user data. |

### Scaling Priorities

1. **First bottleneck:** External API rate limits. Spoonacular has strict per-day limits on free tier. Mitigation: aggressive local SQLite caching — cache every recipe fetched, never re-request what's already local.
2. **Second bottleneck:** LLM costs at scale. Each AI generation call has a direct cost. Mitigation: cache generated recipes by ingredient combination hash; if same ingredients requested, return cached recipe.

## Anti-Patterns

### Anti-Pattern 1: Direct Supabase Calls from UI or Notifiers

**What people do:** Call `supabase.from('recipes').select()` directly in a Riverpod notifier or widget.

**Why it's wrong:** Couples UI code to specific backend implementation. Makes offline support impossible — any connectivity loss causes UI errors. Cannot test notifiers without real Supabase connection.

**Do this instead:** All Supabase access goes through repository classes. Notifiers only call repository methods. Repositories handle the local-vs-remote decision transparently.

### Anti-Pattern 2: Treating Remote Database as Primary Source of Truth

**What people do:** Fetch from Supabase on every screen load, show loading spinner, display remote data.

**Why it's wrong:** App is unusable offline (the stated requirement). Every interaction has network latency. No data available in poor connectivity (grocery stores, underground).

**Do this instead:** Write to local SQLite first, return immediately. Let the sync engine push to Supabase in the background. The UI binds to Drift streams which always have data.

### Anti-Pattern 3: Generating Shopping List On-the-Fly in the UI

**What people do:** Compute the shopping list by mapping over the current meal plan state in a widget or notifier, doing unit math inline.

**Why it's wrong:** Unit normalization (converting cups, tbsp, ml, g, kg to common units for deduplication) is complex, error-prone logic that belongs in the data layer. Computing it in the UI makes it untestable and creates UI jank on large plans.

**Do this instead:** `ShoppingListRepository` owns the aggregation and normalization logic. It reads from the meal plan and ingredient tables, computes the normalized list, and persists the result to its own SQLite table. The notifier just reads the pre-computed list.

### Anti-Pattern 4: One Monolithic Riverpod Provider for All App State

**What people do:** Create a single `AppStateNotifier` that holds ingredient selections, current recipes, meal plan, and shopping list all in one class.

**Why it's wrong:** Any state change in any feature rebuilds all subscribers. Impossible to test features in isolation. The class grows to hundreds of lines.

**Do this instead:** One notifier per feature (IngredientNotifier, RecipeNotifier, MealPlanNotifier, ShoppingListNotifier). Cross-feature dependencies are handled by watching other providers in Riverpod — `ref.watch(selectedIngredientsProvider)` inside RecipesNotifier is the correct pattern.

### Anti-Pattern 5: Skipping sync_status Column in Schema

**What people do:** Build all features without sync metadata, then try to retrofit sync later.

**Why it's wrong:** You can't retrofit an upload queue onto existing data without knowing which rows have been synced. You'll either re-upload everything (duplicates) or skip changed rows (data loss).

**Do this instead:** Add `updated_at` and `sync_status` columns to every table from day one, even before sync is implemented. The columns are cheap; retrofitting is expensive.

## Sources

- [Official Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture/guide) — HIGH confidence
- [Flutter Riverpod Architecture Introduction — Andrea Bizzotto](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/) — HIGH confidence (widely cited, verified against official docs)
- [Supabase Offline-First Flutter Apps with Brick](https://supabase.com/blog/offline-first-flutter-apps) — HIGH confidence (official Supabase blog)
- [PowerSync: Bringing Offline-First to Supabase](https://www.powersync.com/blog/bringing-offline-first-to-supabase) — MEDIUM confidence (vendor documentation)
- [Building Local-First Flutter Apps with Riverpod, Drift, and PowerSync](https://dinkomarinac.dev/blog/building-local-first-flutter-apps-with-riverpod-drift-and-powersync/) — MEDIUM confidence (community, verified against PowerSync docs)
- [Flutter Clean Architecture with Riverpod and Supabase](https://otakoyi.software/blog/flutter-clean-architecture-with-riverpod-and-supabase) — MEDIUM confidence (community post)
- [Flutter Project Structure: Feature-first or Layer-first? — Andrea Bizzotto](https://codewithandrea.com/articles/flutter-project-structure/) — MEDIUM confidence
- [Implementing Data Sync & Conflict Resolution Offline in Flutter](https://vibe-studio.ai/insights/implementing-data-sync-conflict-resolution-offline-in-flutter) — LOW confidence (unverified community source, cross-referenced with official Drift docs)

---
*Architecture research for: Offline-first Flutter + Supabase meal planning app*
*Researched: 2026-03-02*
