import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/core/errors/errors.dart';
import 'package:gift_list/data/repositories/auth_repository.dart';
import 'package:gift_list/features/auth/presentation/auth_form_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository auth;

  setUp(() => auth = MockAuthRepository());

  group('AuthFormCubit', () {
    test('starts idle in sign-in mode', () {
      final cubit = AuthFormCubit(authRepository: auth);
      expect(cubit.state.mode, AuthMode.signIn);
      expect(cubit.state.status, FormStatus.idle);
    });

    blocTest<AuthFormCubit, AuthFormState>(
      'toggleMode switches to sign-up',
      build: () => AuthFormCubit(authRepository: auth),
      act: (cubit) => cubit.toggleMode(),
      expect: () => const [AuthFormState(mode: AuthMode.signUp)],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'submit signs in and emits [submitting, success]',
      setUp: () => when(
        () => auth.signInWithPassword(any(), any()),
      ).thenAnswer((_) async {}),
      build: () => AuthFormCubit(authRepository: auth),
      act: (cubit) => cubit.submit(email: 'a@b.com', password: 'secret'),
      expect: () => const [
        AuthFormState(status: FormStatus.submitting),
        AuthFormState(status: FormStatus.success),
      ],
      verify: (_) =>
          verify(() => auth.signInWithPassword('a@b.com', 'secret')).called(1),
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'submit in sign-up mode calls signUp',
      setUp: () =>
          when(() => auth.signUp(any(), any())).thenAnswer((_) async {}),
      build: () => AuthFormCubit(authRepository: auth),
      act: (cubit) async {
        cubit.toggleMode();
        await cubit.submit(email: 'a@b.com', password: 'secret');
      },
      verify: (_) => verify(() => auth.signUp('a@b.com', 'secret')).called(1),
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'submit surfaces the AppException message on failure',
      setUp: () => when(
        () => auth.signInWithPassword(any(), any()),
      ).thenThrow(const ValidationException('Bad credentials')),
      build: () => AuthFormCubit(authRepository: auth),
      act: (cubit) => cubit.submit(email: 'a@b.com', password: 'secret'),
      expect: () => const [
        AuthFormState(status: FormStatus.submitting),
        AuthFormState(
          status: FormStatus.failure,
          errorMessage: 'Bad credentials',
        ),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'sendMagicLink emits [submitting, magicLinkSent]',
      setUp: () =>
          when(() => auth.sendMagicLink(any())).thenAnswer((_) async {}),
      build: () => AuthFormCubit(authRepository: auth),
      act: (cubit) => cubit.sendMagicLink('a@b.com'),
      expect: () => const [
        AuthFormState(status: FormStatus.submitting),
        AuthFormState(status: FormStatus.magicLinkSent),
      ],
    );
  });
}
