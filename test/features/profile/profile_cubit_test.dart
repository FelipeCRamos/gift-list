import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/data/models/models.dart';
import 'package:gift_list/data/repositories/auth_repository.dart';
import 'package:gift_list/data/repositories/gift_registry_repository.dart';
import 'package:gift_list/features/profile/presentation/profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockRegistry extends Mock implements GiftRegistryRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockRegistry registry;
  late MockAuthRepository auth;

  final existing = Profile(
    id: 'user-demo@giftlist.dev',
    displayName: 'Ana',
    createdAt: DateTime(2026),
    defaultPixKey: 'ana@x.com',
    pixKeyType: PixKeyType.email,
    merchantCity: 'SAO PAULO',
  );

  setUpAll(() {
    registerFallbackValue(
      Profile(id: 'x', displayName: 'x', createdAt: DateTime(2026)),
    );
  });

  setUp(() {
    registry = MockRegistry();
    auth = MockAuthRepository();
  });

  ProfileCubit build() => ProfileCubit(registry: registry, auth: auth);

  group('ProfileCubit.load', () {
    blocTest<ProfileCubit, ProfileState>(
      'emits [loading, ready] with the existing profile',
      setUp: () =>
          when(() => registry.getMyProfile()).thenAnswer((_) async => existing),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        ProfileState(status: ProfileStatus.ready, profile: existing),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'builds a blank draft from the current user when no profile exists',
      setUp: () {
        when(() => registry.getMyProfile()).thenAnswer((_) async => null);
        when(
          () => auth.currentUser,
        ).thenReturn(const AuthUser(id: 'user-new', email: 'newbie@x.com'));
      },
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        isA<ProfileState>()
            .having((s) => s.status, 'status', ProfileStatus.ready)
            .having((s) => s.profile?.id, 'id', 'user-new')
            .having((s) => s.profile?.displayName, 'name', 'newbie'),
      ],
    );
  });

  group('ProfileCubit.save', () {
    blocTest<ProfileCubit, ProfileState>(
      'emits [saving, saved] on success',
      setUp: () => when(
        () => registry.saveMyProfile(any()),
      ).thenAnswer((_) async => existing),
      build: build,
      act: (cubit) => cubit.save(existing),
      expect: () => [
        const ProfileState(status: ProfileStatus.saving),
        ProfileState(status: ProfileStatus.saved, profile: existing),
      ],
    );
  });
}
