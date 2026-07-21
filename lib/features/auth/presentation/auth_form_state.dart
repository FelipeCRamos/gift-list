part of 'auth_form_cubit.dart';

enum AuthMode { signIn, signUp }

enum FormStatus { idle, submitting, success, failure, magicLinkSent }

class AuthFormState extends Equatable {
  const AuthFormState({
    this.mode = AuthMode.signIn,
    this.status = FormStatus.idle,
    this.errorMessage,
  });

  final AuthMode mode;
  final FormStatus status;
  final String? errorMessage;

  bool get isSubmitting => status == FormStatus.submitting;
  bool get isSignIn => mode == AuthMode.signIn;

  AuthFormState copyWith({
    AuthMode? mode,
    FormStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthFormState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [mode, status, errorMessage];
}
