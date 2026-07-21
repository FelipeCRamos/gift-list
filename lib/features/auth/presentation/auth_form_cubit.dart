import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_form_state.dart';

/// Drives the `/auth` form (sign in / sign up / magic link). Session state lives
/// in the root [AuthCubit], which observes the auth stream — this cubit only
/// owns the form's submission lifecycle.
class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit({required AuthRepository authRepository})
    : _auth = authRepository,
      super(const AuthFormState());

  final AuthRepository _auth;

  void toggleMode() {
    emit(
      AuthFormState(
        mode: state.mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn,
      ),
    );
  }

  Future<void> submit({required String email, required String password}) async {
    emit(state.copyWith(status: FormStatus.submitting, clearError: true));
    try {
      if (state.mode == AuthMode.signIn) {
        await _auth.signInWithPassword(email.trim(), password);
      } else {
        await _auth.signUp(email.trim(), password);
      }
      // On success the root AuthCubit reacts to the auth stream and the router
      // redirects away from `/auth`.
      emit(state.copyWith(status: FormStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  Future<void> sendMagicLink(String email) async {
    emit(state.copyWith(status: FormStatus.submitting, clearError: true));
    try {
      await _auth.sendMagicLink(email.trim());
      emit(state.copyWith(status: FormStatus.magicLinkSent));
    } catch (error) {
      emit(
        state.copyWith(
          status: FormStatus.failure,
          errorMessage: _messageFor(error),
        ),
      );
    }
  }

  String _messageFor(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Something went wrong. Please check your details and try again.';
  }
}
