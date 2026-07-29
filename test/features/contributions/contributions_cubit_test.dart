import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/data/models/models.dart';
import 'package:gift_list/data/repositories/gift_registry_repository.dart';
import 'package:gift_list/features/contributions/presentation/contributions_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockRegistry extends Mock implements GiftRegistryRepository {}

GiftList _list() => GiftList(
  id: 'L',
  ownerId: 'owner',
  slug: 'slug',
  title: 'Casa Nova',
  occasion: Occasion.newHome,
  pixKey: 'k',
  pixKeyType: PixKeyType.email,
  merchantName: 'M',
  visibility: ListVisibility.public,
  contributorAuth: ContributorAuth.anonymous,
  isPublished: true,
  createdAt: DateTime(2026),
);

Contribution _c(String id, ContributionStatus status) => Contribution(
  id: id,
  itemId: 'i',
  listId: 'L',
  giverName: 'Giver $id',
  amountCents: 5000,
  status: status,
  pixTxid: 'TX$id',
  createdAt: DateTime(2026),
  expiresAt: DateTime(2026, 1, 1, 1),
);

void main() {
  late MockRegistry registry;

  setUp(() {
    registry = MockRegistry();
    when(() => registry.getMyList('L')).thenAnswer((_) async => _list());
  });

  ContributionsCubit build() =>
      ContributionsCubit(registry: registry, listId: 'L');

  blocTest<ContributionsCubit, ContributionsState>(
    'load groups rows and exposes the list title',
    setUp: () {
      when(() => registry.contributionsForList('L')).thenAnswer(
        (_) async => [
          _c('1', ContributionStatus.awaitingConfirmation),
          _c('2', ContributionStatus.confirmed),
          _c('3', ContributionStatus.expired),
        ],
      );
    },
    build: build,
    act: (c) => c.load(),
    verify: (c) {
      expect(c.state.status, ContributionsStatus.ready);
      expect(c.state.listTitle, 'Casa Nova');
      expect(c.state.awaiting.map((e) => e.id), ['1']);
      expect(c.state.confirmed.map((e) => e.id), ['2']);
      expect(c.state.closed.map((e) => e.id), ['3']);
    },
  );

  blocTest<ContributionsCubit, ContributionsState>(
    'confirm calls the repository then reloads with the new status',
    setUp: () {
      final Contribution awaiting = _c(
        '1',
        ContributionStatus.awaitingConfirmation,
      );
      final Contribution confirmed = _c('1', ContributionStatus.confirmed);
      var didConfirm = false;
      when(() => registry.confirmContribution('1')).thenAnswer((_) async {
        didConfirm = true;
      });
      when(
        () => registry.contributionsForList('L'),
      ).thenAnswer((_) async => [if (didConfirm) confirmed else awaiting]);
    },
    build: build,
    act: (c) async {
      await c.load();
      await c.confirm('1');
    },
    verify: (c) {
      verify(() => registry.confirmContribution('1')).called(1);
      expect(c.state.confirmed.map((e) => e.id), ['1']);
      expect(c.state.awaiting, isEmpty);
      expect(c.state.isBusy('1'), isFalse);
    },
  );

  blocTest<ContributionsCubit, ContributionsState>(
    'reject calls the repository',
    setUp: () {
      when(() => registry.rejectContribution('1')).thenAnswer((_) async {});
      when(
        () => registry.contributionsForList('L'),
      ).thenAnswer((_) async => [_c('1', ContributionStatus.cancelled)]);
    },
    build: build,
    act: (c) async {
      await c.load();
      await c.reject('1');
    },
    verify: (c) {
      verify(() => registry.rejectContribution('1')).called(1);
      expect(c.state.closed.map((e) => e.id), ['1']);
    },
  );
}
