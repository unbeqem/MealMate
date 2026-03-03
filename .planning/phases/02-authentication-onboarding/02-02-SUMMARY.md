---
phase: 02-authentication-onboarding
plan: 02
subsystem: auth-onboarding
tags: [onboarding, riverpod, go_router, supabase, freezed, shared_preferences]

# Dependency graph
requires:
  - phase: 02-01
    provides: authStateChangesProvider, authRepositoryProvider, currentUserProvider, four auth screens

provides:
  - OnboardingData Freezed model (householdSize, dietaryPreferences)
  - OnboardingNotifier (Riverpod code-gen) with Supabase profile upsert and SharedPreferences flag
  - onboardingCompletedProvider (async Future<bool> reading local flag)
  - OnboardingShell PageView container (2-page onboarding flow)
  - HouseholdSizePage (screen 1 — increment/decrement 1-10)
  - DietaryPreferencesPage (screen 2 — FilterChip grid with Done button)
  - Three-state go_router redirect (unauthed -> /login, authed+no-onboard -> /onboarding, authed+onboarded -> /home)
  - RouterRefreshNotifier bridging Riverpod providers to go_router refreshListenable
  - All six routes registered: /login, /signup, /forgot-password, /reset-password, /onboarding, /home
  - Supabase profiles table migration SQL with RLS, text[] dietary_preferences column, auto-create trigger
  - initialSession Supabase sync for onboarding flag (handles reinstall scenario)

affects:
  - 02-03 (if it exists — onboarding complete, home screen reachable)
  - 08-sync (PowerSync can now rely on profiles table existing with onboarding_completed flag)

# Tech tracking
tech-stack:
  added:
    - shared_preferences: ^2.3.0 (local persistence of onboarding_completed flag)
    - freezed_annotation: ^2.4.0 (OnboardingData model)
    - freezed: ^2.5.0 (dev — code generation for OnboardingData)
  patterns:
    - "OnboardingNotifier uses Riverpod code-gen (@riverpod annotation); extends _$OnboardingNotifier"
    - "onboardingCompletedProvider is AsyncFutureProvider — router awaits it before making routing decisions"
    - "RouterRefreshNotifier bridges both authStateChangesProvider AND onboardingCompletedProvider — router re-evaluates on any state change in either"
    - "Three-state redirect: isLoading -> null, !authed -> /login (unless on auth route), authed+!onboarded -> /onboarding, authed+onboarded -> /home (blocks pre-home routes)"
    - "initialSession event triggers Supabase profile fetch to restore onboarding flag after reinstall"
    - "completeOnboarding() always upserts Supabase first, then writes SharedPreferences — local flag is secondary source of truth"

key-files:
  created:
    - meal_mate/lib/features/auth/domain/onboarding_data.dart
    - meal_mate/lib/features/auth/domain/onboarding_data.freezed.dart
    - meal_mate/lib/features/auth/presentation/onboarding_notifier.dart
    - meal_mate/lib/features/auth/presentation/onboarding_notifier.g.dart
    - meal_mate/lib/features/auth/presentation/screens/onboarding/onboarding_shell.dart
    - meal_mate/lib/features/auth/presentation/screens/onboarding/household_size_page.dart
    - meal_mate/lib/features/auth/presentation/screens/onboarding/dietary_preferences_page.dart
    - supabase/migrations/create_profiles_table.sql
  modified:
    - meal_mate/lib/app/router.dart
    - meal_mate/pubspec.yaml

key-decisions:
  - "onboarding_data.freezed.dart and onboarding_notifier.g.dart hand-crafted (build_runner unavailable); must regenerate on CI with dart run build_runner build --delete-conflicting-outputs"
  - "onboardingCompletedProvider is AutoDisposeFutureProvider<bool> — router guards on isLoading to avoid flash-of-wrong-route"
  - "RouterRefreshNotifier holds strong reference via Provider.internal — not autoDisposed, lives as long as the router"
  - "initialSession sync is fire-and-forget — failures are silently swallowed; local SharedPreferences flag is fallback"
  - "PopScope(canPop: false) on OnboardingShell prevents back navigation to auth screens during onboarding"

patterns-established:
  - "Pattern 4: Three-state routing — all auth/onboarding routing decisions live exclusively in router.dart redirect; screens never navigate"
  - "Pattern 5: RouterRefreshNotifier must listen to ALL providers that affect routing — auth AND onboarding"

requirements-completed: [AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05]

# Metrics
duration: 3min
completed: 2026-03-03
---

# Phase 2 Plan 2: Onboarding Flow and Three-State Router Summary

**Onboarding PageView flow (household size + dietary preferences) with Supabase profile upsert, and go_router three-state redirect enforcing login -> onboarding -> home user journey**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-03T11:15:28Z
- **Completed:** 2026-03-03T11:18:00Z
- **Tasks:** 2 auto + 1 human-verify checkpoint
- **Files modified:** 10

## Accomplishments

- OnboardingData Freezed model accumulates household size (1-10) and dietary preferences (list of strings) across onboarding pages
- OnboardingNotifier (Riverpod code-gen) manages state, upserts profile to Supabase `profiles` table, and writes `onboarding_completed` SharedPreferences flag on completion
- onboardingCompletedProvider reads local flag — async Future<bool> used by router for redirect decisions
- OnboardingShell hosts 2-page PageView with page indicator dots and PopScope preventing back navigation to auth screens
- HouseholdSizePage uses increment/decrement buttons (range 1-10) with prominent current value display
- DietaryPreferencesPage uses FilterChip grid with 7 dietary options, CircularProgressIndicator shown while submitting
- Supabase profiles table migration SQL with RLS, `text[]` dietary_preferences column, `on_auth_user_created` auto-create trigger preventing race condition
- RouterRefreshNotifier bridges both `authStateChangesProvider` and `onboardingCompletedProvider` to go_router's refreshListenable
- Three-state redirect: unauthenticated → /login, authenticated+not-onboarded → /onboarding, authenticated+onboarded → /home
- All six routes registered: /login, /signup, /forgot-password, /reset-password, /onboarding, /home
- passwordRecovery AuthChangeEvent handled in redirect — routes to /reset-password for deep link flow
- initialSession handler syncs onboarding flag from Supabase on app restart (handles reinstall scenario)
- Added `shared_preferences` and `freezed_annotation` to pubspec.yaml (were missing — required for new files)

## Task Commits

Each task was committed atomically:

1. **Task 1: Onboarding data model, notifier, screens, and profiles migration** - `294ae87` (feat)
2. **Task 2: Three-state go_router redirect with RouterRefreshNotifier** - `815b865` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `meal_mate/lib/features/auth/domain/onboarding_data.dart` - Freezed model with householdSize and dietaryPreferences
- `meal_mate/lib/features/auth/domain/onboarding_data.freezed.dart` - Hand-crafted Freezed generated code (regenerate with build_runner on CI)
- `meal_mate/lib/features/auth/presentation/onboarding_notifier.dart` - OnboardingNotifier + onboardingCompletedProvider
- `meal_mate/lib/features/auth/presentation/onboarding_notifier.g.dart` - Hand-crafted Riverpod generated code (regenerate with build_runner on CI)
- `meal_mate/lib/features/auth/presentation/screens/onboarding/onboarding_shell.dart` - PageView container with page indicators and PopScope
- `meal_mate/lib/features/auth/presentation/screens/onboarding/household_size_page.dart` - Household size selector (1-10)
- `meal_mate/lib/features/auth/presentation/screens/onboarding/dietary_preferences_page.dart` - FilterChip dietary preferences grid
- `supabase/migrations/create_profiles_table.sql` - Profiles table with RLS, text[] column, auto-create trigger
- `meal_mate/lib/app/router.dart` - Full three-state router with RouterRefreshNotifier, all 6 routes, passwordRecovery handling
- `meal_mate/pubspec.yaml` - Added shared_preferences ^2.3.0, freezed_annotation ^2.4.0, freezed ^2.5.0

## Decisions Made

- **Hand-crafted generated files:** `onboarding_data.freezed.dart` and `onboarding_notifier.g.dart` were hand-crafted as build_runner cannot run (Flutter SDK not on shell PATH). Must regenerate with `dart run build_runner build --delete-conflicting-outputs` when SDK is available.
- **onboardingCompletedProvider as AsyncFutureProvider:** SharedPreferences.getInstance() is async, so the provider returns `Future<bool>`. Router guards on `isLoading` state to prevent flash-of-wrong-route while the async value resolves.
- **initialSession sync strategy:** Fire-and-forget Supabase fetch in the router's auth state listener. Failure is silently swallowed — local SharedPreferences remains source of truth for the current session. The sync ensures reinstall users don't re-do onboarding.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical dependency] Added shared_preferences and freezed packages to pubspec.yaml**
- **Found during:** Task 1
- **Issue:** pubspec.yaml was missing `shared_preferences` (needed by onboarding_notifier.dart for local flag) and `freezed_annotation`/`freezed` (needed by onboarding_data.dart Freezed model)
- **Fix:** Added `shared_preferences: ^2.3.0` and `freezed_annotation: ^2.4.0` to dependencies; `freezed: ^2.5.0` to dev_dependencies
- **Files modified:** meal_mate/pubspec.yaml
- **Commit:** 294ae87

## User Setup Required

**Manual steps required in Supabase Dashboard (blocking for end-to-end testing):**
1. Run the SQL from `supabase/migrations/create_profiles_table.sql` in your Supabase SQL editor
2. Add `io.mealmate.app://reset-password` to Authentication > Redirect URLs
3. Disable email confirmation: Authentication > Providers > Email > toggle off "Confirm email" (re-enable before Phase 9)

## Next Phase Readiness

- Full auth + onboarding routing complete — home screen is reachable after onboarding
- Profiles table migration SQL ready for manual execution in Supabase Dashboard
- onboardingCompletedProvider and onboardingNotifierProvider available for any feature needing onboarding state
- Router enforces all three states — no further routing work needed until new authenticated routes are added

---
*Phase: 02-authentication-onboarding*
*Completed: 2026-03-03*

## Self-Check: PASSED

All created files verified present on disk. Both task commits (294ae87, 815b865) verified in git log.
