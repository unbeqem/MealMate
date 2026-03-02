# Project Research Summary

**Project:** MealMate
**Domain:** Offline-first cross-platform mobile meal planning app (Flutter + Supabase)
**Researched:** 2026-03-02
**Confidence:** MEDIUM-HIGH

## Executive Summary

MealMate is a meal planning mobile app differentiated by ingredient-based recipe discovery, AI recipe generation, and an explicit food waste reduction mission. No direct competitor combines all three. The research consensus is clear: this app must be built offline-first from day one, with local SQLite (Drift) as the primary source of truth and Supabase as the sync target — not the other way around. Users will use shopping lists in grocery stores with poor or no connectivity; retrofitting offline support into an online-first architecture is one of the most common and expensive mistakes in this domain.

The recommended stack is Flutter 3.41 + Riverpod 3.x + Drift + PowerSync + Supabase, with Spoonacular as the external recipe API and OpenAI GPT-4 for AI recipe generation. These choices are well-validated by current community practice and official documentation. The feature scope is well-defined: the v1 core loop is ingredient selection → recipe browsing/generation → weekly meal planner → auto-generated shopping list → offline access. Everything beyond this loop is v1.x or v2+.

The most consequential risks cluster around the foundation phase: using integer primary keys instead of UUIDs will block offline record creation; missing Supabase RLS from day one is a GDPR breach waiting to happen; and treating the offline cache as a later addition will force a full architecture rewrite. All three of these must be addressed before writing any feature code. Secondary risks include AI hallucination poisoning the shopping list pipeline, and unit normalization being underestimated as a simple lookup table when it requires a multi-stage normalization pipeline.

## Key Findings

### Recommended Stack

The Flutter + Supabase + Riverpod combination is well-established and appropriate for this product's complexity. Riverpod 3.x (released Oct 2025) adds compile-time safety and auto-retry that previous state management options lacked. The offline-first requirement dictates the most consequential stack decision: Drift (local SQLite ORM) as the primary data store, with PowerSync providing automatic bidirectional sync between Drift and Supabase. Manual sync implementation is explicitly an anti-pattern here — it becomes the most complex and buggy part of the app.

For external data, Spoonacular ($29/mo Cook plan) is the clear recipe API choice due to native meal planning endpoints and an ingredient parsing API that directly solves the unit normalization challenge. OpenFoodFacts (free) handles ingredient autocomplete. OpenAI GPT-4 via `dart_openai` handles AI recipe generation; Gemini is a viable swap if cost becomes a constraint. API keys must never be embedded in the Flutter app bundle — proxy through Supabase Edge Functions.

**Core technologies:**
- Flutter 3.41 + Dart 3.10: cross-platform mobile UI — decision already made; current stable
- Riverpod 3.2.1 + codegen: state management — compile-time safety, async caching, best DX for this complexity level
- Drift 2.32.0: local SQLite ORM — primary source of truth for all persistent data; type-safe migrations
- PowerSync 1.17.0: offline sync engine — automatic Supabase ↔ Drift two-way sync with LWW conflict resolution
- Supabase (hosted): auth + PostgreSQL remote store — RLS for GDPR data isolation; auth built-in
- Spoonacular: external recipe API — native meal planning endpoints, ingredient parsing, 365K+ recipes
- dart_openai 6.1.1: AI recipe generation — GPT-4 structured JSON output for recipe creation
- go_router 17.1.0: navigation — Flutter.dev maintained, declarative, deep linking support
- freezed 3.2.5: domain models — immutable value objects with unions for Recipe, MealPlan, ShoppingItem
- flutter_secure_storage 10.0.0: auth token storage — major security update, RSA OAEP + AES-GCM

**Packages to avoid:** Isar (abandoned 2024), GetX (anti-patterns), Provider (superseded), Supabase Realtime alone for offline sync, raw SharedPreferences for auth tokens, integer PKs for any synced table.

### Expected Features

The feature landscape is well-mapped by competitor analysis. No competitor combines ingredient-first discovery + AI generation + food waste framing — this is a real uncontested gap. The core loop has 10 must-have features; everything else is v1.x or later.

**Must have (table stakes):**
- User auth (email/password via Supabase) — required to persist any data
- Ingredient selection with search — primary entry point for the whole flow
- Recipe browsing filtered by ingredients (Spoonacular API) — core value delivery
- Dietary restriction filters (vegetarian, vegan, gluten-free, dairy-free) — expected by ~30% of users
- Recipe detail view with serving size scaling — needed before planning
- 7-day weekly meal planner (breakfast/lunch/dinner slots) — the calendar is the product
- Shopping list auto-generated from meal plan with unit normalization and deduplication — completes the core loop
- Manual shopping list editing (add/remove/check-off) — list is unusable in-store without this
- Offline access (cached meal plan + shopping list via Drift) — non-negotiable for in-store use
- AI recipe generation from selected ingredients (LLM fallback when API returns nothing) — differentiator from day 1

**Should have (competitive):**
- Recipe favorites / personal cookbook — drives retention via invested collection
- Meal plan templates / saved weeks — reduces weekly re-planning friction for power users
- Shopping list categorized by store section — significant UX improvement, low cost
- Drag-and-drop meal rescheduling — friction reduction in the planner
- Push notifications for dinner reminders — engagement driver; 4-week retention correlation
- Household / shared shopping list (Supabase Realtime) — significant for families

**Defer (v2+):**
- Pantry inventory tracking — high maintenance burden, separate product complexity
- Price comparison across supermarkets — requires retailer API partnerships
- Grocery delivery integration — requires retailer partnerships
- Recipe import from URL — schema.org parsing is brittle
- Social/community features — different product thesis; compete here after PMF
- "What's expiring soon" smart suggestions — depends on pantry tracking

**Anti-features to avoid building:** full pantry inventory, barcode scanning, gamification/streaks, macro nutrition tracking.

### Architecture Approach

The architecture is a clean feature-first Flutter app with four strict layers: UI (screens/widgets) → State (Riverpod Notifiers) → Repository (single source of truth boundary) → Data (Drift local DB + remote services). All reads and writes go through local SQLite; Supabase is never called from the UI or Notifiers directly. The sync engine (PowerSync) operates as a background process that watches connectivity, queues pending writes, and uploads to Supabase asynchronously. This architecture means the UI has zero network latency for all read/write operations.

**Major components:**
1. UI Layer (Flutter screens + widgets) — observes Riverpod providers only; no direct data access
2. Riverpod Notifiers (AsyncNotifier per feature) — transform repository data into UI state; one per feature domain
3. Repository Layer (IngredientRepo, RecipeRepo, MealPlanRepo, ShoppingListRepo) — single source of truth; owns local/remote routing
4. Local SQLite via Drift — primary source of truth; all tables include `sync_status` + `updated_at` from day one
5. SyncEngine (PowerSync) — background bidirectional sync, LWW conflict resolution
6. RecipeAPIClient (Spoonacular via Dio) — cached to SQLite on first fetch; never re-fetched
7. LLMClient (OpenAI via dart_openai) — always requires connectivity; results cached to SQLite with `source = 'ai_generated'`
8. Supabase (auth + PostgreSQL) — sync target, never direct read source; RLS enforced on all user tables

The feature-first project structure (`lib/features/{auth,ingredients,recipes,meal_plan,shopping_list}/`) with data/domain/presentation sub-layers per feature is the prescribed organization. Cross-cutting infrastructure (database, sync, Supabase client) lives in `lib/core/`.

### Critical Pitfalls

1. **UUID primary keys are non-negotiable** — Integer/serial PKs cause collision when records are created offline on multiple devices. Every user-facing table must use UUID v4 PKs generated client-side. This cannot be retrofitted after launch without a full data migration. Fix: set this in the schema before writing any insert.

2. **Supabase RLS disabled or misconfigured** — RLS is off by default; in Jan 2025, 170+ apps exposed all user data. The SQL editor runs as superuser and bypasses RLS entirely, giving a false sense of correctness. Fix: enable RLS on every table immediately after creation, write policies alongside table creation, and test with real JWTs from two separate test accounts.

3. **Offline-first treated as a later addition** — The most expensive architectural mistake. Retrofitting a repository/cache layer onto an online-first app requires rewriting every data-access call. Fix: implement the repository abstraction before the first Supabase call, even if the initial implementation is Supabase-only behind the interface.

4. **Unit normalization underestimated** — "2 cups + 150g flour" cannot be summed with a simple lookup table; it requires a 5-stage pipeline (lexical normalization → unit family classification → intra-family conversion → cross-family conflict handling → ingredient-specific density table). Treating this as simple produces a broken shopping list. Fix: build and exhaustively unit-test the normalization pipeline as a standalone domain service before wiring it to the shopping list.

5. **AI hallucinations poisoning the shopping list** — LLMs generate nonsensical quantities ("1/8 egg"), mismatched units, and out-of-scope ingredients that feed directly into the normalization pipeline. Fix: enforce structured JSON schema output, validate generated ingredients against the known ingredient list, add quantity sanity checks, and never let AI output flow directly into shopping list aggregation without a validation gate.

## Implications for Roadmap

Based on research, the architecture build order maps directly to a natural phase structure. Dependencies are strict: auth and schema must exist before features, offline architecture must exist before feature code, shopping list depends on meal plan.

### Phase 1: Foundation (Infrastructure + Auth)

**Rationale:** Every feature depends on auth for RLS scoping, and the Drift schema defines the domain models that all feature code builds on. Changing schema or PKs after features are built is the highest-cost change in this domain. Auth guards must exist before any screen can be built correctly.

**Delivers:** Working auth flow (register/login/logout), Drift database with all tables (UUID PKs, sync_status columns), Supabase project with RLS enabled on all tables, go_router with auth guard, Supabase Edge Functions scaffold for API key proxying.

**Addresses:** User auth (table stakes), offline architecture prerequisite, Supabase project setup.

**Avoids:** Pitfall 1 (integer PKs), Pitfall 4 (RLS), Pitfall 8 (offline-first treated as Phase 2), Pitfall 10 (SQLite migrations), Pitfall 9 (GDPR deletion endpoint scaffold).

**Research flag:** Standard patterns — auth with Supabase + go_router is well-documented. No additional research needed.

---

### Phase 2: Ingredient + Recipe Core

**Rationale:** Ingredient selection is the entry point for the entire product. Recipe browsing depends on ingredient selection and the external API. This phase establishes the Spoonacular integration with SQLite caching, which the meal planner depends on.

**Delivers:** Ingredient selection screen with OpenFoodFacts search, dietary filter preferences, recipe browsing screen filtered by selected ingredients (Spoonacular), recipe detail view with serving size scaling, SQLite caching of all API responses.

**Addresses:** Ingredient selection (P1), recipe browsing (P1), dietary filters (P1), recipe detail + scaling (P1).

**Uses:** Spoonacular API via Dio, OpenFoodFacts package, Drift caching, freezed domain models (Recipe, Ingredient).

**Avoids:** Pitfall 7 (API rate exhaustion — cache from day 1, mock in tests, separate API keys per environment).

**Research flag:** Standard patterns — Spoonacular REST integration via Dio is straightforward. API quota management needs attention but is not complex.

---

### Phase 3: Meal Planning + Shopping List

**Rationale:** The 7-day planner is the central product surface. Shopping list generation is the output of the planner and cannot be built before meals are assignable to slots. Unit normalization must be designed and tested before the shopping list UI is wired.

**Delivers:** 7-day meal planner grid with tap-to-assign recipe slots, shopping list auto-generated from meal plan with unit normalization and deduplication, manual shopping list editing (add/remove/check-off).

**Addresses:** 7-day meal planner (P1), shopping list with deduplication (P1), unit normalization engine (P1), manual list editing (P1).

**Implements:** MealPlanRepository, ShoppingListRepository, unit normalizer as isolated domain service.

**Avoids:** Pitfall 3 (unit normalization naivety — build and test the normalization pipeline as a standalone service before wiring to UI), Anti-Pattern 3 (shopping list computed in UI).

**Research flag:** Unit normalization logic warrants deeper research during planning — specifically the 5-stage pipeline and ingredient-specific density table for baking ingredients.

---

### Phase 4: AI Recipe Generation

**Rationale:** AI generation is the fallback path when Spoonacular returns no results for a selected ingredient combination. It requires the recipe display and caching infrastructure from Phase 2 to exist first. AI-generated recipes must flow through the same Recipe domain model.

**Delivers:** AI recipe generation from selected ingredients (GPT-4 via dart_openai), structured JSON schema enforcement on AI output, ingredient whitelist validation gate, AI recipe caching to SQLite with `source = 'ai_generated'` flag, streaming loading UI.

**Addresses:** AI recipe generation from ingredients (P1 differentiator).

**Avoids:** Pitfall 5 (AI hallucinations — JSON schema validation, quantity sanity checks, ingredient whitelist before DB insert), UX pitfall (duplicate recipes from double-taps — disable button during request).

**Research flag:** OpenAI structured output / JSON schema mode for recipe generation warrants research during planning to define the exact schema and prompt constraints.

---

### Phase 5: Offline Sync

**Rationale:** Features are built offline-first with Drift as source of truth from Phase 1, but the PowerSync sync engine is layered in here. This separation means features can be tested without sync complexity, and sync failures don't compound with feature failures.

**Delivers:** PowerSync integration for bidirectional Supabase ↔ Drift sync, LWW conflict resolution, connectivity detection, offline mode UI indicators, pending sync badges, background sync via WorkManager.

**Addresses:** Offline access (P1 — read capability exists from Phase 1, sync confirmed in this phase).

**Uses:** powersync 1.17.0, connectivity_plus, workmanager.

**Avoids:** Pitfall 2 (custom sync layer — use PowerSync), Pitfall 6 (Realtime subscription memory leaks — manage channel lifecycle at provider level), UX pitfall (no visual offline indicator).

**Research flag:** PowerSync + Drift integration needs careful attention during planning — verify PowerSync's Drift dependency version matches the project's drift version (known compatibility constraint from STACK.md).

---

### Phase 6: Polish + v1.x Features

**Rationale:** Once the core loop is validated by real usage, add the features that drive retention and multi-user value. Polish also addresses UX gaps identified in pitfalls research.

**Delivers:** Recipe favorites, meal plan templates, shopping list categorized by store section, drag-and-drop rescheduling, push notifications (FCM/APNs), household sharing (Supabase Realtime), undo for destructive planner actions, recipe image caching (cached_network_image).

**Addresses:** P2 features: favorites, templates, store-section categories, drag-and-drop, notifications, household sharing.

**Avoids:** UX pitfalls (no undo for "remove recipe", flat 40+ item shopping list, meal planner with no thumbnails).

**Research flag:** Household sharing requires a group/household data model — needs schema design during planning. Push notifications (FCM/APNs setup) is standard but requires platform configuration.

---

### Phase Ordering Rationale

- Foundation before everything: Drift schema defines domain models; UUID PKs and RLS cannot be retrofitted. One day of setup avoids a week of migration.
- Ingredient/Recipe before Meal Plan: You can't assign a recipe to a meal slot if recipe browsing doesn't work. The recipe cache must be populated before the planner is testable.
- Shopping List after Meal Plan: Aggregation logic reads from the meal plan; it cannot be built in isolation.
- AI after basic recipe infrastructure: AI-generated recipes must flow into the same Recipe model and cache. The model must exist first.
- Sync after features: Features work correctly offline (Drift as source of truth) before adding sync complexity. Two failure modes at once is a debugging nightmare.
- Polish last: Optimize retention features after the core loop is validated, not before.

### Research Flags

**Needs deeper research during planning:**
- **Phase 3 (Unit Normalization):** The 5-stage normalization pipeline — specifically the ingredient-specific density table for ~20 common baking ingredients and the cross-family conflict handling UX decision.
- **Phase 4 (AI Recipe Generation):** OpenAI JSON schema mode for structured recipe output — define the exact schema, prompt constraints, and RAG approach for ingredient whitelisting.
- **Phase 5 (PowerSync Integration):** Verify PowerSync 1.17.0 dependency on Drift version; integration patterns for conflict resolution edge cases.
- **Phase 6 (Household Sharing):** Group/household data model design — affects auth schema (foreign keys) and RLS policies.

**Standard patterns (skip research-phase):**
- **Phase 1 (Auth + Foundation):** Supabase auth + go_router + RLS is thoroughly documented with official sources.
- **Phase 2 (Recipe API):** Spoonacular REST via Dio + Drift caching is standard; the only nuance (quota management) is already documented in PITFALLS.md.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Core stack (Flutter, Riverpod, Drift, Supabase) verified against official pub.dev and documentation. PowerSync integration MEDIUM — vendor docs only. AI package (dart_openai) MEDIUM — unofficial client. |
| Features | MEDIUM | Based on competitor analysis and multiple review sources. No direct user interviews. Core feature landscape is well-established; differentiator rankings are interpretive but corroborated by multiple sources. |
| Architecture | HIGH | Sourced from official Flutter app architecture guide and Andrea Bizzotto's widely-cited Riverpod architecture series. Patterns are well-validated. |
| Pitfalls | MEDIUM | RLS and offline-first pitfalls are HIGH confidence (official Supabase docs + real breach data). Unit normalization complexity is MEDIUM. AI hallucination pitfall is LOW-MEDIUM (community sources). |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **Spoonacular ingredient parsing API vs. custom normalization:** STACK.md notes Spoonacular has an ingredient parsing API that "directly solves" unit normalization. PITFALLS.md describes a custom 5-stage normalization pipeline. These should be reconciled during Phase 3 planning — evaluate whether the Spoonacular ingredient parsing endpoint can replace the custom normalization logic, or whether custom normalization is still needed for AI-generated recipe ingredients.

- **PowerSync + Drift version compatibility:** STACK.md flags that PowerSync uses Drift internally and version alignment must be verified. This must be confirmed at project setup, before Phase 1 schema work begins.

- **API key security model:** PITFALLS.md recommends proxying Spoonacular calls through Supabase Edge Functions. This adds latency to recipe search. The tradeoff (security vs. performance) should be explicitly decided during Phase 1/2 planning.

- **LWW conflict resolution is "acceptable" for meal plans but "NOT acceptable" for shopping list edits (PITFALLS.md):** The shopping list conflict strategy needs explicit design during Phase 3 planning — likely a merge strategy rather than LWW for checked-off items.

- **dart_openai vs. google_generative_ai cost decision:** STACK.md notes Gemini is a viable swap with a more generous free tier. This is a cost decision that should be made before Phase 4, not during it.

## Sources

### Primary (HIGH confidence)
- Flutter official app architecture guide — docs.flutter.dev/app-architecture/guide
- Supabase RLS official docs — supabase.com/docs/guides/database/postgres/row-level-security
- Drift official migration guide — drift.simonbinder.eu/guides/migrating_to_drift/
- Flutter offline-first design patterns — docs.flutter.dev/app-architecture/design-patterns/offline-first
- go_router (flutter.dev publisher) — pub.dev
- Supabase Flutter official blog — supabase.com/blog/offline-first-flutter-apps
- Riverpod official docs — riverpod.dev

### Secondary (MEDIUM confidence)
- Flutter Riverpod Architecture — Andrea Bizzotto, codewithandrea.com
- PowerSync Supabase integration — powersync.com/blog
- Building local-first Flutter apps with Riverpod, Drift, PowerSync — dinkomarinac.dev
- RLS misconfiguration incident data (170+ apps) — byteiota.com, prosperasoft.com (Jan 2025)
- Competitor analysis (Mealime, Paprika, Whisk, Plan to Eat, Ollie) — multiple sources
- Flutter project structure: feature-first — codewithandrea.com
- Spoonacular pricing — spoonacular.com/food-api/pricing

### Tertiary (LOW confidence)
- AI recipe generation hallucination patterns — DEV Community, Medium
- GDPR compliance for Flutter mobile apps — Hasan Karli, Medium; Didomi blog
- Flutter offline-first Part 1/2 — DEV Community (anurag_dev)
- Meal planning app feature comparisons — centenary.day, mealflow.ai (vendor blog), ollie.ai (vendor-biased)

---
*Research completed: 2026-03-02*
*Ready for roadmap: yes*
