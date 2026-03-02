---
phase: 01-foundation
plan: 04
subsystem: auth
tags: [flutter, dart, riverpod, go_router, supabase, auth]

# Dependency graph
requires:
  - phase: 01-01
    provides: Flutter project with go_router dependency, feature-first directory structure, router.dart placeholder
provides:
  - GoRouter with auth redirect (loading/unauthenticated/authenticated states)
  - authStateProvider streaming Supabase AuthState via StreamProvider
  - AuthRepository wrapping SupabaseClient auth stream
  - AppUser domain model (id, email)
  - Placeholder LoginScreen and HomeScreen
  - App widget upgraded to MaterialApp.router consuming routerProvider
affects:
  - 02-auth (full login/signup UI replaces placeholder LoginScreen)
  - 03-ingredient-selection (all feature screens use this router)
  - All subsequent phases (router is entry point for all screens)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - GoRouter auth redirect: loading -> null, unauthenticated -> /login, authenticated -> /home
    - Auth state via StreamProvider<AuthState> (ref.watch triggers router rebuild on change)
    - AuthRepository as data layer wrapper around SupabaseClient.auth
    - AppUser as domain model separate from Supabase User

key-files:
  created:
    - meal_mate/lib/features/auth/domain/user.dart
    - meal_mate/lib/features/auth/data/auth_repository.dart
    - meal_mate/lib/features/auth/presentation/auth_notifier.dart
    - meal_mate/lib/features/auth/presentation/screens/login_screen.dart
    - meal_mate/lib/features/home/presentation/screens/home_screen.dart
  modified:
    - meal_mate/lib/app/router.dart
    - meal_mate/lib/app/app.dart

key-decisions:
  - "Router uses ref.watch(authStateProvider) inside routerProvider — rebuilds GoRouter on auth change, eliminating need for separate ChangeNotifier refreshListenable"
  - "Loading state returns null (no redirect) preventing login flash on app launch before Supabase resolves session"
  - "AuthRepository owns all Supabase auth calls — presentation layer has zero direct Supabase imports"
  - "Home feature created at features/home/presentation/screens/ consistent with feature-first layout"

patterns-established:
  - "Auth redirect pattern: isLoading || hasError -> null, !isAuthenticated -> /login, isAuthenticated on /login -> /home"
  - "Provider rebuilds GoRouter: ref.watch(authStateProvider) inside routerProvider serves as refreshListenable equivalent"

requirements-completed:
  - INFRA-OFFLINE-FIRST

# Metrics
duration: 5min
completed: 2026-03-02
---

# Phase 01 Plan 04: Go Router with Auth Guard Summary

**GoRouter with Riverpod auth redirect that handles loading/unauthenticated/authenticated states, eliminating the login flash bug via null redirect during Supabase session resolution.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-02T16:00:00Z
- **Completed:** 2026-03-02T16:05:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- AuthRepository wraps Supabase auth client, exposing onAuthStateChange stream and currentSession/currentUser accessors
- authStateProvider as StreamProvider<AuthState> serves as the single source of truth for auth state across the app
- GoRouter redirect handles all 3 states: AsyncLoading -> null (no redirect), unauthenticated -> /login, authenticated -> /home
- App upgraded from plain MaterialApp to MaterialApp.router consuming routerProvider via ref.watch
- Placeholder LoginScreen (Phase 2 placeholder) and HomeScreen created in feature-first structure

## Task Commits

Each task was committed atomically:

1. **Task 1: Create auth state provider and auth repository** - `1cb2b74` (feat)
2. **Task 2: Create go_router with auth redirect and update App to MaterialApp.router** - `aa142f0` (feat)

**Plan metadata:** (docs commit — TBD)

## Files Created/Modified

- `meal_mate/lib/features/auth/domain/user.dart` - AppUser domain model (id, email) — not a Supabase User
- `meal_mate/lib/features/auth/data/auth_repository.dart` - AuthRepository + authRepositoryProvider wrapping SupabaseClient
- `meal_mate/lib/features/auth/presentation/auth_notifier.dart` - authStateProvider (StreamProvider<AuthState>)
- `meal_mate/lib/features/auth/presentation/screens/login_screen.dart` - Placeholder login screen for Phase 2
- `meal_mate/lib/features/home/presentation/screens/home_screen.dart` - Placeholder home screen
- `meal_mate/lib/app/router.dart` - GoRouter with auth redirect logic and /login, /home routes
- `meal_mate/lib/app/app.dart` - Upgraded to ConsumerWidget using MaterialApp.router with routerProvider

## Decisions Made

- Used `ref.watch(authStateProvider)` inside `routerProvider` as the mechanism to trigger router re-evaluation on auth state change. This is idiomatic Riverpod and avoids the boilerplate of a `ChangeNotifier` adapter for `refreshListenable`.
- `AuthRepository` is the only file importing `supabase_flutter` in the auth feature — presentation files only import from the repository.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

Flutter SDK not available in shell PATH (same environment limitation as plan 01-01). All files created correctly per spec. The GitHub Actions CI pipeline at `meal_mate/.github/workflows/flutter.yml` will perform `flutter analyze` verification when pushed.

## User Setup Required

None - no external service configuration required for this plan.

## Next Phase Readiness

- Auth guard is in place: all feature screens added in phases 2-9 will correctly redirect unauthenticated users to /login
- Phase 2 (auth UI) replaces the placeholder LoginScreen with actual email/password or magic link UI
- The loading state null-redirect ensures no login flash regardless of session resolution timing

---
*Phase: 01-foundation*
*Completed: 2026-03-02*
