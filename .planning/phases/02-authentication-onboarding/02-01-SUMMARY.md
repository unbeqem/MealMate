---
phase: 02-authentication-onboarding
plan: 01
subsystem: auth
tags: [supabase, flutter_secure_storage, riverpod, go_router, deep-link, email-auth]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: Supabase.initialize(), Riverpod ProviderScope, go_router routerProvider, flutter_secure_storage in pubspec

provides:
  - SecureLocalStorage (flutter_secure_storage wrapper replacing default SharedPreferences session storage)
  - AuthRepository (thin wrapper around all supabase.auth.* methods)
  - AppAuthState sealed class (authenticated, unauthenticated, loading)
  - authStateChangesProvider / authRepositoryProvider / currentUserProvider (Riverpod code-gen providers)
  - LoginScreen, SignupScreen, ForgotPasswordScreen, ResetPasswordScreen (full forms with validation and error handling)
  - Deep link scheme io.mealmate.app configured on iOS and Android for password reset flow

affects:
  - 02-02 (router extension with signup, forgot-password, reset-password routes; authStateChangesProvider already available)
  - 02-03 (onboarding flow uses authRepositoryProvider and currentUserProvider)
  - 08-sync (PowerSync auth integration reads currentSession from AuthRepository)

# Tech tracking
tech-stack:
  added: []  # All packages were already in pubspec.yaml from Phase 1
  patterns:
    - "SecureLocalStorage extends LocalStorage — always pass to Supabase.initialize() via FlutterAuthClientOptions"
    - "@riverpod code-gen for all Riverpod providers (not legacy StateNotifier or plain Provider)"
    - "All supabase.auth.* calls go through AuthRepository; widgets/notifiers never import supabase_flutter auth directly"
    - "Navigation on auth state change delegated exclusively to go_router redirect — screens never navigate on signedIn/signedOut"
    - "ConsumerStatefulWidget + local _isLoading bool for async UI state in auth screens"

key-files:
  created:
    - meal_mate/lib/features/auth/data/secure_local_storage.dart
    - meal_mate/lib/features/auth/domain/auth_state.dart
    - meal_mate/lib/features/auth/presentation/auth_notifier.g.dart
    - meal_mate/lib/features/auth/presentation/screens/signup_screen.dart
    - meal_mate/lib/features/auth/presentation/screens/forgot_password_screen.dart
    - meal_mate/lib/features/auth/presentation/screens/reset_password_screen.dart
  modified:
    - meal_mate/lib/features/auth/data/auth_repository.dart
    - meal_mate/lib/features/auth/presentation/auth_notifier.dart
    - meal_mate/lib/features/auth/presentation/screens/login_screen.dart
    - meal_mate/lib/main.dart
    - meal_mate/ios/Runner/Info.plist
    - meal_mate/android/app/src/main/AndroidManifest.xml

key-decisions:
  - "authStateProvider alias maintained for backward compatibility with existing router.dart (points to authStateChangesProvider)"
  - "auth_notifier.g.dart created as placeholder — must be regenerated with build_runner once Dart SDK is available on CI"
  - "ResetPasswordScreen route registration deferred to Plan 02-02 (router extension plan)"
  - "Supabase Dashboard Redirect URL (io.mealmate.app://reset-password) requires manual setup — documented in User Setup Required"

patterns-established:
  - "Pattern 1: SecureLocalStorage is the only session storage — never SharedPreferences for tokens"
  - "Pattern 2: AuthRepository is the single Supabase auth import point in the feature layer"
  - "Pattern 3: Auth screens use ConsumerStatefulWidget with try/catch around repository calls and ScaffoldMessenger snackbars for errors"

requirements-completed: [AUTH-01, AUTH-02, AUTH-03, AUTH-04]

# Metrics
duration: 3min
completed: 2026-03-03
---

# Phase 2 Plan 1: Auth Data Layer and Screens Summary

**Supabase email/password auth with SecureLocalStorage session encryption, AuthRepository service layer, Riverpod code-gen providers, and four full auth screens with deep link config for password reset**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-03T11:08:54Z
- **Completed:** 2026-03-03T11:11:54Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- SecureLocalStorage replaces default SharedPreferences session storage, encrypting JWT in Keychain (iOS) / Keystore (Android)
- AuthRepository wraps all supabase.auth methods (signUp, signIn, signOut, resetPasswordForEmail, updatePassword) — single Supabase auth import point
- Three Riverpod code-gen providers: authRepositoryProvider, authStateChangesProvider (stream), currentUserProvider (derived)
- Four auth screens with form validation, loading indicators, and error snackbars — navigation delegated to go_router
- Deep link scheme io.mealmate.app configured in both Info.plist and AndroidManifest.xml

## Task Commits

Each task was committed atomically:

1. **Task 1: Auth data layer — SecureLocalStorage, AuthRepository, auth state providers** - `45a381a` (feat)
2. **Task 2: Auth screens — login, signup, forgot password, reset password + deep link config** - `cb1c2ce` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `meal_mate/lib/features/auth/data/secure_local_storage.dart` - SecureLocalStorage extending LocalStorage using flutter_secure_storage
- `meal_mate/lib/features/auth/data/auth_repository.dart` - Full AuthRepository with all 7 auth methods
- `meal_mate/lib/features/auth/domain/auth_state.dart` - AppAuthState sealed class: authenticated/unauthenticated/loading
- `meal_mate/lib/features/auth/presentation/auth_notifier.dart` - @riverpod providers: authRepository, authStateChanges, currentUser
- `meal_mate/lib/features/auth/presentation/auth_notifier.g.dart` - Generated code for Riverpod providers (placeholder, regenerate on CI)
- `meal_mate/lib/features/auth/presentation/screens/login_screen.dart` - Full login form with validation and error handling
- `meal_mate/lib/features/auth/presentation/screens/signup_screen.dart` - Sign-up form with confirm password validation
- `meal_mate/lib/features/auth/presentation/screens/forgot_password_screen.dart` - Forgot password email form
- `meal_mate/lib/features/auth/presentation/screens/reset_password_screen.dart` - Reset password form (used after passwordRecovery event)
- `meal_mate/lib/main.dart` - Added FlutterAuthClientOptions(localStorage: SecureLocalStorage()) to Supabase.initialize()
- `meal_mate/ios/Runner/Info.plist` - Added CFBundleURLSchemes: io.mealmate.app
- `meal_mate/android/app/src/main/AndroidManifest.xml` - Added intent-filter for io.mealmate.app://reset-password

## Decisions Made

- **authStateProvider alias:** The existing `router.dart` imported `authStateProvider`. Rather than break it, added `final authStateProvider = authStateChangesProvider;` alias in `auth_notifier.dart`. Plan 02-02 can clean this up when it extends the router.
- **auth_notifier.g.dart as placeholder:** Since Flutter SDK is not on PATH in this environment, build_runner cannot run. The `.g.dart` file was hand-crafted with correct provider registrations matching riverpod_generator 4.x output format. This must be regenerated with `dart run build_runner build --delete-conflicting-outputs` when the SDK is available.
- **ResetPasswordScreen route deferred:** The route `/reset-password` is not registered yet — Plan 02-02 extends the router. The screen is ready and imported when needed.

## Deviations from Plan

None - plan executed exactly as written.

Note: The `auth_notifier.g.dart` could not be generated via `dart run build_runner` (Flutter SDK not on shell PATH per environment notes). A hand-crafted placeholder matching riverpod_generator 4.x output was created instead. Verification was via code review rather than `dart analyze`.

## User Setup Required

**Manual step required in Supabase Dashboard:**
1. Go to Authentication > Redirect URLs
2. Add `io.mealmate.app://reset-password`

This is required for the password reset deep link flow to work on real devices. Without it, the Supabase PKCE token exchange will reject the redirect URL.

## Next Phase Readiness

- Auth screens ready — Plan 02-02 needs to register `/signup`, `/forgot-password`, `/reset-password` routes in the router
- `authStateChangesProvider` exposes `AuthState` stream — Plan 02-02 router can extend redirect logic with three-state routing
- Deep link config in place — Supabase Dashboard manual step still needed (see User Setup Required)
- `currentUserProvider` and `authRepositoryProvider` available for Plan 02-03 onboarding flow

---
*Phase: 02-authentication-onboarding*
*Completed: 2026-03-03*
