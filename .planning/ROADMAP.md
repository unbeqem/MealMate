# Roadmap: MealMate

## Overview

MealMate delivers one core loop: select ingredients, discover or generate recipes, assign them to a 7-day meal planner, and get an auto-generated shopping list that works offline in a grocery store. The build order is strict — foundation before features, ingredients before recipes, recipes before meal planning, meal planning before shopping lists, features before sync. Each phase delivers a complete, independently verifiable capability. AI recipe generation and offline sync are isolated to their own phases to contain complexity. The app is done when the full loop runs end-to-end on a real device with no internet connection.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Flutter project scaffolding, Drift schema with UUID PKs, Supabase project with RLS, go_router with auth guard, Edge Functions scaffold
- [x] **Phase 2: Authentication & Onboarding** - Email/password auth via Supabase, session persistence, password reset, onboarding flow (completed 2026-03-03)
- [x] **Phase 3: Ingredient Selection** - Ingredient search via OpenFoodFacts, category browsing, favorites, dietary filters, "I have these" selector (UAT gap closure in progress) (completed 2026-03-04)
- [x] **Phase 4: Recipe Discovery** - Recipe browsing and search via Spoonacular, recipe detail view, serving size scaling, ingredient-based filtering (completed 2026-03-05)
- [x] **Phase 5: Weekly Meal Planner** - 7-day planner grid, recipe assignment, drag-and-drop rescheduling, plan templates, ingredient reuse suggestions (completed 2026-03-05)
- [ ] **Phase 6: Shopping List** - Auto-generated shopping list from meal plan, unit normalization pipeline, deduplication, manual editing, check-off
- [ ] **Phase 7: AI Recipe Generation** - GPT-4 recipe generation from selected ingredients, JSON schema enforcement, validation gate, SQLite caching
- [ ] **Phase 8: Offline & Sync** - PowerSync bidirectional Supabase-Drift sync, connectivity detection, offline indicators, background sync
- [ ] **Phase 9: Polish & GDPR Hardening** - End-to-end device testing, GDPR compliance, error states, empty states, done-criteria verification

## Phase Details

### Phase 1: Foundation
**Goal**: The project infrastructure exists so that every subsequent feature can be built correctly from day one — UUID PKs, RLS, offline-first architecture, and auth guards are all in place before any feature code is written.
**Depends on**: Nothing (first phase)
**Requirements**: *(infrastructure phase — no user-facing requirement IDs; satisfies all constraints: UUID PKs, RLS, GDPR, offline-first architecture, API key security)*
**Success Criteria** (what must be TRUE):
  1. Flutter project runs on iOS simulator and Android emulator with no errors
  2. Drift local database initializes with all domain tables (ingredients, recipes, meal_plan_slots, shopping_list_items) using UUID v4 primary keys
  3. Supabase project has RLS enabled on all user tables, verified with two separate test JWT tokens
  4. go_router redirects unauthenticated users to login screen and authenticated users past it
  5. Supabase Edge Functions scaffold exists and proxies a test call without exposing API keys in the Flutter bundle
**Plans:** 3/5 plans executed

Plans:
- [x] 01-01-PLAN.md — Flutter project setup: feature-first structure, all dependencies, CI workflow (Wave 1)
- [ ] 01-02-PLAN.md — Drift schema: 4 domain tables with UUID PKs, sync metadata, AppDatabase, code gen (Wave 2)
- [ ] 01-03-PLAN.md — Supabase project: PostgreSQL schema mirroring Drift, RLS policies, GDPR deletion scaffold (Wave 3)
- [ ] 01-04-PLAN.md — go_router + auth guard: auth state provider, redirect logic, placeholder screens (Wave 2)
- [ ] 01-05-PLAN.md — Edge Functions: Spoonacular and OpenAI API key proxies, Flutter EdgeFunctionClient (Wave 4)

### Phase 2: Authentication & Onboarding
**Goal**: Users can create accounts, stay logged in across sessions, recover forgotten passwords, and complete an onboarding flow that captures their household and dietary context — before any feature of the app is accessible.
**Depends on**: Phase 1
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05
**Success Criteria** (what must be TRUE):
  1. User can sign up with email and password and is taken to onboarding on first login
  2. User can close and reopen the app and remain logged in without re-entering credentials
  3. User can log out from any screen and is returned to the login screen
  4. User who forgot password receives a reset email and can set a new password
  5. New user completes a 2-3 screen onboarding flow that captures household size and dietary preferences, and this data is persisted to Supabase
**Plans**: 2 plans

Plans:
- [ ] 02-01-PLAN.md — Auth data layer (SecureLocalStorage, AuthRepository, auth state provider) + auth screens (login, signup, forgot password, reset password) + deep link config
- [ ] 02-02-PLAN.md — Onboarding flow (household size, dietary preferences, Supabase profile upsert) + three-state go_router redirect (auth + onboarding routing)

### Phase 3: Ingredient Selection
**Goal**: Users can find any ingredient they want to cook with — by searching, browsing categories, or filtering by dietary restriction — and build a personal favorites list for quick reuse.
**Depends on**: Phase 2
**Requirements**: INGR-01, INGR-02, INGR-03, INGR-04, INGR-05
**Success Criteria** (what must be TRUE):
  1. User can type in a search box and see ingredient autocomplete results from OpenFoodFacts within 500ms
  2. User can browse ingredients organized by category (produce, dairy, meat, grains, etc.) without searching
  3. User can mark any ingredient as a favorite and find it in a dedicated favorites list on relaunch
  4. User can filter the ingredient list to show only items matching their dietary restrictions (vegetarian, vegan, gluten-free, dairy-free)
  5. User can select ingredients from their favorites or search results to indicate "I have these today" for recipe discovery
**Plans**: 5 plans

Plans:
- [x] 03-01-PLAN.md — Ingredient data layer: domain models, OFf SDK integration, Drift schema extension (v2), IngredientRepository with pull-through cache
- [x] 03-02-PLAN.md — Ingredient selection UI: debounced autocomplete search, category browser, dietary filter chips, Riverpod 3 providers, route registration
- [x] 03-03-PLAN.md — Favorites and "I have these": favorite toggle with optimistic write, selected-today keepAlive provider backed by Drift, favorites screen, selected-today bar
- [ ] 03-04-PLAN.md — Gap closure: fix category double-translation bug, toggleFavorite upsert for non-Drift ingredients, pull-to-refresh on category screen (Wave 1)
- [ ] 03-05-PLAN.md — Gap closure: fix search speed (local-first before debounce), wire dietary filters to search results, dietary badges on tiles (Wave 2)

### Phase 4: Recipe Discovery
**Goal**: Users can browse a large library of real recipes filtered by the ingredients they have, view complete recipe details, and adjust serving sizes — giving them enough information to decide what to cook before touching the meal planner.
**Depends on**: Phase 3
**Requirements**: RECP-01, RECP-02, RECP-03, RECP-04
**Success Criteria** (what must be TRUE):
  1. User can search recipes by name, ingredient, cuisine, and cook time and see results from Spoonacular
  2. User can open a recipe and see the full ingredient list, step-by-step instructions, cook time, and serving count
  3. User can change the serving size on a recipe detail screen and see all ingredient quantities update proportionally
  4. User can tap "Find recipes using my ingredients" and see only recipes that use ingredients from their selected list
  5. Previously fetched recipes are available to view offline (cached to Drift on first load)
**Plans:** 3/3 plans complete

Plans:
- [ ] 04-01-PLAN.md — Spoonacular data layer: Freezed models, Edge Function proxy, Drift cache, RecipeRepository (Wave 1)
- [ ] 04-02-PLAN.md — Recipe browse screen: search, filter chips, pagination, ingredient-based discovery (Wave 2)
- [ ] 04-03-PLAN.md — Recipe detail screen: ingredients, instructions, serving scaler, route wiring (Wave 2)

### Phase 5: Weekly Meal Planner
**Goal**: Users can build a complete week of meals by assigning recipes to breakfast, lunch, and dinner slots, reorder meals freely, save their best weeks as templates, and receive suggestions that minimize leftover ingredients.
**Depends on**: Phase 4
**Requirements**: PLAN-01, PLAN-02, PLAN-03, PLAN-04, PLAN-05, PLAN-06, PLAN-07
**Success Criteria** (what must be TRUE):
  1. User can see a 7-column, 3-row grid (days x meal slots) and tap any empty slot to assign a recipe from the recipe library
  2. User can replace or remove a recipe from any filled slot without leaving the planner screen
  3. User can drag a meal card from one slot to another slot and the change persists on reload
  4. User can save the current week's plan as a named template and later load that template into any future week
  5. When browsing recipes to fill a slot, the planner highlights recipes that reuse ingredients already in the current week's plan
**Plans:** 6/6 plans complete

Plans:
- [ ] 05-01-PLAN.md — Meal plan data layer: Drift schema extension (weekStart column), MealSlot/WeekPlan domain models, MealPlanRepository CRUD, Riverpod stream notifier (Wave 1)
- [ ] 05-02-PLAN.md — Planner grid UI: 7-day x 3-slot grid, week navigation, tap-to-assign recipe picker, slot card with edit/replace/remove (Wave 2)
- [ ] 05-03-PLAN.md — Drag-and-drop rescheduling: LongPressDraggable + DragTarget, scroll conflict mitigation, atomic swap persistence (Wave 3)
- [ ] 05-04-PLAN.md — Templates: MealPlanTemplates + MealPlanTemplateSlots tables, TemplateRepository save/load, TemplateListScreen (Wave 2)
- [ ] 05-05-PLAN.md — Ingredient reuse suggestions: weekIngredientNames provider, overlap computation via Set.intersection, badge in recipe picker (Wave 3)
- [ ] 05-06-PLAN.md — Gap closure: wire ingredient overlap badge with cached recipe data in selectForSlot mode (Wave 1)

### Phase 6: Shopping List
**Goal**: The meal plan automatically produces a single, clean shopping list that a user can walk into a store with — no duplicates, sensible units, and the ability to check off items and make manual adjustments.
**Depends on**: Phase 5
**Requirements**: SHOP-01, SHOP-02, SHOP-03, SHOP-04, SHOP-05, SHOP-06, SHOP-07
**Success Criteria** (what must be TRUE):
  1. When a user opens the shopping list, it contains every ingredient from every recipe in the current meal plan with no manual steps required
  2. The same ingredient appearing in multiple recipes appears as a single line item with quantities summed (e.g., two recipes using flour show one "flour" entry)
  3. Ingredients measured in different but compatible units are normalized and summed correctly (e.g., "500g + 0.5kg flour" shows as "1kg flour")
  4. User can add a free-text item to the shopping list that is not derived from any recipe
  5. User can remove any item, adjust its quantity, and check it off as purchased — and all changes persist across app restarts
**Plans:** 3 plans

Plans:
- [ ] 06-01-PLAN.md — Unit normalization pipeline: 5-stage TDD service (lexical, unit family, intra-family conversion, cross-family conflict, display formatting), exhaustive unit tests (Wave 1)
- [ ] 06-02-PLAN.md — Shopping list data layer: Drift migration (isManual column), ShoppingListDao, ShoppingListRepository with meal-plan aggregation and deduplication (Wave 2)
- [ ] 06-03-PLAN.md — Shopping list UI: reactive ListView with check-off, quantity editor, manual add bottom sheet, remove, route registration, human verification (Wave 3)

### Phase 7: AI Recipe Generation
**Goal**: When Spoonacular returns no usable recipes for a user's ingredient selection, an AI-generated recipe appears seamlessly — validated, coherent, and indistinguishable in quality from an API recipe.
**Depends on**: Phase 4
**Requirements**: RECP-05, RECP-06
**Success Criteria** (what must be TRUE):
  1. When a user selects ingredients and Spoonacular returns zero matches, an AI-generated recipe appears automatically without any extra user action
  2. The AI-generated recipe contains only ingredients from the user's selected list, with plausible quantities and standard units
  3. AI-generated recipes are cached to local SQLite and available offline after first generation
  4. No AI recipe with nonsensical quantities (e.g., "1/8 egg", "3kg salt") reaches the shopping list — the validation gate catches and discards or corrects them
**Plans**: TBD

Plans:
- [ ] 07-01: LLM client — dart_openai integration via Edge Function proxy, JSON schema prompt for recipe output, structured response parsing to Recipe model
- [ ] 07-02: AI validation gate — ingredient whitelist check, quantity sanity bounds, unit validity check, fallback behavior on validation failure
- [ ] 07-03: AI integration in recipe discovery flow — trigger condition (zero Spoonacular results), streaming loading UI, cache to Drift with source='ai_generated'

### Phase 8: Offline & Sync
**Goal**: The app's full core loop — meal plan, shopping list, and previously browsed recipes — is available with no internet connection, and any changes made offline sync automatically and silently when connectivity returns.
**Depends on**: Phase 6, Phase 7
**Requirements**: SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-05
**Success Criteria** (what must be TRUE):
  1. User can open the app in airplane mode and see their current meal plan and shopping list with full functionality
  2. User can check off shopping list items while offline and those check-offs are still checked when connectivity returns and sync completes
  3. Recipes the user has previously viewed are accessible offline from the local cache
  4. Changes made on device A while offline appear on device B within 30 seconds of device A reconnecting to the internet
  5. The app shows a visible indicator when it is operating in offline mode, and removes it when sync completes
**Plans**: TBD

Plans:
- [ ] 08-01: PowerSync integration — PowerSync 1.17.0 + Drift version alignment, sync schema definition, bidirectional sync configuration for all user tables
- [ ] 08-02: Connectivity and offline UI — connectivity_plus listener, offline mode banner, sync pending badge, optimistic local writes
- [ ] 08-03: Background sync — WorkManager job for background sync when app is backgrounded, LWW conflict resolution for meal plan, merge strategy for shopping list check-offs
- [ ] 08-04: Cross-device sync validation — test SYNC-04 and SYNC-05 with two real accounts on two devices, verify no data loss on conflict

### Phase 9: Polish & GDPR Hardening
**Goal**: The app meets its done criteria — a working end-to-end core loop on a real device, with no crashes on common edge cases, proper GDPR compliance, and every empty state handled gracefully.
**Depends on**: Phase 8
**Requirements**: *(quality gate — no new requirement IDs; satisfies done criteria: working end-to-end on real device/emulator, GDPR compliance constraint)*
**Success Criteria** (what must be TRUE):
  1. Full core loop (sign up → select ingredients → browse/generate recipe → assign to planner → view shopping list → check off items) completes without error on a real iOS device or Android device
  2. User can request deletion of their account and all associated data is purged from Supabase within 30 days (GDPR Article 17)
  3. Every screen that can be empty (no ingredients selected, empty planner, empty shopping list) shows a helpful empty state rather than a blank screen
  4. App does not crash when switching between offline and online mid-session, or when API calls fail
**Plans**: TBD

Plans:
- [ ] 09-01: End-to-end device testing — full core loop walkthrough on iOS and Android, crash log review, performance profiling
- [ ] 09-02: GDPR compliance — account deletion flow, data export, privacy policy screen, consent handling for AI processing
- [ ] 09-03: Empty states and error handling — empty state widgets for all major screens, API error banners, retry logic, graceful degradation

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 3/5 | In Progress|  |
| 2. Authentication & Onboarding | 2/2 | Complete   | 2026-03-03 |
| 3. Ingredient Selection | 5/5 | Complete   | 2026-03-04 |
| 4. Recipe Discovery | 3/3 | Complete   | 2026-03-05 |
| 5. Weekly Meal Planner | 6/6 | Complete   | 2026-03-05 |
| 6. Shopping List | 0/3 | Not started | - |
| 7. AI Recipe Generation | 0/3 | Not started | - |
| 8. Offline & Sync | 0/4 | Not started | - |
| 9. Polish & GDPR Hardening | 0/3 | Not started | - |
