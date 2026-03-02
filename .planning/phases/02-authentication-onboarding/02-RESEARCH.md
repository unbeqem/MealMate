# Phase 2: Authentication & Onboarding - Research

**Researched:** 2026-03-02
**Domain:** Flutter email/password auth via supabase_flutter 2.x, session persistence, password reset deep links, onboarding flow with Riverpod state and Supabase profile upsert
**Confidence:** HIGH (core auth API and session persistence), MEDIUM (deep link password reset, onboarding routing pattern)

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AUTH-01 | User can sign up with email and password | `supabase.auth.signUp()` API confirmed; email confirmation toggle; trigger auto-creates profile row |
| AUTH-02 | User can log in and stay logged in across sessions | `signInWithPassword()` confirmed; session persisted via custom `SecureLocalStorage` wrapping `flutter_secure_storage` |
| AUTH-03 | User can log out from any screen | `supabase.auth.signOut()` confirmed; `onAuthStateChange` stream fires `signedOut` event; go_router redirect handles navigation |
| AUTH-04 | User can reset password via email link | `resetPasswordForEmail()` confirmed; requires deep link setup on iOS/Android and Supabase redirect URL config; `passwordRecovery` AuthChangeEvent drives in-app reset screen |
| AUTH-05 | New user completes 2-3 screen onboarding capturing household size and dietary preferences, persisted to Supabase | `profiles` table with upsert pattern confirmed; PageView + Riverpod StateNotifier for step management; `onboarding_completed` flag in `shared_preferences` drives go_router guard |
</phase_requirements>

---

## Summary

Phase 2 builds on the Foundation (Phase 1) to give users a complete authentication lifecycle and a first-run onboarding experience. The technical surface is well-understood: `supabase_flutter 2.x` provides the auth API, `flutter_secure_storage` (already in the stack) is used to implement a custom `LocalStorage` adapter so session tokens are stored in the device Keychain/Keystore rather than plain `SharedPreferences`. The go_router auth guard established in Phase 1 is extended here to handle three routing states — unauthenticated, authenticated-but-not-onboarded, and authenticated-and-onboarded.

The two highest-complexity areas are password reset (requires deep link configuration on both iOS and Android, plus Supabase redirect URL registration) and the go_router onboarding redirect (requires checking a second flag — onboarding completion — in addition to auth state). Both are solvable with known patterns but require care in implementation.

Supabase's default session storage uses `SharedPreferences`, which stores tokens in plaintext on Android. The project's STACK.md already mandates `flutter_secure_storage ^10.0.0` for this purpose. A custom `LocalStorage` implementation must be passed to `Supabase.initialize()` to override the default. This is a small but critical step that must not be skipped.

**Primary recommendation:** Implement auth as a thin service layer (`AuthRepository` wrapping `supabase.auth.*`), expose auth state as a `StreamProvider` watching `onAuthStateChange`, and wire go_router's redirect to read both auth state and onboarding completion flag. Build onboarding as a 2-screen PageView with a single `StateNotifier` accumulating answers before a single Supabase upsert on completion.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| supabase_flutter | ^2.12.0 | Auth API: signUp, signInWithPassword, signOut, resetPasswordForEmail, onAuthStateChange | Official Supabase Flutter client; already in project stack |
| flutter_secure_storage | ^10.0.0 | Encrypted session token storage (Keychain/Keystore) | Already in project stack; required to override Supabase default SharedPreferences storage; v10 is a major security update |
| flutter_riverpod | ^3.2.1 + riverpod_generator ^4.0.3 | Auth state as StreamProvider; onboarding state as StateNotifier | Already in project stack; standard for this project |
| go_router | ^17.1.0 | Route guards for unauthenticated and pre-onboarding users | Already in project stack; Phase 1 establishes the router; Phase 2 extends redirect logic |
| shared_preferences | ^2.5.4 | Persisting `onboarding_completed` boolean flag (non-sensitive) | Already in project stack; appropriate for non-sensitive flags |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| freezed | ^3.2.5 | Immutable `OnboardingData` accumulator model (household_size + dietary_preferences) | Collecting multi-screen onboarding answers before upsert |
| go_router | ^17.1.0 | `redirect` callback handles three-state routing: unauthed → /login, authed+no-onboard → /onboarding, authed+onboarded → /home | Already in stack |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom SecureLocalStorage | Default SharedPreferences storage | Default stores tokens in plaintext — violates GDPR/security requirements; never acceptable |
| PageView for onboarding | Separate named routes per screen | PageView is simpler for linear 2-3 screen flows; named routes add complexity for no gain at this scale |
| Riverpod StreamProvider for auth state | StatefulWidget + initState listener | StatefulWidget approach cannot be shared across go_router redirect logic; StreamProvider is the clean approach |

**Installation:**
All packages are already in the project stack from Phase 1. No new dependencies are required for Phase 2 beyond what is already planned.

---

## Architecture Patterns

### Recommended Project Structure

```
lib/
├── features/
│   └── auth/
│       ├── data/
│       │   ├── auth_repository.dart          # Wraps supabase.auth.* methods
│       │   └── secure_local_storage.dart     # Custom LocalStorage impl using flutter_secure_storage
│       ├── domain/
│       │   ├── auth_state.dart               # Sealed class: authenticated(user) | unauthenticated | loading
│       │   └── onboarding_data.dart          # Freezed: household_size + dietary_preferences list
│       └── presentation/
│           ├── auth_notifier.dart            # StreamNotifier wrapping onAuthStateChange
│           ├── onboarding_notifier.dart      # StateNotifier accumulating onboarding answers
│           └── screens/
│               ├── login_screen.dart
│               ├── signup_screen.dart
│               ├── forgot_password_screen.dart
│               ├── reset_password_screen.dart  # Shown when passwordRecovery event fires
│               └── onboarding/
│                   ├── onboarding_shell.dart  # PageView container
│                   ├── household_size_page.dart
│                   └── dietary_preferences_page.dart
└── app/
    └── router.dart                           # Extended with onboarding redirect
```

### Pattern 1: Custom SecureLocalStorage for Supabase Session

**What:** Override Supabase's default `SharedPreferences`-based session storage with a custom implementation wrapping `flutter_secure_storage`. Session JWT is stored encrypted in device Keychain (iOS) / Keystore (Android).

**When to use:** Always — pass this to `Supabase.initialize()` on app startup.

**Example:**
```dart
// Source: supabase/supabase-flutter local_storage.dart + flutter_secure_storage docs
class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _sessionKey = 'supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      (await _storage.read(key: _sessionKey)) != null;

  @override
  Future<String?> accessToken() async =>
      _storage.read(key: _sessionKey);

  @override
  Future<void> removePersistedSession() async =>
      _storage.delete(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) async =>
      _storage.write(key: _sessionKey, value: persistSessionString);
}

// In main():
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
  authOptions: FlutterAuthClientOptions(
    localStorage: SecureLocalStorage(),
  ),
);
```

### Pattern 2: Auth State as StreamProvider

**What:** Wrap `supabase.auth.onAuthStateChange` in a Riverpod `StreamProvider` so auth state is reactively available across the widget tree and go_router redirect.

**When to use:** App root — provides auth state to the entire app.

**Example:**
```dart
// Source: supabase.com/docs/reference/dart/auth-onauthstatechange
@riverpod
Stream<AuthState> authStateChanges(AuthStateChangesRef ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
}

// Convenience provider — returns the current user or null
@riverpod
User? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull?.session?.user;
}
```

**AuthChangeEvent values to handle:**
- `initialSession` — app startup with existing session; do not redirect to login
- `signedIn` — user just authenticated; check onboarding completion flag, redirect accordingly
- `signedOut` — redirect to login
- `passwordRecovery` — show in-app reset password screen (received via deep link)
- `tokenRefreshed` — no navigation needed; session updated silently

### Pattern 3: go_router Three-State Redirect

**What:** The router redirect callback reads both auth state and onboarding completion to route to the correct screen. Three states: unauthenticated → `/login`, authenticated + onboarding incomplete → `/onboarding`, authenticated + onboarding complete → `/home`.

**When to use:** In `router.dart`; extends the Phase 1 auth guard.

**Example:**
```dart
// Source: dinkomarinac.dev/blog/guarding-routes-in-flutter-with-gorouter-and-riverpod/
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final onboardingCompleted = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    refreshListenable: _buildRefreshListenable(ref, authState),
    redirect: (context, state) {
      // Still loading — don't redirect
      if (authState.isLoading || authState.hasError) return null;

      final isAuthenticated = authState.valueOrNull?.session != null;
      final isOnLoginOrSignup = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      if (!isAuthenticated) {
        return isOnLoginOrSignup ? null : '/login';
      }

      // Authenticated — check onboarding
      if (!onboardingCompleted && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }

      // Authenticated + onboarded — redirect away from auth screens
      if (isOnLoginOrSignup || state.matchedLocation == '/onboarding') {
        return '/home';
      }

      return null;
    },
    routes: [...],
  );
});
```

### Pattern 4: Onboarding Flow with PageView + StateNotifier + Supabase Upsert

**What:** A 2-screen PageView collects household size (screen 1) and dietary preferences (screen 2). A single `OnboardingNotifier` accumulates answers in an `OnboardingData` Freezed object. On the final screen "Done" tap, the notifier upserts to `profiles` and writes the `onboarding_completed` flag to `SharedPreferences`.

**When to use:** First login only — the go_router redirect handles not showing it again.

**Example:**
```dart
// Source: flutterexplained.com/p/flutter-onboarding-with-riverpod + supabase.com/docs/reference/dart/upsert
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingData build() => OnboardingData();

  void setHouseholdSize(int size) {
    state = state.copyWith(householdSize: size);
  }

  void toggleDietaryPreference(String preference) {
    final current = List<String>.from(state.dietaryPreferences);
    current.contains(preference)
        ? current.remove(preference)
        : current.add(preference);
    state = state.copyWith(dietaryPreferences: current);
  }

  Future<void> completeOnboarding() async {
    final user = Supabase.instance.client.auth.currentUser!;
    // Upsert to Supabase profiles table
    await Supabase.instance.client.from('profiles').upsert({
      'id': user.id,
      'household_size': state.householdSize,
      'dietary_preferences': state.dietaryPreferences,
      'onboarding_completed': true,
      'updated_at': DateTime.now().toIso8601String(),
    });
    // Mark locally so router redirect knows
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    // Notifier invalidation triggers router rebuild
    ref.invalidateSelf();
  }
}

// Profiles table SQL (Supabase):
// create table public.profiles (
//   id uuid references auth.users on delete cascade primary key,
//   household_size integer,
//   dietary_preferences text[],
//   onboarding_completed boolean default false,
//   updated_at timestamptz default now()
// );
// alter table public.profiles enable row level security;
// create policy "Users can manage their own profile"
//   on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);
```

### Pattern 5: Password Reset via Deep Link

**What:** `resetPasswordForEmail()` sends a magic link that opens the app via deep link. The `passwordRecovery` AuthChangeEvent fires in `onAuthStateChange`. The router detects this event and navigates to a reset password screen where the user enters a new password.

**When to use:** Forgot password flow only.

**Example:**
```dart
// Source: supabase.com/docs/guides/auth/native-mobile-deep-linking
// Step 1: Send reset email
await supabase.auth.resetPasswordForEmail(
  email,
  redirectTo: 'io.mealmate.app://reset-password',
);

// Step 2: Handle passwordRecovery event in auth notifier
// onAuthStateChange emits AuthChangeEvent.passwordRecovery when the
// deep link is opened. Router redirect checks for this event and
// navigates to /reset-password screen.

// Step 3: User sets new password on reset screen
await supabase.auth.updateUser(UserAttributes(password: newPassword));
```

**Deep link setup required (iOS `Info.plist`):**
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.mealmate.app</string>
    </array>
  </dict>
</array>
```

**Deep link setup required (Android `AndroidManifest.xml`):**
```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="io.mealmate.app" android:host="reset-password" />
</intent-filter>
```

**Supabase Dashboard:** Add `io.mealmate.app://reset-password` to Authentication > Redirect URLs.

### Anti-Patterns to Avoid

- **Calling Supabase auth methods directly from widgets:** All `supabase.auth.*` calls must go through `AuthRepository`. Widgets call the repository via Riverpod notifiers only.
- **Using SharedPreferences for session tokens:** Default Supabase storage is SharedPreferences — plaintext on Android. Always override with `SecureLocalStorage`.
- **Checking onboarding state only at app launch:** The go_router `redirect` must react to auth state changes (the `refreshListenable` must be wired to the auth stream), not just check state once on startup.
- **Navigating to home in the signedIn handler directly:** The `onAuthStateChange` listener should update Riverpod state only; navigation must be handled exclusively by go_router redirect to avoid double-navigation.
- **Using `user_metadata` claims in RLS policies:** Only `auth.uid()` is safe in RLS. User metadata can be modified by authenticated users.
- **Skipping the trigger for auto-creating profile rows:** Without the `on_auth_user_created` trigger, a race condition exists where a signed-in user navigating to the home screen before the onboarding flow completes will find no profile row.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Session storage security | Custom encryption for session tokens | `flutter_secure_storage ^10.0.0` + custom `LocalStorage` | Keychain/Keystore integration has dozens of edge cases (background app kill, screen unlock state, biometric auth). `flutter_secure_storage` handles all of them. |
| Token refresh | Manual JWT expiry tracking + refresh loop | `supabase_flutter` built-in token refresh | Supabase client handles refresh automatically; session string is renewed before expiry. Manual tracking introduces race conditions. |
| Email format validation | Custom regex | Flutter's built-in `Form` + `validator` property or `RegExp` from the cookbook | Rolling your own regex for email validation almost always has edge cases. Flutter's official cookbook shows the correct approach. |
| Route guarding | Custom Navigator push/pop logic | go_router `redirect` callback watching Riverpod auth state | Custom navigation logic breaks when deep links, notifications, or back navigation are involved. go_router redirect is the single, correct integration point. |

**Key insight:** Auth is a domain full of edge cases — token expiry, race conditions, deep link timing, keychain accessibility states. Using the platform's auth SDK (supabase_flutter) and the platform's secure storage (flutter_secure_storage) eliminates these problems. Every line of custom auth infrastructure is a liability.

---

## Common Pitfalls

### Pitfall 1: Default Session Storage in SharedPreferences

**What goes wrong:** Supabase Flutter defaults to `SharedPreferences` for session storage. On Android, this stores the JWT in plaintext on the filesystem. This violates GDPR requirements (personal data processed for authentication must be adequately protected) and is a security risk if the device is compromised.

**Why it happens:** Developers call `Supabase.initialize()` without the `authOptions.localStorage` parameter and assume session storage is secure.

**How to avoid:** Always pass `FlutterAuthClientOptions(localStorage: SecureLocalStorage())` to `Supabase.initialize()`. Verify by checking that no session data appears in `SharedPreferences` after login.

**Warning signs:** `Supabase.initialize()` call without `authOptions` parameter; no `flutter_secure_storage` usage in the auth feature.

### Pitfall 2: Password Reset Deep Link Not Working When App is Closed

**What goes wrong:** The reset email is sent successfully. The user taps the link. But the app fails to open, or opens on the home screen instead of the reset password screen, or the `passwordRecovery` AuthChangeEvent is never fired.

**Why it happens:** Three separate configurations must all be correct simultaneously: (1) the custom URL scheme in `Info.plist`/`AndroidManifest.xml`, (2) the `redirectTo` URL in `resetPasswordForEmail()` must exactly match the registered scheme, and (3) the redirect URL must be registered in the Supabase Dashboard under Authentication > Redirect URLs. Any mismatch causes silent failure.

**How to avoid:** Test the deep link flow end-to-end on a real device early. Use the exact same URL string in all three places. The PKCE flow (default in supabase_flutter 2.x) handles the token exchange automatically when the deep link is received — do not attempt to manually parse the URL fragment.

**Warning signs:** Password reset email sent successfully (confirmed in Supabase auth logs) but app doesn't open or navigate correctly; `passwordRecovery` event never fires in `onAuthStateChange` logs.

### Pitfall 3: Router Redirect Not Reactive to Auth State Changes

**What goes wrong:** The go_router redirect correctly handles the initial app launch routing, but when the user signs out mid-session, the router doesn't redirect to `/login`. Or: the user completes onboarding, but the app stays on the onboarding screen instead of navigating to `/home`.

**Why it happens:** go_router's `redirect` is only called when navigation happens, not proactively. Without a `refreshListenable` (or `router.refresh()`) wired to the auth state stream, route changes driven by auth state changes don't trigger a re-evaluation of the redirect logic.

**How to avoid:** Wire `GoRouter.refreshListenable` to a `Listenable` that fires whenever auth state or onboarding state changes. A common pattern is using a `ChangeNotifier` that calls `notifyListeners()` whenever the Riverpod providers update:

```dart
// Pattern: make auth stream drive router refresh
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    ref.listen(onboardingCompletedProvider, (_, __) => notifyListeners());
  }
}
```

**Warning signs:** Signing out doesn't navigate to login screen without a hot restart; completing onboarding doesn't navigate to home screen automatically.

### Pitfall 4: Race Condition — onboarding_completed Flag Out of Sync with Supabase

**What goes wrong:** The user completes onboarding, the Supabase upsert succeeds, but writing the local `SharedPreferences` flag fails (or vice versa). On next launch, the go_router redirect checks the local flag and incorrectly routes the user back to onboarding, where a re-upsert is attempted.

**Why it happens:** Two writes (Supabase upsert + SharedPreferences) are not atomic. If the app is killed between the two writes, the state is inconsistent.

**How to avoid:** Design the redirect logic to check BOTH the local `SharedPreferences` flag AND the Supabase `profiles.onboarding_completed` column. On app startup (the `initialSession` AuthChangeEvent), fetch the profile row and sync the local flag. The local flag is a cache of the remote truth, not the source of truth.

**Warning signs:** Onboarding appears to repeat for users who definitely completed it; onboarding state not recovered after app reinstall.

### Pitfall 5: Dietary Preferences Stored as Flat Text String in Supabase

**What goes wrong:** Storing `dietary_preferences` as a single `text` column (comma-separated string like `"vegetarian,gluten-free"`) requires parsing on every read and makes querying for users with a specific preference impossible without a LIKE scan.

**Why it happens:** Simplicity — a `text` column is the fastest initial implementation.

**How to avoid:** Use a PostgreSQL `text[]` array column. Flutter's Supabase client handles `List<String>` serialization to `text[]` automatically in upsert operations. This enables clean SQL queries like `WHERE 'vegetarian' = ANY(dietary_preferences)` in future phases (e.g., recipe filtering).

**Warning signs:** `dietary_preferences text` column in the profiles table migration.

---

## Code Examples

Verified patterns from official sources:

### Supabase Auth API — Core Operations

```dart
// Source: supabase.com/docs/reference/dart/auth-signinwithpassword
// Sign up
final AuthResponse res = await supabase.auth.signUp(
  email: email,
  password: password,
);
final User? user = res.user;

// Sign in
final AuthResponse res = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

// Sign out
await supabase.auth.signOut();

// Password reset
await supabase.auth.resetPasswordForEmail(
  email,
  redirectTo: 'io.mealmate.app://reset-password',
);

// Update password (called from reset password screen after passwordRecovery event)
await supabase.auth.updateUser(UserAttributes(password: newPassword));
```

### onAuthStateChange — Listening Pattern

```dart
// Source: supabase.com/docs/reference/dart/auth-onauthstatechange
// AuthChangeEvent values: initialSession, signedIn, signedOut,
// passwordRecovery, tokenRefreshed, userUpdated, userDeleted

final subscription = supabase.auth.onAuthStateChange.listen((data) {
  final AuthChangeEvent event = data.event;
  final Session? session = data.session;
  switch (event) {
    case AuthChangeEvent.signedIn:
      // Check onboarding, route to /onboarding or /home
    case AuthChangeEvent.signedOut:
      // Route to /login
    case AuthChangeEvent.passwordRecovery:
      // Route to /reset-password
    default:
      break;
  }
});
// Always cancel in dispose:
subscription.cancel();
```

### Supabase Profile Table — SQL Setup

```sql
-- Source: supabase.com/docs/guides/auth/managing-user-data
-- Run in Supabase SQL editor or migration file

create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  household_size integer,
  dietary_preferences text[],
  onboarding_completed boolean default false,
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users can manage their own profile"
  on public.profiles
  for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

create index profiles_id_idx on public.profiles(id);

-- Auto-create empty profile row on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id)
  values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

### Form Validation — Login Screen Pattern

```dart
// Source: docs.flutter.dev/cookbook/forms/validation
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Email is required';
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
          return null;
        },
      ),
      TextFormField(
        obscureText: true,
        validator: (value) {
          if (value == null || value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Call auth repository
          }
        },
        child: const Text('Log In'),
      ),
    ],
  ),
)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Provider` enum in supabase_flutter | `OAuthProvider` enum | supabase_flutter v2 (2023) | Breaking change; use `OAuthProvider` for any OAuth flows |
| Manual session refresh polling | Built-in automatic token refresh via supabase_flutter | supabase_flutter v1+ | Session refresh is fully automatic; do not poll `expiresAt` |
| Session stored in SharedPreferences (default) | Custom `LocalStorage` with `flutter_secure_storage` | Best practice since flutter_secure_storage became stable | Security requirement; plaintext token storage is not acceptable |
| StateNotifier for Riverpod | Notifier / AsyncNotifier + code gen | Riverpod 2.x → 3.x (Sep 2025) | Use `@riverpod` annotation with `Notifier` / `AsyncNotifier` classes; `StateNotifier` still works but is the legacy approach |
| Hash-based deep link fragments (`#access_token=...`) | PKCE flow (code-based, not fragment-based) | supabase_flutter 2.x default | PKCE is more secure; supabase_flutter handles exchange automatically; do not attempt to manually parse `access_token` from URL |

**Deprecated/outdated:**
- `StateNotifier`: Still functional but superseded by `Notifier`/`AsyncNotifier` with `@riverpod` annotation in Riverpod 3.x. New code in this project should use the generator pattern.
- Pre-v2 auth flows from tutorials: Many online articles use `supabase.auth.signIn()` (v1 API). The v2 API uses `signInWithPassword()`. Filter tutorial results by date.

---

## Open Questions

1. **Email confirmation: enabled or disabled for v1?**
   - What we know: Supabase enables email confirmation by default. When enabled, `signUp()` returns a session only after the user clicks the confirmation link. Without confirmation, the user is in an unconfirmed state and cannot access protected resources.
   - What's unclear: The requirements (AUTH-01) say "user can sign up with email and password" but don't specify whether email confirmation is required. For a mobile app in early development, email confirmation adds friction (deep link needed for the confirmation click) and can slow iteration. For production, it is a security/GDPR best practice.
   - Recommendation: **Disable email confirmation in Supabase Dashboard during Phase 2 development.** Plan to re-enable it before Phase 9 (Polish & GDPR Hardening) with proper deep link handling. Document this as a known TODO in the plan.

2. **Where to check onboarding completion: local flag only, or also Supabase profile?**
   - What we know: The local `SharedPreferences` flag is faster to read at startup. The Supabase `profiles.onboarding_completed` column is the source of truth and survives app reinstalls.
   - What's unclear: Does Phase 2 need to handle the reinstall scenario where the local flag is gone but Supabase has `onboarding_completed = true`? This depends on whether multi-device sync (Phase 8) is expected to cover this.
   - Recommendation: **For Phase 2, use local `SharedPreferences` flag as primary check.** On `initialSession` event (app startup with existing session), fetch the profile row and sync the local flag. This handles the reinstall case without requiring network on every launch.

3. **go_router `refreshListenable` integration with Riverpod providers**
   - What we know: go_router's `refreshListenable` needs a `Listenable`, but Riverpod providers are not `Listenable` directly. A bridge `ChangeNotifier` is needed.
   - What's unclear: Riverpod 3.x may have a cleaner integration path. The Phase 1 router setup will determine what the existing foundation looks like.
   - Recommendation: **Use a `RouterRefreshNotifier extends ChangeNotifier` that listens to auth and onboarding providers via `ref.listen` and calls `notifyListeners()`.** This is the established community pattern (verified across multiple sources).

---

## Sources

### Primary (HIGH confidence)
- [supabase.com/docs/reference/dart/auth-signinwithpassword](https://supabase.com/docs/reference/dart/auth-signinwithpassword) — signInWithPassword, signUp, signOut API
- [supabase.com/docs/reference/dart/auth-onauthstatechange](https://supabase.com/docs/reference/dart/auth-onauthstatechange) — onAuthStateChange stream, AuthChangeEvent enum
- [supabase.com/docs/guides/auth/managing-user-data](https://supabase.com/docs/guides/auth/managing-user-data) — profiles table structure, trigger pattern, upsert
- [supabase.com/docs/guides/getting-started/tutorials/with-flutter](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter) — Supabase.initialize(), session check at startup
- [supabase.com/docs/guides/auth/native-mobile-deep-linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking) — iOS/Android deep link setup, Supabase redirect URL config
- [supabase/supabase-flutter LocalStorage source](https://github.com/supabase/supabase-flutter/blob/main/packages/supabase_flutter/lib/src/local_storage.dart) — LocalStorage interface, SecureLocalStorage pattern
- [docs.flutter.dev/cookbook/forms/validation](https://docs.flutter.dev/cookbook/forms/validation) — Form + TextFormField + GlobalKey validation pattern

### Secondary (MEDIUM confidence)
- [dinkomarinac.dev — Guarding routes with GoRouter and Riverpod](https://dinkomarinac.dev/blog/guarding-routes-in-flutter-with-gorouter-and-riverpod/) — three-state redirect pattern, refreshListenable wiring
- [flutterexplained.com — Flutter Onboarding with Riverpod](https://flutterexplained.com/p/flutter-onboarding-with-riverpod) — onboarding completion flag in SharedPreferences, GoRouter initial route
- [apparencekit.dev — Flutter + Riverpod + GoRouter redirect](https://apparencekit.dev/blog/flutter-riverpod-gorouter-redirect/) — router provider pattern with Riverpod
- [supabase.com blog — flutter-authentication](https://supabase.com/blog/flutter-authentication) — onAuthStateChange + deep link handling for password recovery

### Tertiary (LOW confidence)
- [meoromi.medium.com — Reset Password on Flutter Supabase Without Deeplink](https://meoromi.medium.com/reset-password-on-flutter-supabase-without-deeplink-in-alternate-way-4165c94f8b1a) — alternative password reset without deep link (not recommended for v1 but useful fallback)
- [medium.com — Flutter + Supabase Auth: Complete Guide](https://medium.com/@punithsuppar7795/flutter-supabase-auth-a-complete-guide-to-secure-login-signup-6c3a3bfe18a3) — general auth walkthrough (unverified date)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already decided in Phase 1 STACK.md; supabase_flutter 2.x API verified against official docs
- Architecture: HIGH — patterns verified against official Flutter docs, official Supabase docs, and multiple consistent community sources
- Deep link password reset: MEDIUM — API verified against official docs; iOS/Android configuration details verified against deep linking guide; end-to-end integration has known community pain points (see Pitfall 2)
- Onboarding routing: MEDIUM — pattern verified against multiple community sources; exact Riverpod 3.x integration nuances may need adjustment based on Phase 1 router foundation

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (supabase_flutter API stable; go_router redirect patterns stable; deep link setup OS-dependent and may change with new Flutter/iOS/Android releases)
