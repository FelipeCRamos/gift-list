import 'dart:async';

import '../../models/auth_user.dart';
import '../auth_repository.dart';

/// In-memory [AuthRepository] for local development and tests. Any non-empty
/// password signs in; the user id is derived deterministically from the email so
/// seeded ownership lines up (see [userIdForEmail]).
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({AuthUser? initialUser}) : _current = initialUser;

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  AuthUser? _current;

  /// Stable id for an email so mock sign-in matches seeded `ownerId`s.
  static String userIdForEmail(String email) =>
      'user-${email.trim().toLowerCase()}';

  @override
  AuthUser? get currentUser => _current;

  @override
  Stream<AuthUser?> authState() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> signInWithPassword(String email, String password) async {
    if (password.isEmpty) {
      throw ArgumentError('Password required');
    }
    _emit(_userFor(email));
  }

  @override
  Future<void> signUp(String email, String password) async {
    if (password.isEmpty) {
      throw ArgumentError('Password required');
    }
    _emit(_userFor(email));
  }

  @override
  Future<void> sendMagicLink(String email) async {
    // No-op in the mock — a real magic link is delivered out of band.
  }

  @override
  Future<void> signOut() async => _emit(null);

  AuthUser _userFor(String email) {
    final String normalized = email.trim().toLowerCase();
    return AuthUser(id: userIdForEmail(normalized), email: normalized);
  }

  void _emit(AuthUser? user) {
    _current = user;
    _controller.add(user);
  }

  void dispose() => _controller.close();
}
