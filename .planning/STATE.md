---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: unknown
stopped_at: Completed 03-01-PLAN.md — ingredient data layer
last_updated: "2026-03-04T09:13:58.274Z"
last_activity: "2026-03-03 — Completed 02-01: Supabase email/password auth with SecureLocalStorage, AuthRepository, four auth screens, and deep link config"
progress:
  total_phases: 9
  completed_phases: 1
  total_plans: 21
  completed_plans: 7
---

---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: unknown
last_updated: "2026-03-03T11:19:49.539Z"
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 21
  completed_plans: 7
---

---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: in-progress
last_updated: "2026-03-03T11:13:47Z"
progress:
  total_phases: 6
  completed_phases: 0
  total_plans: 13
  completed_plans: 4
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-02)

**Core value:** Users can go from selecting ingredients to a complete weekly meal plan with an accurate shopping list in minutes — reducing food waste and unnecessary spending.
**Current focus:** Phase 2 — Authentication & Onboarding

## Current Position

Phase: 2 of 6 (Authentication & Onboarding)
Plan: 1 of 2 in current phase (02-01 complete)
Status: In progress
Last activity: 2026-03-03 — Completed 02-01: Supabase email/password auth with SecureLocalStorage, AuthRepository, four auth screens, and deep link config

Progress: [███░░░░░░░] 12%

## Performance Metrics

**Velocity:**
- Total plans completed: 4
- Average duration: 4 min
- Total execution time: 0.2 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 3/5 | 14 min | 5 min |
| 02-authentication-onboarding | 1/2 | 3 min | 3 min |

**Recent Trend:**
- Last 5 plans: 01-01 (7 min), 01-04 (5 min), 01-02 (2 min), 02-01 (3 min)
- Trend: Stable

*Updated after each plan completion*

| Phase-Plan | Duration | Tasks | Files |
|------------|----------|-------|-------|
| 01-foundation P01 | 7 min | 2 tasks | 12 files |
| 01-foundation P04 | 5 min | 2 tasks | 7 files |
| 01-foundation P02 | 2 min | 2 tasks | 7 files |
| 02-authentication-onboarding P01 | 3 min | 2 tasks | 12 files |
| Phase 02 P02 | 3 | 2 tasks | 10 files |
| Phase 03-ingredient-selection P01 | 15 | 2 tasks | 12 files |
| Phase 03-ingredient-selection P02 | 5 | 2 tasks | 8 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Stack: Flutter 3.41 + Riverpod 3.x + Drift + PowerSync + Supabase (confirmed by research)
- Recipe API: Spoonacular ($29/mo Cook plan) — native meal planning endpoints, ingredient parsing
- Ingredient API: OpenFoodFacts (free) — autocomplete
- AI: dart_openai (GPT-4) — AI recipe generation; Gemini is cost-driven swap option
- Offline: Drift as primary source of truth; Supabase is sync target only, never direct read source
- API key security: Proxy Spoonacular and OpenAI calls through Supabase Edge Functions
- Flutter project structure: Lives in meal_mate/ subdirectory; feature-first layout (app/, core/, features/)
- Supabase keys: Injected via String.fromEnvironment — never hardcoded in source
- app.dart: Upgraded to MaterialApp.router in plan 01-04; uses ConsumerWidget + routerProvider
- GoRouter auth redirect: loading -> null (no flash), unauthenticated -> /login, authenticated -> /home
- AuthRepository is sole Supabase auth import point in feature layer; presentation uses authStateProvider only
- routerProvider uses ref.watch(authStateProvider) — Riverpod rebuild serves as refreshListenable equivalent
- Drift schema: UUID v4 text PKs on all 4 domain tables (never integer autoIncrement) — offline-first sync safety
- Drift schema: syncStatus defaults to 'pending'; updatedAt uses currentDateAndTime — PowerSync reads these columns
- AppDatabase optional QueryExecutor constructor — Phase 8 injects SqliteAsyncDriftConnection without changing this file
- [Phase 02-01]: authStateProvider alias maintained for backward compat with router.dart; points to authStateChangesProvider
- [Phase 02-01]: auth_notifier.g.dart hand-crafted (build_runner unavailable); must regenerate on CI with dart run build_runner build
- [Phase 02-01]: Supabase Dashboard Redirect URL io.mealmate.app://reset-password requires manual setup
- [Phase 02-02]: onboarding_data.freezed.dart and onboarding_notifier.g.dart hand-crafted (build_runner unavailable); must regenerate on CI
- [Phase 02-02]: onboardingCompletedProvider is AsyncFutureProvider<bool>; router guards on isLoading to prevent flash-of-wrong-route
- [Phase 03-ingredient-selection]: selectedToday has NO date filter — getSelectedToday and clearSelectedToday operate on all rows for userId (persist until manual clear)
- [Phase 03-ingredient-selection]: ingredientCategories has exactly 12 entries including Baking and Nuts & Seeds per locked decision
- [Phase 03-ingredient-selection]: appDatabaseProvider uses keepAlive: true — db connection survives navigation across all Phase 3 screens
- [Phase 03-ingredient-selection]: IngredientSearchScreen and IngredientFavoritesScreen are tab children with no own Scaffold — IngredientMainScreen provides the single Scaffold
- [Phase 03-ingredient-selection]: Local-first search fast path: >= 5 local matches in commonIngredients skips OFf API entirely
- [Phase 03-ingredient-selection]: /ingredients/favorites removed as standalone route — Favorites is now Tab 1 of IngredientMainScreen

### Pending Todos

- Supabase Dashboard: Add io.mealmate.app://reset-password to Authentication > Redirect URLs (required for password reset deep link)

### Blockers/Concerns

- [Pre-Phase 1] Verify PowerSync 1.17.0 + Drift version compatibility before schema work begins
- [Pre-Phase 1] Decide dart_openai vs. google_generative_ai before Phase 7 (cost decision)
- [Phase 3] Evaluate whether Spoonacular ingredient parsing API can replace custom normalization for API recipes, or if custom pipeline is still needed for AI-generated recipes
- [Phase 8] Shopping list sync conflict strategy must be merge (not LWW) for check-off state

## Session Continuity

Last session: 2026-03-04T09:12:32Z
Stopped at: Completed 03-02-PLAN.md — ingredient UI layer
Resume file: None
