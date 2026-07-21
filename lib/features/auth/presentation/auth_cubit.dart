import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/auth_user.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_state.dart';

/// Root-scoped session cubit. Tracks the signed-in user and exposes the auth
/// actions; routing guards and gates read its state.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository authRepository})
    : _auth = authRepository,
      super(const AuthState.unknown()) {
    _sub = _auth.authState().listen(_onUserChanged);
  }

  final AuthRepository _auth;
  late final StreamSubscription<AuthUser?> _sub;

  void _onUserChanged(AuthUser? user) {
    emit(
      user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, user: user),
    );
  }

  Future<void> signInWithPassword(String email, String password) =>
      _auth.signInWithPassword(email, password);

  Future<void> signUp(String email, String password) =>
      _auth.signUp(email, password);

  Future<void> sendMagicLink(String email) => _auth.sendMagicLink(email);

  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
