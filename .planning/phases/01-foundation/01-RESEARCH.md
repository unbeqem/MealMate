# Phase 1: Foundation - Research

**Researched:** 2026-03-02
**Domain:** Flutter project setup, Drift local SQLite schema, Supabase RLS, go_router auth guards, Supabase Edge Functions
**Confidence:** HIGH (core setup patterns), MEDIUM (PowerSync/Drift integration version compatibility)

---

## Summary

Phase 1 establishes every piece of infrastructure that later features depend on: a running Flutter project with the full dependency graph, a typed local SQLite schema (Drift) with UUID PKs and sync metadata columns, Supabase with RLS enforced on all user tables, go_router with auth-aware redirect, and an Edge Functions scaffold that proxies external API keys. Nothing in Phase 1 is user-visible — it exists solely to give phases 2–9 a correct foundation.

The most critical decisions in this phase — UUID primary keys, RLS, offline-first repository abstraction, and API key proxying — are all "first or never" choices. Retrofitting any of them after feature code is written is a high-cost operation. The research confirms the chosen stack (Flutter 3.41, Drift 2.32, Riverpod 3.x, go_router 17, Supabase) is current and well-supported as of March 2026.

The one open risk is the PowerSync/Drift integration bridge (`drift_sqlite_async 0.2.6`), which is in beta and uses Drift >=2.28.0 <3.0.0. Drift 2.32 falls within this range, so the versions are compatible — but the beta status means the Phase 1 scaffold should include a connectivity smoke test verifying that PowerSync streams propagate through Drift's query system before any feature work begins.

**Primary recommendation:** Set up Drift schema with UUID PKs and `sync_status`/`updated_at` columns on every table before writing a single line of feature code. This schema is the contract everything else builds on.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter | 3.41.x (stable) | Cross-platform UI | Project decision; current stable as of Feb 2026 |
| dart | 3.10.x | Language | Ships with Flutter 3.41 |
| drift | ^2.32.0 | Local SQLite ORM | Type-safe SQL, reactive streams, migrations, UUID PKs |
| drift_flutter | ^0.3.0 | Flutter-specific Drift setup | Wraps `drift_native` for correct path handling on iOS/Android |
| supabase_flutter | ^2.12.0 | Auth + remote sync + realtime | Official Supabase Flutter client |
| flutter_riverpod | ^3.2.1 | State management | Project decision; Riverpod 3.x is current community standard |
| riverpod_annotation | ^4.0.2 | Code generation annotations | Required with riverpod_generator |
| go_router | ^17.1.0 | Declarative navigation + auth guard | flutter.dev maintained; supports redirect-based auth guards |
| flutter_secure_storage | ^10.0.0 | Encrypted token storage | Stores Supabase JWT securely (RSA OAEP + AES-GCM) |
| uuid | ^4.x | UUID v4 generation | Used in `clientDefault()` for Drift UUID PKs |

### Dev Dependencies

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| drift_dev | ^2.32.0 | Drift code generator | Must match drift major version exactly |
| build_runner | ^2.4.x | Code generation runner | Runs drift_dev + riverpod_generator + freezed |
| riverpod_generator | ^4.0.3 | Riverpod provider code gen | Eliminates provider boilerplate |

### Supporting (Phase 1 specific)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| powersync | ^1.17.0 | Offline-first sync engine | PowerSync wraps the Drift DB; scaffold the connection here |
| drift_sqlite_async | ^0.2.6 | Bridge: PowerSync → Drift | Connects `SqliteAsyncDriftConnection` to `AppDatabase` |
| connectivity_plus | ^7.0.0 | Network state detection | Used by sync engine; initialize in foundation |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Drift | sqflite | sqflite requires raw SQL; no type safety; no reactive streams |
| Drift | Isar | Isar abandoned by maintainer in 2024; do not use |
| PowerSync | Manual sync queue | Weeks of edge-case work; queue durability, conflict resolution, app lifecycle |
| go_router redirect | Navigator 2.0 manual guards | Far more boilerplate; go_router redirect is the standard pattern |
| flutter_secure_storage v10 | SharedPreferences | SharedPreferences is plain-text; never use for auth tokens |

**Installation (pubspec.yaml additions):**

```yaml
dependencies:
  flutter_riverpod: ^3.2.1
  riverpod_annotation: ^4.0.2
  drift: ^2.32.0
  drift_flutter: ^0.3.0
  powersync: ^1.17.0
  drift_sqlite_async: ^0.2.6
  supabase_flutter: ^2.12.0
  go_router: ^17.1.0
  flutter_secure_storage: ^10.0.0
  connectivity_plus: ^7.0.0
  uuid: ^4.0.0

dev_dependencies:
  drift_dev: ^2.32.0
  build_runner: ^2.4.0
  riverpod_generator: ^4.0.3
```

---

## Architecture Patterns

### Recommended Project Structure (Phase 1 creates)

```
lib/
├── app/
│   ├── app.dart                    # MaterialApp.router + ProviderScope root
│   ├── router.dart                 # go_router config, routes, redirect guard
│   └── theme.dart                  # App-wide Material 3 theme
│
├── core/
│   ├── database/
│   │   ├── app_database.dart       # Drift @DriftDatabase class
│   │   ├── app_database.g.dart     # Generated (build_runner)
│   │   └── tables/
│   │       ├── ingredients_table.dart
│   │       ├── recipes_table.dart
│   │       ├── meal_plan_slots_table.dart
│   │       └── shopping_list_items_table.dart
│   ├── sync/
│   │   ├── sync_engine.dart        # PowerSync init + connectivity bridge
│   │   └── connectivity_service.dart
│   └── supabase/
│       └── supabase_client.dart    # Supabase.initialize() + client accessor
│
└── features/
    └── auth/
        ├── data/
        │   └── auth_repository.dart    # Wraps Supabase auth
        ├── domain/
        │   └── user.dart               # Domain User model
        └── presentation/
            ├── auth_notifier.dart      # Riverpod AsyncNotifier for auth state
            └── screens/
                └── login_screen.dart   # Placeholder login screen
```

### Pattern 1: Drift Table with UUID PK + Sync Metadata

**What:** Every domain table uses `text().clientDefault(() => const Uuid().v4()).primary()` as its PK, plus `updated_at` and `sync_status` columns for offline sync.

**Why this order:** UUID PKs and sync columns must be in the schema from the very first `schemaVersion = 1`. Adding them later requires a migration that touches every FK reference.

**Example (verified from drift.simonbinder.eu docs):**

```dart
// Source: drift.simonbinder.eu/dart_api/tables/ + drift.simonbinder.eu/docs/getting-started/
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Ingredients extends Table {
  // UUID v4 PK — generated client-side so offline inserts never collide
  TextColumn get id => text().clientDefault(() => _uuid.v4())();

  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();

  // Sync metadata — required on every table that syncs to Supabase
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Recipes extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get source => text().withDefault(const Constant('api'))(); // 'api' | 'ai_generated'
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class MealPlanSlots extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get userId => text()();
  TextColumn get recipeId => text().nullable().references(Recipes, #id)();
  TextColumn get dayOfWeek => text()(); // 'monday'...'sunday'
  TextColumn get mealType => text()(); // 'breakfast' | 'lunch' | 'dinner'
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class ShoppingListItems extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Ingredients, Recipes, MealPlanSlots, ShoppingListItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mealmate');
  }
}
```

**Code generation:** `dart run build_runner build --delete-conflicting-outputs`

### Pattern 2: PowerSync → Drift Bridge

**What:** PowerSync uses its own SQLite layer (`sqlite_async`). The `drift_sqlite_async` bridge connects it to Drift's typed query layer.

**Example (verified from docs.powersync.com/client-sdk-references/flutter/flutter-orm-support):**

```dart
// Source: docs.powersync.com/client-sdk-references/flutter/flutter-orm-support
import 'package:powersync/powersync.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';

// In sync_engine.dart
final powerSyncDatabase = PowerSyncDatabase(
  schema: schema,
  path: await getDatabasePath(),
);

// Bridge: connect PowerSync's SQLite to Drift
final driftConnection = SqliteAsyncDriftConnection(powerSyncDatabase);
final appDb = AppDatabase(driftConnection);
```

**Critical note:** `drift_sqlite_async 0.2.6` is beta. For local-only tables, use `transformTableUpdates` to ensure Drift receives streaming notifications by internal table name. Verify streaming works before writing feature code.

### Pattern 3: go_router Auth Guard with Riverpod

**What:** GoRouter's `redirect` callback watches auth state from a Riverpod `StreamProvider`. The `refreshListenable` parameter tells the router to re-evaluate redirect whenever auth changes.

**Example (verified from dinkomarinac.dev + apparencekit.dev):**

```dart
// Source: dinkomarinac.dev/guarding-routes-in-flutter-with-gorouter-and-riverpod
// auth_notifier.dart
@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((event) => event.session?.user);
}

// router.dart
final routerProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ref.read(authStateProvider.notifier);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authStateNotifier,  // re-run redirect on auth change
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);

      // Don't redirect while auth state is still loading
      if (authAsync.isLoading || authAsync.hasError) return null;

      final isAuthenticated = authAsync.valueOrNull != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isGoingToLogin) return '/login';
      if (isAuthenticated && isGoingToLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    ],
  );
});
```

**Integration in app.dart:**
```dart
Consumer(
  builder: (_, ref, __) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(routerConfig: router);
  },
)
```

### Pattern 4: Supabase RLS Policies

**What:** Every user-data table gets RLS enabled immediately at creation time, with `USING` + `WITH CHECK` policies using `(SELECT auth.uid())` (the `SELECT` wrapper caches the call for ~95% performance improvement per official docs).

**Example (verified from supabase.com/docs/guides/database/postgres/row-level-security):**

```sql
-- Source: supabase.com/docs/guides/database/postgres/row-level-security

-- Step 1: Enable RLS (do this for EVERY table)
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plan_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_list_items ENABLE ROW LEVEL SECURITY;

-- Step 2: Create policies for each operation
-- SELECT: users can only see their own rows
CREATE POLICY "users_select_own_ingredients"
ON ingredients FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- INSERT: validate user_id on insert (WITH CHECK prevents injecting other user's ID)
CREATE POLICY "users_insert_own_ingredients"
ON ingredients FOR INSERT
TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

-- UPDATE: both USING (which rows) + WITH CHECK (what values) are required
CREATE POLICY "users_update_own_ingredients"
ON ingredients FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

-- DELETE
CREATE POLICY "users_delete_own_ingredients"
ON ingredients FOR DELETE
TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- Performance: index user_id on every table (policies do full table scan without it)
CREATE INDEX idx_ingredients_user_id ON ingredients(user_id);
CREATE INDEX idx_recipes_user_id ON recipes(user_id);
CREATE INDEX idx_meal_plan_slots_user_id ON meal_plan_slots(user_id);
CREATE INDEX idx_shopping_list_items_user_id ON shopping_list_items(user_id);
```

**Verification protocol:** Never test RLS in the Supabase SQL editor (it runs as `postgres` superuser, bypassing RLS). Use the Supabase client SDK with two real JWTs from two separate test user accounts. If User A's JWT can read User B's rows via the API, RLS is misconfigured.

### Pattern 5: Edge Function API Key Proxy

**What:** Spoonacular and OpenAI keys live in Supabase project secrets (`supabase secrets set`). The Flutter app calls a Supabase Edge Function via the Supabase SDK; the function reads the key from `Deno.env.get()` and proxies the request. The Flutter bundle never contains third-party API keys.

**Example (verified from supabase.com/docs/guides/functions/secrets):**

```typescript
// supabase/functions/recipe-proxy/index.ts
// Source: supabase.com/docs/guides/functions/secrets
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req: Request) => {
  const spoonacularKey = Deno.env.get('SPOONACULAR_API_KEY')!

  const { query } = await req.json()
  const url = `https://api.spoonacular.com/recipes/complexSearch?query=${query}&apiKey=${spoonacularKey}`

  const response = await fetch(url)
  const data = await response.json()

  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

**Set secrets:**
```bash
supabase secrets set SPOONACULAR_API_KEY=your_key_here
supabase secrets set OPENAI_API_KEY=your_key_here
# Keys available immediately — no redeploy needed
```

**Invoke from Flutter:**
```dart
// Source: supabase.com/docs/reference/dart/functions-invoke
final response = await Supabase.instance.client.functions.invoke(
  'recipe-proxy',
  body: {'query': 'pasta'},
);
```

### Pattern 6: Drift Schema Migrations

**What:** Every schema change requires incrementing `schemaVersion`. Use `drift_dev make-migrations` to generate schema snapshots and test files. Never use `DROP TABLE/CREATE TABLE` as a migration strategy.

**Example (verified from drift.simonbinder.eu/migrations/):**

```dart
// Source: drift.simonbinder.eu/migrations/
@override
int get schemaVersion => 2;  // increment for every schema change

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Example: adding a column in v2
        await m.addColumn(recipes, recipes.thumbnailUrl);
      }
    },
  );
}
```

**Generate migration snapshots:**
```bash
dart run drift_dev make-migrations
```
This command generates schema JSON files and test files that validate migrations don't cause data loss.

### Anti-Patterns to Avoid

- **Integer auto-increment PKs on any table:** Two offline clients both generate `id=1`. On sync they collide. UUID PKs are the only valid choice for offline-first tables.
- **RLS enabled but no policies written:** RLS with no policies is "deny all" — the app will fail silently. Always write policies immediately after enabling RLS.
- **Testing RLS in the Supabase SQL editor:** The SQL editor runs as `postgres` superuser, which bypasses RLS. All RLS validation must use the Flutter SDK with a real JWT.
- **Supabase `service_role` key in the Flutter bundle:** This key bypasses all RLS. It must never appear in app code — only in Edge Functions via `Deno.env.get()`.
- **`SharedPreferences` for auth tokens:** Plain-text on disk. Always use `flutter_secure_storage` for any auth credential.
- **Schema changes via app reinstall:** Once any migration-tracked schema is on a device, the only path forward is `onUpgrade`. Develop with Drift migrations from version 1.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| UUID generation | Custom random string | `uuid ^4.x` with `Uuid().v4()` | UUID v4 has 2^122 bits of randomness; collision probability is negligible at any practical scale |
| Local SQLite schema migrations | Manual SQL ALTER TABLE | `drift_dev make-migrations` | Drift validates migrations against schema snapshots; prevents silent data loss |
| Offline sync queue | `SyncService` + `SharedPreferences` | PowerSync | App lifecycle events, partial failures, conflict resolution, and queue durability require hundreds of lines of edge-case handling |
| Auth state navigation | `Navigator.pushNamed` conditionals everywhere | go_router `redirect` | Declarative redirect centralizes auth logic in one place; no drift between navigation entry points |
| API key security | Obfuscation in app bundle | Supabase Edge Functions + `Deno.env.get()` | Any key in the bundle can be extracted from the APK/IPA; server-side proxy is the only real protection |
| RLS testing | Manual SQL queries in Supabase dashboard | SDK + two-JWT test | SQL editor bypasses RLS; only SDK calls exercise the policy layer |

**Key insight:** In this foundation phase, all the "don't hand-roll" items have proven, well-documented solutions that the stack already includes. The cost of using them is configuration; the cost of not using them is a full rewrite.

---

## Common Pitfalls

### Pitfall 1: Integer PKs — "I'll Add UUIDs Later"

**What goes wrong:** Table is created with `autoIncrement()` PK. Offline inserts produce colliding IDs. When offline sync is added in Phase 8, every FK reference in the schema must be migrated.

**Why it happens:** Drift's default `integer().autoIncrement()` example is in every tutorial. Developers copy it without thinking about offline insert ID generation.

**How to avoid:** Use `text().clientDefault(() => const Uuid().v4())()` + `@override Set<Column> get primaryKey => {id}` on every table. This is a one-time decision in schemaVersion 1.

**Warning signs:** Any `IntColumn get id => integer().autoIncrement()()` in a table that will sync.

### Pitfall 2: RLS Disabled or Misconfigured

**What goes wrong:** In January 2025, 170+ apps exposed user data because RLS was off by default. User A's JWT can call `supabase.from('meal_plan_slots').select()` and read all users' data.

**Why it happens:** Supabase creates tables with RLS off. The SQL editor runs as superuser and bypasses RLS, so developers test successfully and ship. Real users get each other's data.

**How to avoid:**
- `ALTER TABLE x ENABLE ROW LEVEL SECURITY` immediately after `CREATE TABLE`
- Always include `WITH CHECK` on INSERT/UPDATE policies, not just `USING`
- Never validate RLS in the SQL editor — use client SDK with two test JWTs
- Add `user_id` index or every policy triggers a full table scan

**Warning signs:** Any table created without an immediate `ENABLE ROW LEVEL SECURITY` line.

### Pitfall 3: Supabase SQL Editor as RLS Validator

**What goes wrong:** Developer runs queries in the SQL editor, sees only their data, concludes RLS works. Ships. Any authenticated user can read all rows via the API.

**Why it happens:** The SQL editor is logged in as `postgres` role which has `BYPASSRLS`. It's invisible in the UI.

**How to avoid:** Create two test Supabase users. Sign in as User A in the Flutter app, insert a row. Sign in as User B, attempt to read User A's row via `supabase.from('table').select()`. If it returns data, RLS policy is missing or wrong.

**Warning signs:** "It works in the dashboard" used as evidence of correct RLS.

### Pitfall 4: drift_sqlite_async Beta Streaming Bug

**What goes wrong:** PowerSync syncs data to SQLite, but Drift `watchSingleOrNull()` / `watch()` streams never emit updates. Data is in the database but the UI doesn't update.

**Why it happens:** `drift_sqlite_async 0.2.6` is beta. For local-only tables where `viewName` differs from the table name, PowerSync notifies using internal names but Drift listens for view names. Stream updates are dropped.

**How to avoid:** Use the `transformTableUpdates` parameter when using local-only tables. Always write a smoke test in Phase 1 that:
1. Inserts a row into a Drift table
2. Verifies the `watch()` stream emits the updated value
3. Verifies a PowerSync-triggered update propagates through the stream

**Warning signs:** `watch()` returns a stream that only emits the initial value.

### Pitfall 5: Auth Redirect Race Condition

**What goes wrong:** App launches, router evaluates `redirect`, auth state is still loading (`AsyncLoading`). Router redirects to `/login`. User was already authenticated — they see a login flash on startup.

**Why it happens:** `Supabase.instance.client.auth.currentSession` is not synchronously available on app launch. The stream takes a moment to emit.

**How to avoid:** In the redirect callback, check for loading state and return `null` (no redirect) until auth state is resolved:
```dart
redirect: (context, state) {
  final authAsync = ref.read(authStateProvider);
  if (authAsync.isLoading || authAsync.hasError) return null; // Wait
  // ...rest of redirect logic
}
```

### Pitfall 6: Missing `WITH CHECK` on INSERT/UPDATE Policies

**What goes wrong:** User can insert a row with any `user_id` value (including another user's ID). Data is attributed to the wrong user.

**Why it happens:** Many tutorials only show `USING` clauses. `WITH CHECK` is required for write operations and is a separate concept.

**How to avoid:** Every INSERT policy must use `WITH CHECK ((SELECT auth.uid()) = user_id)`. Every UPDATE policy needs both `USING` and `WITH CHECK`.

---

## Code Examples

Verified patterns from official sources:

### Complete Drift Table Definition (Phase 1 standard)

```dart
// Source: drift.simonbinder.eu/dart_api/tables/
class MealPlanSlots extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get userId => text()();
  TextColumn get recipeId => text().nullable().references(Recipes, #id)();
  TextColumn get dayOfWeek => text()(); // 'monday'...'sunday'
  TextColumn get mealType => text()(); // 'breakfast' | 'lunch' | 'dinner'
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Supabase Initialization

```dart
// Source: supabase.com/docs/guides/getting-started/quickstarts/flutter
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    // Note: anonKey is safe to embed — it's restricted by RLS
    // The service_role key must NEVER be here
  );

  runApp(
    const ProviderScope(child: App()),
  );
}
```

### go_router with Auth Redirect (complete minimal example)

```dart
// Source: dinkomarinac.dev/guarding-routes-in-flutter-with-gorouter-and-riverpod
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      if (authAsync.isLoading || authAsync.hasError) return null;

      final isAuthenticated = authAsync.valueOrNull != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isGoingToLogin) return '/login';
      if (isAuthenticated && isGoingToLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const PlaceholderHomeScreen()),
    ],
  );
});
```

### Edge Function: Minimal Spoonacular Proxy

```typescript
// supabase/functions/recipe-proxy/index.ts
// Source: supabase.com/docs/guides/functions/secrets
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req: Request) => {
  const key = Deno.env.get('SPOONACULAR_API_KEY')!
  const { endpoint, params } = await req.json()

  const url = new URL(`https://api.spoonacular.com/${endpoint}`)
  url.searchParams.set('apiKey', key)
  for (const [k, v] of Object.entries(params ?? {})) {
    url.searchParams.set(k, String(v))
  }

  const resp = await fetch(url.toString())
  const data = await resp.json()
  return new Response(JSON.stringify(data), {
    headers: { 'Content-Type': 'application/json' },
    status: resp.status,
  })
})
```

### Drift Migration Strategy (template for Phase 1 → future phases)

```dart
// Source: drift.simonbinder.eu/migrations/
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(), // creates all tables at v1
  onUpgrade: (m, from, to) async {
    // Phase 1 is schemaVersion 1 — no upgrade needed yet
    // Future migrations will add columns here with: if (from < N) { ... }
  },
  beforeOpen: (details) async {
    // Enable WAL mode for better concurrent performance
    await customStatement('PRAGMA journal_mode = WAL');
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

### CI Workflow (GitHub Actions baseline)

```yaml
# .github/workflows/flutter.yml
name: Flutter CI
on: [push, pull_request]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.0'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Isar local DB | Drift | 2024 (Isar abandoned) | Isar is dead; Drift is the correct choice for all new Flutter projects |
| `Provider` package | `flutter_riverpod 3.x` | Oct 2025 (Riverpod 3.0) | Riverpod 3 added auto-retry, improved async safety; Provider is superseded |
| Navigator 2.0 manual auth guards | go_router `redirect` | 2022+ (now v17) | go_router is flutter.dev maintained and the standard; Navigator 2.0 directly is too verbose |
| `http` package | `dio ^5.9.2` | Ongoing | Dio adds interceptors, retry, cancellation — required for production API clients |
| Integer PKs with manual sync | UUID PKs from day one | N/A (always a design choice) | Integer PKs are fundamentally incompatible with offline-first multi-device sync |
| flutter_secure_storage v9 | flutter_secure_storage v10 | 2024 | v10 is a breaking security update (custom cipher, removes deprecated Jetpack Security) |
| drift_sqlite_async (alpha) | drift_sqlite_async 0.2.6 (beta) | Late 2025 | Beta now — verify streaming works in Phase 1 smoke test |

**Deprecated/outdated:**
- `Isar`: Abandoned by maintainer 2024 — do not use
- `Provider` package: Superseded by Riverpod from the same author
- `SharedPreferences` for auth tokens: Never appropriate for credentials
- Supabase Flutter v1 auth patterns: `OAuthProvider` was renamed in v2; check upgrade guide

---

## Open Questions

1. **drift_sqlite_async streaming reliability in production**
   - What we know: Version 0.2.6 is beta; local-only tables have a known streaming issue requiring `transformTableUpdates`
   - What's unclear: Whether any Phase 1 tables qualify as "local-only" or if all tables will be synced (and thus use standard table names)
   - Recommendation: Write a streaming smoke test in Phase 1 (`01-02` plan) that inserts a row and verifies `watch()` emits the update. Fail the plan if it doesn't.

2. **Supabase new API key format (`sb_publishable_xxx`)**
   - What we know: Supabase announced a transition from `anon`/`service_role` keys to `sb_publishable_xxx` format (from GitHub discussions, March 2026)
   - What's unclear: Whether newly created projects in March 2026 use the old format, new format, or both
   - Recommendation: When creating the Supabase project in `01-03`, document which key format is issued. If `sb_publishable_xxx`, update initialization code accordingly. Both formats work with `supabase_flutter ^2.12.0`.

3. **PowerSync project setup requirements**
   - What we know: PowerSync requires a separate project on powersync.com dashboard (not just the Supabase dashboard) with a connector configured to the Supabase PostgreSQL instance
   - What's unclear: Whether Phase 1 should set up the PowerSync dashboard project now or defer to Phase 8 (sync phase)
   - Recommendation: Scaffold the PowerSync database class and `drift_sqlite_async` connection in Phase 1 to validate compatibility, but defer the full PowerSync dashboard project creation and sync configuration to Phase 8. Use Drift in standalone mode (without sync) for phases 2–7.

---

## Validation Architecture

`workflow.nyquist_validation` is not present in `.planning/config.json` (the key does not exist in the config). Skipping this section.

---

## Sources

### Primary (HIGH confidence)
- [drift.simonbinder.eu/docs/getting-started/](https://drift.simonbinder.eu/docs/getting-started/) — dependency setup, database class, build_runner command
- [drift.simonbinder.eu/dart_api/tables/](https://drift.simonbinder.eu/dart_api/tables/) — UUID clientDefault, custom primaryKey override
- [drift.simonbinder.eu/migrations/](https://drift.simonbinder.eu/migrations/) — schemaVersion, onUpgrade, make-migrations command
- [supabase.com/docs/guides/database/postgres/row-level-security](https://supabase.com/docs/guides/database/postgres/row-level-security) — RLS enable, USING/WITH CHECK policies, `(SELECT auth.uid())` performance pattern
- [supabase.com/docs/guides/functions/secrets](https://supabase.com/docs/guides/functions/secrets) — Deno.env.get(), secrets set CLI, .env for local dev
- [supabase.com/docs/guides/functions/quickstart-dashboard](https://supabase.com/docs/guides/functions/quickstart-dashboard) — Edge Function structure, deploy workflow

### Secondary (MEDIUM confidence)
- [docs.powersync.com/client-sdk-references/flutter/flutter-orm-support](https://docs.powersync.com/client-sdk-references/flutter/flutter-orm-support) — SqliteAsyncDriftConnection pattern (vendor docs)
- [pub.dev/packages/drift_sqlite_async](https://pub.dev/packages/drift_sqlite_async) — version 0.2.6, drift >=2.28.0 <3.0.0 compatibility (pub.dev registry)
- [dinkomarinac.dev/guarding-routes-in-flutter-with-gorouter-and-riverpod](https://dinkomarinac.dev/guarding-routes-in-flutter-with-gorouter-and-riverpod) — go_router + Riverpod redirect pattern (community, cross-verified with go_router docs)
- [apparencekit.dev/blog/flutter-riverpod-gorouter-redirect/](https://apparencekit.dev/blog/flutter-riverpod-gorouter-redirect/) — routerProvider + refreshListenable pattern (community, corroborated by multiple sources)
- [.planning/research/STACK.md](../../research/STACK.md) — full stack versions, verified against pub.dev (previous project research, 2026-03-02)
- [.planning/research/ARCHITECTURE.md](../../research/ARCHITECTURE.md) — architecture patterns, data flow, anti-patterns (previous project research, 2026-03-02)
- [.planning/research/PITFALLS.md](../../research/PITFALLS.md) — UUID PK pitfall, RLS pitfall, migration pitfall (previous project research, 2026-03-02)

### Tertiary (LOW confidence)
- WebSearch: GitHub Actions Flutter CI patterns — multiple community sources, basic structure consistent across all sources

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions verified against pub.dev and official docs
- Architecture patterns (Drift tables, go_router redirect): HIGH — verified against official documentation
- PowerSync/Drift bridge: MEDIUM — drift_sqlite_async 0.2.6 is beta; known streaming issue documented; compatibility range confirmed from pub.dev
- RLS policies: HIGH — verified directly from supabase.com/docs/guides/database/postgres/row-level-security
- Edge Functions proxy: HIGH — verified from supabase.com/docs/guides/functions/secrets
- Pitfalls: HIGH for UUID PKs, RLS, auth race condition — all verified. MEDIUM for drift_sqlite_async streaming bug (from vendor docs, beta package)

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (30 days — stable stack; drift_sqlite_async beta status may change sooner)
