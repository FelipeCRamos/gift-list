import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/data/models/models.dart';
import 'package:gift_list/data/repositories/gift_registry_repository.dart';
import 'package:gift_list/features/lists/presentation/list_editor_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockRegistry extends Mock implements GiftRegistryRepository {}

GiftList _list({
  ListVisibility visibility = ListVisibility.public,
  ContributorAuth auth = ContributorAuth.anonymous,
}) {
  return GiftList(
    id: 'list-1',
    ownerId: 'owner',
    slug: 'slug',
    title: 'Title',
    occasion: Occasion.other,
    pixKey: 'k@x.com',
    pixKeyType: PixKeyType.email,
    merchantName: 'ANA',
    visibility: visibility,
    contributorAuth: auth,
    isPublished: false,
    createdAt: DateTime(2026),
  );
}

void main() {
  late MockRegistry registry;

  setUpAll(() => registerFallbackValue(const ListUpdate()));
  setUp(() => registry = MockRegistry());

  ListEditorCubit build() => ListEditorCubit(registry: registry);

  group('private ⇒ login_required invariant', () {
    blocTest<ListEditorCubit, ListEditorState>(
      'setVisibility(private) forces login_required and locks the toggle',
      build: build,
      act: (cubit) => cubit.setVisibility(ListVisibility.private),
      expect: () => [
        isA<ListEditorState>()
            .having((s) => s.visibility, 'visibility', ListVisibility.private)
            .having(
              (s) => s.contributorAuth,
              'auth',
              ContributorAuth.loginRequired,
            )
            .having((s) => s.authLocked, 'locked', true),
      ],
    );

    blocTest<ListEditorCubit, ListEditorState>(
      'setContributorAuth is ignored while private (locked)',
      build: build,
      act: (cubit) {
        cubit.setVisibility(ListVisibility.private);
        cubit.setContributorAuth(ContributorAuth.anonymous);
      },
      // Only the visibility change emits; the locked auth change is a no-op.
      expect: () => [
        isA<ListEditorState>().having(
          (s) => s.contributorAuth,
          'auth',
          ContributorAuth.loginRequired,
        ),
      ],
    );

    blocTest<ListEditorCubit, ListEditorState>(
      'returning to public unlocks the contributor auth toggle',
      build: build,
      act: (cubit) {
        cubit.setVisibility(ListVisibility.private);
        cubit.setVisibility(ListVisibility.public);
        cubit.setContributorAuth(ContributorAuth.anonymous);
      },
      expect: () => [
        isA<ListEditorState>().having((s) => s.authLocked, 'locked', true),
        isA<ListEditorState>().having((s) => s.authLocked, 'locked', false),
        isA<ListEditorState>().having(
          (s) => s.contributorAuth,
          'auth',
          ContributorAuth.anonymous,
        ),
      ],
    );
  });

  blocTest<ListEditorCubit, ListEditorState>(
    'load seeds access settings from the list',
    setUp: () => when(() => registry.getMyList('list-1')).thenAnswer(
      (_) async => _list(
        visibility: ListVisibility.private,
        auth: ContributorAuth.loginRequired,
      ),
    ),
    build: build,
    act: (cubit) => cubit.load('list-1'),
    expect: () => [
      isA<ListEditorState>().having(
        (s) => s.status,
        'status',
        ListEditorStatus.loading,
      ),
      isA<ListEditorState>()
          .having((s) => s.status, 'status', ListEditorStatus.ready)
          .having((s) => s.authLocked, 'locked', true),
    ],
  );

  blocTest<ListEditorCubit, ListEditorState>(
    'save sends the live visibility/auth in the update',
    setUp: () {
      when(() => registry.getMyList('list-1')).thenAnswer((_) async => _list());
      when(() => registry.updateList(any(), any())).thenAnswer(
        (_) async => _list(
          visibility: ListVisibility.private,
          auth: ContributorAuth.loginRequired,
        ),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.load('list-1');
      cubit.setVisibility(ListVisibility.private);
      await cubit.save(
        title: 'Title',
        occasion: Occasion.other,
        pixKey: 'k@x.com',
        pixKeyType: PixKeyType.email,
        merchantName: 'ANA',
      );
    },
    verify: (_) {
      final captured =
          verify(
                () => registry.updateList('list-1', captureAny()),
              ).captured.single
              as ListUpdate;
      expect(captured.visibility, ListVisibility.private);
      expect(captured.contributorAuth, ContributorAuth.loginRequired);
    },
  );
}
