# Stack Research

**Domain:** Cross-platform mobile app — meal planning with offline-first support, recipe APIs, and AI generation
**Researched:** 2026-03-02
**Confidence:** MEDIUM-HIGH (core stack HIGH, API selection MEDIUM, AI integration MEDIUM)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Flutter | 3.41.x (stable) | Cross-platform mobile UI (iOS + Android) | Decision already made; current stable is 3.41 (Feb 2026), well-suited to this app's UI complexity |
| Dart | 3.10.x | Primary language | Ships with Flutter 3.41 |
| Supabase (hosted) | latest | PostgreSQL DB, auth, realtime | Decision already made; built-in auth, RLS for GDPR data isolation, realtime subscriptions for cross-device sync |
| supabase_flutter | ^2.12.0 | Flutter client for Supabase | Official Supabase Flutter client; latest stable 2.12.0; supports email/password auth and realtime Postgres changes out of the box |
| flutter_riverpod | ^3.2.1 | State management | Riverpod 3.x is the current community standard for Flutter in 2026; compile-time safety, built-in async/caching, minimal boilerplate; Riverpod 3.0 (Oct 2025) added auto-retry, experimental offline caching. Better DX than BLoC for this project's complexity level. |

### State Management — Riverpod Generator Stack

These three packages work as a unit for the Riverpod code-generation workflow:

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_riverpod | ^3.2.1 | Runtime provider infrastructure | Always — the core package |
| riverpod_annotation | ^4.0.2 | Annotations for code generation | With riverpod_generator; eliminates manual provider boilerplate |
| riverpod_generator | ^4.0.3 | Code generator for providers | Run via `build_runner`; use for all providers in this project |
| build_runner | ^2.4.x | Dart code generation runner | Required to run `riverpod_generator` and `freezed` |

### Database & Offline Storage

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| drift | ^2.32.0 | Local SQLite ORM — offline-first data layer | Primary local database; stores cached recipes, meal plans, shopping lists; type-safe SQL with migrations; actively maintained (v2.32.0 published 41 hours prior to research) |
| powersync | ^1.17.0 | Offline-first sync engine (Supabase <-> SQLite) | Recommended over manual sync implementation; PowerSync provides automatic two-way sync between Supabase Postgres and local SQLite (via Drift); handles conflict resolution with LWW by default; production-ready with verified publisher |

### Networking & APIs

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| dio | ^5.9.2 | HTTP client | All external API calls (Spoonacular, OpenAI); interceptors for auth headers, retry logic, and error normalization |
| connectivity_plus | ^7.0.0 | Network state detection | Detect online/offline state to gate sync attempts; Flutter Favorite with 2M+ downloads |

### Data Modeling

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| freezed | ^3.2.5 | Immutable data classes with union types | Domain models (Recipe, MealPlan, ShoppingList); Flutter Favorite; generates copyWith, equality, toString |
| freezed_annotation | ^2.4.x | Annotations for freezed code generation | Required companion to freezed |
| json_serializable | ^6.13.0 | JSON encode/decode code generation | API response deserialization; 2.33M downloads; Flutter Favorite; use with `@JsonSerializable` annotation |
| json_annotation | ^4.9.x | Annotations for json_serializable | Required companion |

### Navigation

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| go_router | ^17.1.0 | Declarative navigation | Standard navigation for this app; Flutter Favorite, published by flutter.dev; supports deep linking; feature-complete and stable |

### Persistence & Security

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_secure_storage | ^10.0.0 | Encrypted storage for sensitive data | Store Supabase auth tokens, API keys; uses RSA OAEP + AES-GCM on Android/iOS; v10.0.0 is a major security update (custom cipher, removes deprecated Jetpack Security) |
| shared_preferences | ^2.5.4 | Simple non-sensitive key-value storage | UI preferences, onboarding flags, last-used filters |

### Image Caching

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| cached_network_image | ^3.4.1 | Cache recipe images for offline viewing | Recipe image display; 6.9k likes, 2M+ downloads; handles offline gracefully by serving cached images |

### Background Sync

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| workmanager | ^0.9.0+3 | Background task scheduling | Periodic background sync when app is closed; supports Android WorkManager + iOS Background Tasks; runs sync queue flush on connectivity restore |

### AI Recipe Generation

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| dart_openai | ^6.1.1 | OpenAI API client | Generate custom recipes from selected ingredients via GPT-4; unofficial but comprehensive; 6.1.1 published 3 months prior; covers chat completions, streaming |

### Recipe Data Source: Spoonacular

See "API Selection" section below for full comparison. Spoonacular is the recommended external recipe API.

---

## API Selection: Spoonacular (Recommended)

**Verdict: Spoonacular for recipes, OpenFoodFacts for ingredient autocomplete.**

### Recipe API Comparison

| Criterion | Spoonacular | Edamam | TheMealDB | OpenFoodFacts |
|-----------|-------------|--------|-----------|---------------|
| Recipe count | 365,000+ | 2.3M | ~283 meals (limited) | 0 (product DB, not recipes) |
| Free tier | 50 points/day (very restrictive) | No free tier — 10-day trial only | Fully free | Fully free (no recipes) |
| Paid entry | $29/mo (1,500 pts/day) | $9/mo (10K calls/mo) | $2/mo (Patreon) | N/A |
| Features | Recipe search, meal planning endpoints, ingredient parsing, unit normalization | Nutrition focus, allergens | Basic recipe search | Product/ingredient data only |
| Flutter package | None (use Dio) | None (use Dio) | None (use Dio) | `openfoodfacts ^3.30.2` |
| Meal planning support | Yes (native endpoints) | No | No | No |
| Unit normalization | Yes (ingredient parsing API) | Partial | No | No |

**Choose Spoonacular because:**

1. It has native meal planning endpoints that reduce custom logic needed
2. Its ingredient parsing API directly solves the unit normalization challenge described in PROJECT.md
3. Its 365K recipe database is sufficient for MVP
4. $29/month Cook plan (1,500 points/day) is affordable and sufficient for MVP development and early users
5. Free tier (50 pts/day) works for development testing

**Use OpenFoodFacts** (`openfoodfacts ^3.30.2`) for ingredient autocomplete/search within the ingredient selection flow. It is completely free, has 2.9M+ products, officially maintained by the OpenFoodFacts org, and covers ingredient metadata (allergens, NOVA group) better than recipe APIs.

**Do NOT use TheMealDB** for a production app: only ~283 meals available, no meal planning endpoints, no ingredient parsing.
**Do NOT use Edamam** for MVP: no free tier, higher cost, nutrition-focused rather than meal planning-focused.

---

## Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Flutter DevTools | Performance profiling, widget inspector | Built into Flutter; use for identifying rebuild issues |
| `build_runner` | Code generation | Run `flutter pub run build_runner build --delete-conflicting-outputs` after modifying freezed/riverpod/json_serializable models |
| Supabase CLI | Local Supabase dev, migrations, RLS testing | `supabase start` for local dev; essential for testing RLS policies before deploying |
| VS Code + Flutter extension | Primary IDE | Riverpod snippets extension available |
| flutter_lints | Lint rules | Official Flutter lint rules package |

---

## Installation

```bash
# Add to pubspec.yaml dependencies:
flutter pub add flutter_riverpod
flutter pub add supabase_flutter
flutter pub add drift
flutter pub add powersync
flutter pub add dio
flutter pub add connectivity_plus
flutter pub add freezed_annotation
flutter pub add json_annotation
flutter pub add go_router
flutter pub add flutter_secure_storage
flutter pub add shared_preferences
flutter pub add cached_network_image
flutter pub add workmanager
flutter pub add dart_openai
flutter pub add openfoodfacts
flutter pub add riverpod_annotation

# Add to pubspec.yaml dev_dependencies:
flutter pub add --dev build_runner
flutter pub add --dev riverpod_generator
flutter pub add --dev freezed
flutter pub add --dev json_serializable
flutter pub add --dev drift_dev
```

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| State management | Riverpod 3.x | BLoC | BLoC requires more boilerplate (Events, States, Blocs); better suited for teams with strict separation requirements or 20+ screen apps; Riverpod's async providers handle the recipe-loading/caching patterns more naturally |
| State management | Riverpod 3.x | Provider | Provider is superseded by Riverpod from the same author; lacks compile-time safety; Riverpod is the direct upgrade path |
| State management | Riverpod 3.x | GetX | GetX is opinionated and anti-pattern heavy; poor testability; not recommended by Flutter community for production apps |
| Local database | Drift | Isar | Isar is faster for NoSQL bulk operations but the project maintainer abandoned it; do not use for new projects in 2026 |
| Local database | Drift | sqflite | sqflite requires raw SQL; no type safety; Drift is the type-safe abstraction over sqflite that is the better default |
| Offline sync | PowerSync | Manual Supabase realtime | Manual realtime sync fails on connection drops, requires custom conflict resolution; PowerSync handles this reliably |
| Offline sync | PowerSync | Brick | Brick is a viable alternative but less mature with Supabase; PowerSync has first-class Supabase integration |
| Recipe API | Spoonacular | Edamam | No permanent free tier; nutrition-focused, not meal-planning-focused; overkill for MVP |
| Recipe API | Spoonacular | TheMealDB | Only 283 meals; not viable for a real product |
| AI integration | dart_openai (OpenAI) | Google Gemini (google_generative_ai) | Both are viable; OpenAI's GPT-4 is the stronger model for structured recipe generation with JSON output mode; Gemini is a reasonable swap if cost is a concern |
| Navigation | go_router | auto_route | auto_route is code-generation heavy; go_router is simpler, flutter.dev maintained, and sufficient for this app's navigation needs |
| Image caching | cached_network_image | flutter_cache_manager | cached_network_image wraps flutter_cache_manager; use cached_network_image directly for widget integration |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `Provider` package | Deprecated by Riverpod (same author); lacks compile-time safety; no code generation | `flutter_riverpod ^3.2.1` |
| `Isar` database | Project abandoned by maintainer in 2024; no active maintenance | `drift ^2.32.0` |
| `hive` / `hive_flutter` | Not suitable as primary DB for relational data (meal plans reference recipes, shopping lists reference plans); no migrations | `drift` for relational data |
| `GetX` | Anti-patterns, poor testability, not aligned with Flutter architecture recommendations | `flutter_riverpod` + `go_router` |
| `http` package (dart:http) | Too low-level for production use — no interceptors, no automatic retry, no request cancellation | `dio ^5.9.2` |
| ElectricSQL | Does not handle client-side persistence; requires custom implementation | `powersync ^1.17.0` |
| Edamam Recipe API | No free tier (10-day trial only); $9/mo minimum; nutrition focus doesn't serve meal planning | Spoonacular at $29/mo |
| TheMealDB as primary recipe source | Only ~283 meals — far too small for a real product; no meal planning endpoints | Spoonacular |
| Raw `SharedPreferences` for auth tokens | Plain-text storage; violates GDPR/security best practices for personal data | `flutter_secure_storage ^10.0.0` |
| Supabase Realtime alone for offline sync | Works only when connected; no local persistence; breaks the offline-first requirement | `powersync` (adds SQLite layer) |

---

## Stack Patterns by Variant

**If budget for AI is constrained:**
- Swap `dart_openai` for `google_generative_ai` (Gemini)
- Gemini has a more generous free tier than OpenAI
- API contract differences are minimal for chat-completion-style recipe generation

**If Spoonacular cost is a blocker at MVP:**
- Use TheMealDB for seed/demo data only (it's free)
- Supplement with AI-generated recipes (OpenAI/Gemini)
- Accept smaller recipe browsing catalog until paid tier is funded
- Warning: TheMealDB's 283 meals will feel limited quickly

**If you need to test offline logic without PowerSync:**
- Use Drift alone with manual `isSynced` flags on records
- Implement a simple sync queue in Drift
- This is a valid prototype approach but requires rebuilding with PowerSync for production reliability

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `flutter_riverpod ^3.2.1` | `riverpod_generator ^4.0.3`, `riverpod_annotation ^4.0.2` | All three must be upgraded together; 3.x is a breaking change from 2.x |
| `freezed ^3.2.5` | `freezed_annotation ^2.4.x`, `build_runner ^2.4.x` | freezed 3.0 introduced breaking changes from 2.x; new projects start on 3.x |
| `drift ^2.32.0` | `drift_dev ^2.32.0` | drift and drift_dev must be on the same major version |
| `json_serializable ^6.13.0` | `json_annotation ^4.9.x` | Must be compatible versions; json_serializable 6.x requires json_annotation 4.x |
| `supabase_flutter ^2.12.0` | Flutter 3.10+ | Supabase 2.x dropped Flutter 2.x support |
| `powersync ^1.17.0` | `supabase_flutter ^2.x`, `drift ^2.x` | PowerSync uses Drift internally; verify PowerSync's drift dependency version matches yours |

---

## GDPR Compliance Notes

Supabase's Row Level Security (RLS) is the primary technical control for GDPR data isolation. Every user-specific table (meal_plans, shopping_lists, favorites, user_recipes) must have RLS enabled with `auth.uid() = user_id` policies. In January 2025, 83% of exposed Supabase databases involved RLS misconfigurations — this must be enabled from day one, not retrofitted.

For consent management, no third-party consent SDK is required for this app's v1 scope (no ads, no analytics SDKs). Standard Supabase auth with clear privacy policy and data deletion endpoint (Supabase `auth.admin.deleteUser()`) is sufficient for GDPR MVP compliance.

---

## Sources

- `flutter_riverpod ^3.2.1` — pub.dev verified (published 26 days prior to research); riverpod.dev official docs
- `supabase_flutter ^2.12.0` — pub.dev verified (supabase.io publisher); supabase.com/docs/guides/getting-started/quickstarts/flutter
- `drift ^2.32.0` — pub.dev verified (published 41 hours prior to research); actively maintained
- `powersync ^1.17.0` — pub.dev verified (powersync.com publisher); powersync.com/blog/offline-first-apps-made-simple-supabase-powersync
- `freezed ^3.2.5` — pub.dev verified (dash-overflow.net publisher); Flutter Favorite
- `go_router ^17.1.0` — pub.dev verified (flutter.dev publisher); Flutter Favorite
- `flutter_secure_storage ^10.0.0` — pub.dev verified; v10.0.0 major security update confirmed
- `connectivity_plus ^7.0.0` — pub.dev verified (fluttercommunity.dev); Flutter Favorite; 2M+ downloads
- `dio ^5.9.2` — pub.dev verified (published 9 hours prior to research)
- `dart_openai ^6.1.1` — pub.dev verified; API coverage table updated Nov 2025
- `openfoodfacts ^3.30.2` — pub.dev verified (openfoodfacts.org publisher); actively maintained
- `workmanager ^0.9.0+3` — pub.dev verified (fluttercommunity.dev publisher)
- `riverpod_generator ^4.0.3` — pub.dev verified; compatible with riverpod_annotation 4.0.2
- Spoonacular pricing — spoonacular.com/food-api/pricing (fetched 2026-03-02); free: 50 pts/day, Cook: $29/mo
- Edamam pricing — developer.edamam.com (fetched 2026-03-02); no free tier, $9/mo minimum
- Flutter 3.41 stable — docs.flutter.dev/release/whats-new (fetched 2026-03-02)
- Supabase RLS statistics — WebSearch result citing January 2025 data: 83% of exposed Supabase DBs had RLS misconfiguration (MEDIUM confidence — single source)
- Isar abandonment — multiple sources (greenrobot.org, dinkomarinac.dev) consistently report maintainer departure (MEDIUM confidence — WebSearch verified across sources)

---
*Stack research for: MealMate — Flutter + Supabase meal planning mobile app*
*Researched: 2026-03-02*
