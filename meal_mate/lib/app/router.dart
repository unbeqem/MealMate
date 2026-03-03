import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;
import '../features/auth/presentation/auth_notifier.dart';
import '../features/auth/presentation/onboarding_notifier.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/onboarding/onboarding_shell.dart';
import '../features/home/presentation/screens/home_screen.dart';

// ---------------------------------------------------------------------------
// RouterRefreshNotifier
// ---------------------------------------------------------------------------

/// Bridges Riverpod providers to go_router's [refreshListenable].
///
/// Notifies go_router to re-evaluate the [redirect] callback whenever:
/// - The Supabase auth state changes ([authStateChangesProvider])
/// - The local onboarding completion flag changes ([onboardingCompletedProvider])
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    ref.listen(onboardingCompletedProvider, (_, __) => notifyListeners());
  }
}

// ---------------------------------------------------------------------------
// routerProvider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final onboardingCompletedAsync = ref.watch(onboardingCompletedProvider);

  // Sync onboarding flag from Supabase on initialSession (handles reinstall scenario).
  // When the user reinstalls, the local SharedPreferences flag is gone but Supabase
  // still has the completed profile row. We fetch it and restore the local flag.
  ref.listen(authStateChangesProvider, (_, next) async {
    final authEvent = next.valueOrNull?.event;
    final user = next.valueOrNull?.session?.user;
    if (authEvent == AuthChangeEvent.initialSession && user != null) {
      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('onboarding_completed')
            .eq('id', user.id)
            .maybeSingle();
        if (response != null &&
            response['onboarding_completed'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('onboarding_completed', true);
          // Invalidate the onboarding provider so router re-evaluates.
          ref.invalidate(onboardingCompletedProvider);
        }
      } catch (_) {
        // Silently ignore — the local flag is the source of truth for this session.
        // On next app open with network, the sync will succeed.
      }
    }
  });

  final refreshNotifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // CRITICAL: Don't redirect while auth state is loading — prevents login flash.
      if (authState.isLoading || authState.hasError) return null;

      final session = authState.valueOrNull?.session;
      final isAuthenticated = session != null;
      final authEvent = authState.valueOrNull?.event;

      // Handle passwordRecovery deep link event — route to reset password screen.
      if (authEvent == AuthChangeEvent.passwordRecovery) {
        return '/reset-password';
      }

      final currentLocation = state.matchedLocation;

      // --- UNAUTHENTICATED ---
      if (!isAuthenticated) {
        const authRoutes = ['/login', '/signup', '/forgot-password'];
        if (authRoutes.contains(currentLocation)) return null;
        return '/login';
      }

      // --- AUTHENTICATED ---
      // Read onboarding completion state. While the async provider loads,
      // treat it as not completed (stay on current screen, re-evaluate on load).
      final isOnboarded = onboardingCompletedAsync.valueOrNull ?? false;
      final isLoadingOnboarding = onboardingCompletedAsync.isLoading;

      // Wait for the onboarding state to resolve before making routing decisions.
      if (isLoadingOnboarding) return null;

      if (!isOnboarded) {
        // Authenticated but not onboarded — enforce onboarding.
        if (currentLocation == '/onboarding') return null;
        return '/onboarding';
      }

      // Authenticated AND onboarded — push off auth/onboarding routes.
      const preHomeRoutes = [
        '/login',
        '/signup',
        '/forgot-password',
        '/onboarding',
      ];
      if (preHomeRoutes.contains(currentLocation)) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingShell(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
    ],
  );
});
