import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

part 'auth_notifier.g.dart';

/// Exposes the [AuthRepository] instance to the widget tree.
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(Supabase.instance.client);
}

/// Stream of [AuthState] changes from Supabase auth.
///
/// Used by go_router's redirect to reactively guard routes.
@riverpod
Stream<AuthState> authStateChanges(AuthStateChangesRef ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.onAuthStateChange;
}

/// Convenience provider returning the currently signed-in [User] or null.
@riverpod
User? currentUser(CurrentUserRef ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.valueOrNull?.session?.user;
}

/// Backward-compatible alias for [authStateChangesProvider].
///
/// [router.dart] and other existing consumers import this name.
final authStateProvider = authStateChangesProvider;
