import '../models/auth_user.dart';

/// Authentication boundary. Supabase lives only behind implementations of this.
abstract class AuthRepository {
  /// Emits the current user (or null) and every subsequent change.
  Stream<AuthUser?> authState();

  /// The currently signed-in user, or null if anonymous.
  AuthUser? get currentUser;

  Future<void> signInWithPassword(String email, String password);

  Future<void> signUp(String email, String password);

  Future<void> sendMagicLink(String email);

  Future<void> signOut();
}
