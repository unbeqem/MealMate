---
phase: 05-weekly-meal-planner
plan: 01
subsystem: meal-planner-data-layer
tags: [drift, riverpod, repository, domain-models, freezed, stream]
dependency_graph:
  requires:
    - 03-ingredient-selection (appDatabaseProvider, Drift schema v3)
    - 02-authentication-onboarding (currentUserProvider, authNotifier)
  provides:
    - MealPlanRepository (watchWeek, assignRecipe, clearSlot, swapSlots, getFilledSlots)
    - TemplateRepository (saveCurrentWeek, loadTemplate, getAllTemplates, deleteTemplate)
    - MealPlanNotifier (family StreamNotifier keyed by weekStart)
    - TemplateNotifier (AsyncNotifier for template list)
    - currentUserIdProvider
    - MealSlot and PlanTemplate Freezed domain models
    - Drift schema v4 (MealPlanTemplates, MealPlanTemplateSlots tables)
  affects:
    - 05-02 (meal planner grid UI depends on MealPlanNotifier)
    - 05-03 (drag-and-drop depends on swapSlots)
    - 05-04 (templates UI depends on TemplateNotifier)
    - 05-05 (ingredient suggestions depends on getFilledSlots)
tech_stack:
  added:
    - MealPlanTemplates Drift table (UUID PK, userId, name, createdAt, updatedAt, syncStatus)
    - MealPlanTemplateSlots Drift table (UUID PK, templateId FK, dayOfWeek, mealType, recipeId, recipeTitle, recipeImage)
  patterns:
    - Spoonacular int IDs stored as text strings in recipeId columns ("716429") — avoids FK type migration
    - Left-outer-join with cachedRecipes using CustomExpression for text-to-int cast comparison
    - Family StreamNotifier (.build takes DateTime weekStart param, watches Drift reactively)
    - Template slots snapshot recipeTitle/recipeImage at save time — avoids stale joins on cache eviction
key_files:
  created:
    - meal_mate/lib/core/database/tables/meal_plan_templates_table.dart
    - meal_mate/lib/core/database/tables/meal_plan_template_slots_table.dart
    - meal_mate/lib/features/meal_planner/domain/meal_slot.dart
    - meal_mate/lib/features/meal_planner/domain/meal_slot.freezed.dart
    - meal_mate/lib/features/meal_planner/domain/plan_template.dart
    - meal_mate/lib/features/meal_planner/domain/plan_template.freezed.dart
    - meal_mate/lib/features/meal_planner/data/meal_plan_repository.dart
    - meal_mate/lib/features/meal_planner/data/template_repository.dart
    - meal_mate/lib/features/meal_planner/presentation/providers/meal_plan_notifier.dart
    - meal_mate/lib/features/meal_planner/presentation/providers/meal_plan_notifier.g.dart
    - meal_mate/lib/features/meal_planner/presentation/providers/template_notifier.dart
    - meal_mate/lib/features/meal_planner/presentation/providers/template_notifier.g.dart
  modified:
    - meal_mate/lib/core/database/app_database.dart (schemaVersion 3→4, two new tables)
    - meal_mate/lib/core/database/app_database.g.dart (hand-crafted table classes, data classes, companions, manager classes)
decisions:
  - "[Phase 05-01]: currentUserIdProvider wraps currentUserProvider — throws StateError if not authenticated, so all meal plan operations implicitly require sign-in"
  - "[Phase 05-01]: MealPlanNotifier uses ref.$arg to access the weekStart family parameter in mutation methods"
  - "[Phase 05-01]: Template slots snapshot recipeTitle/recipeImage at save time to avoid stale joins when CachedRecipes entries are evicted"
  - "[Phase 05-01]: weekStart normalised to UTC midnight before all DB queries to ensure consistent equality matching across timezones"
  - "[Phase 05-01]: TemplateRepository.getAllTemplates uses N+1 queries (one per template) — acceptable for expected template counts (<20); future optimisation if needed"
metrics:
  duration_minutes: 7
  completed_date: "2026-03-05"
  tasks_completed: 2
  files_created: 12
  files_modified: 2
---

# Phase 05 Plan 01: Meal Planner Data Layer Summary

**One-liner:** Drift schema v4 with MealPlanTemplates/MealPlanTemplateSlots tables, MealSlot/PlanTemplate Freezed domain models, MealPlanRepository with reactive Drift stream, TemplateRepository with transactional save/load, and family StreamNotifier + AsyncNotifier Riverpod providers.

## What Was Built

### Schema Extension (Drift v4)

Two new tables added via migration `if (from < 4)`:

- **MealPlanTemplates**: `id` (UUID v4), `userId`, `name`, `createdAt`, `updatedAt`, `syncStatus`
- **MealPlanTemplateSlots**: `id` (UUID v4), `templateId` (FK→MealPlanTemplates), `dayOfWeek`, `mealType`, `recipeId` (text, nullable), `recipeTitle` (text, nullable), `recipeImage` (text, nullable)

Hand-crafted `app_database.g.dart` additions following the exact existing pattern for `$XxxTable`, `XxxData`, `XxxCompanion`, filter/ordering/annotation composers, table managers, and `_$AppDatabase` table getters.

### Domain Models

`MealSlot` and `PlanTemplate` as `@freezed sealed class` with hand-crafted `.freezed.dart` files matching the `recipe_search_result.freezed.dart` structural pattern. No JSON serialisation (these are internal domain objects).

### Repositories

**MealPlanRepository:**
- `watchWeek(userId, weekStart)` — reactive Drift stream via left-outer-join with cachedRecipes (CustomExpression for text-to-int cast)
- `assignRecipe(...)` — find-or-create slot by (userId, weekStart, dayOfWeek, mealType), then insertOnConflictUpdate
- `clearSlot(slotId)` — updates recipeId to null
- `swapSlots(slotIdA, slotIdB)` — transactional read-both-write-both
- `getFilledSlots(userId, weekStart)` — non-stream, only non-null recipeId rows

**TemplateRepository:**
- `saveCurrentWeek(name, userId, weekStart)` — transaction: insert template header + one slot row per filled slot
- `loadTemplate(templateId, userId, targetWeekStart, replaceAll)` — optionally delete-all-first, then insertOnConflictUpdate for each template slot
- `getAllTemplates(userId)` — ordered by createdAt desc, N+1 query per template for slots
- `deleteTemplate(templateId)` — transaction: delete slots first (FK), then template

### Riverpod Providers

- **currentUserIdProvider** — simple `@riverpod` provider wrapping `currentUserProvider`; throws `StateError` if not signed in
- **MealPlanNotifier** — `@riverpod class` family StreamNotifier; `build(DateTime weekStart)` returns `watchWeek` stream; `ref.$arg` used in mutation methods to access the weekStart param
- **TemplateNotifier** — `@riverpod class` AsyncNotifier; `build()` calls `getAllTemplates`; mutations call `ref.invalidateSelf()` to refresh

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

All 12 created files verified on disk. Both task commits verified:
- `dd9d8a7` — feat(05-01): Drift schema v4 + MealSlot/PlanTemplate domain models
- `22f9d8a` — feat(05-01): MealPlanRepository, TemplateRepository, and stream notifiers
