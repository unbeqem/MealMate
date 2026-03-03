import 'package:supabase_flutter/supabase_flutter.dart';

/// Sealed class representing the authentication state of the application.
///
/// Three variants:
/// - [AppAuthStateAuthenticated] — user is signed in, [user] is non-null
/// - [AppAuthStateUnauthenticated] — user is signed out
/// - [AppAuthStateLoading] — auth state is being determined (app startup)
sealed class AppAuthState {
  const AppAuthState();
}

/// The user is authenticated. [user] is the signed-in Supabase [User].
final class AppAuthStateAuthenticated extends AppAuthState {
  final User user;
  const AppAuthStateAuthenticated(this.user);
}

/// The user is not authenticated.
final class AppAuthStateUnauthenticated extends AppAuthState {
  const AppAuthStateUnauthenticated();
}

/// Authentication state is loading (e.g., restoring session on app startup).
final class AppAuthStateLoading extends AppAuthState {
  const AppAuthStateLoading();
}
