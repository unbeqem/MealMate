import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around [SupabaseClient.auth] that isolates all Supabase auth
/// calls from the rest of the application.
///
/// Widgets and notifiers must never call [supabase.auth] directly — they use
/// this repository via [authRepositoryProvider].
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Signs up a new user with email and password.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) =>
      _client.auth.signUp(email: email, password: password);

  /// Signs in an existing user with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  /// Signs out the current user.
  Future<void> signOut() => _client.auth.signOut();

  /// Sends a password reset email to [email].
  ///
  /// The [redirectTo] deep link must match the scheme registered in
  /// Info.plist / AndroidManifest.xml and in the Supabase Dashboard under
  /// Authentication > Redirect URLs.
  Future<void> resetPasswordForEmail(String email) =>
      _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.mealmate.app://reset-password',
      );

  /// Updates the currently signed-in user's password.
  Future<UserResponse> updatePassword(String newPassword) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

  /// Stream of authentication state changes.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// The current session, or null if unauthenticated.
  Session? get currentSession => _client.auth.currentSession;

  /// The current user, or null if unauthenticated.
  User? get currentUser => _client.auth.currentUser;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});
