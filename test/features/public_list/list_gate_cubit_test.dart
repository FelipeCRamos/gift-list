import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/core/errors/errors.dart';
import 'package:gift_list/data/models/models.dart';
import 'package:gift_list/data/repositories/auth_repository.dart';
import 'package:gift_list/data/repositories/gift_registry_repository.dart';
import 'package:gift_list/features/public_list/presentation/list_gate_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockRegistry extends Mock implements GiftRegistryRepository {}

class MockAuth extends Mock implements AuthRepository {}

ListAccessInfo _info(ListVisibility v, ContributorAuth a) =>
    ListAccessInfo(exists: true, title: 'T', visibility: v, contributorAuth: a);

const _user = AuthUser(id: 'u', email: 'u@x.com');

void main() {
  late MockRegistry registry;
  late MockAuth auth;

  setUp(() {
    registry = MockRegistry();
    auth = MockAuth();
    when(() => auth.currentUser).thenReturn(null);
  });

  ListGateCubit build() =>
      ListGateCubit(registry: registry, auth: auth, slug: 'slug');

  void stubInfo(ListAccessInfo info) => when(
    () => registry.getListAccessInfo('slug'),
  ).thenAnswer((_) async => info);

  GateStatus statusOf(ListGateCubit c) => c.state.status;

  blocTest<ListGateCubit, ListGateState>(
    'notFound when the slug is unknown',
    setUp: () => stubInfo(const ListAccessInfo.notFound()),
    build: build,
    act: (c) => c.resolve(),
    verify: (c) => expect(statusOf(c), GateStatus.notFound),
  );

  blocTest<ListGateCubit, ListGateState>(
    'public + anonymous → ready',
    setUp: () =>
        stubInfo(_info(ListVisibility.public, ContributorAuth.anonymous)),
    build: build,
    act: (c) => c.resolve(),
    verify: (c) => expect(statusOf(c), GateStatus.ready),
  );

  blocTest<ListGateCubit, ListGateState>(
    'public + login_required, no session → needsLogin',
    setUp: () =>
        stubInfo(_info(ListVisibility.public, ContributorAuth.loginRequired)),
    build: build,
    act: (c) => c.resolve(),
    verify: (c) => expect(statusOf(c), GateStatus.needsLogin),
  );

  blocTest<ListGateCubit, ListGateState>(
    'public + login_required, signed in → ready',
    setUp: () {
      when(() => auth.currentUser).thenReturn(_user);
      stubInfo(_info(ListVisibility.public, ContributorAuth.loginRequired));
    },
    build: build,
    act: (c) => c.resolve(),
    verify: (c) => expect(statusOf(c), GateStatus.ready),
  );

  blocTest<ListGateCubit, ListGateState>(
    'private, no session → private',
    setUp: () =>
        stubInfo(_info(ListVisibility.private, ContributorAuth.loginRequired)),
    build: build,
    act: (c) => c.resolve(),
    verify: (c) => expect(statusOf(c), GateStatus.private),
  );

  blocTest<ListGateCubit, ListGateState>(
    'private, signed in + allowlisted → ready',
    setUp: () {
      when(() => auth.currentUser).thenReturn(_user);
      stubInfo(_info(ListVisibility.private, ContributorAuth.loginRequired));
      when(() => registry.getPublicList('slug')).thenAnswer(
        (_) async => const PublicList(
          slug: 'slug',
          title: 'T',
          occasion: Occasion.other,
          merchantName: 'M',
          merchantCity: 'C',
          pixKey: 'k',
          pixKeyType: PixKeyType.email,
          items: [],
        ),
      );
    },
    build: build,
    act: (c) => c.resolve(),
    verify: (c) => expect(statusOf(c), GateStatus.ready),
  );

  blocTest<ListGateCubit, ListGateState>(
    'private, signed in but not allowlisted → noAccess',
    setUp: () {
      when(() => auth.currentUser).thenReturn(_user);
      stubInfo(_info(ListVisibility.private, ContributorAuth.loginRequired));
      when(
        () => registry.getPublicList('slug'),
      ).thenThrow(const AccessDeniedException());
    },
    build: build,
    act: (c) => c.resolve(),
    verify: (c) => expect(statusOf(c), GateStatus.noAccess),
  );
}
