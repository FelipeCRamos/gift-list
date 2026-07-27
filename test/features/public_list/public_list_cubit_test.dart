import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/data/models/models.dart';
import 'package:gift_list/data/repositories/gift_registry_repository.dart';
import 'package:gift_list/features/public_list/presentation/public_list_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockRegistry extends Mock implements GiftRegistryRepository {}

void main() {
  late MockRegistry registry;

  setUp(() => registry = MockRegistry());

  const list = PublicList(
    slug: 'slug',
    title: 'T',
    occasion: Occasion.other,
    merchantName: 'M',
    merchantCity: 'C',
    pixKey: 'k',
    pixKeyType: PixKeyType.email,
    items: [],
  );

  blocTest<PublicListCubit, PublicListState>(
    'load emits [loading, ready] with progress indexed by item id',
    setUp: () {
      when(() => registry.getPublicList('slug')).thenAnswer((_) async => list);
      when(() => registry.publicProgress('slug')).thenAnswer(
        (_) async => const [
          ItemProgress(
            itemId: 'i1',
            targetAmountCents: 1000,
            confirmedCents: 400,
            reservedCents: 0,
            state: ItemState.open,
          ),
        ],
      );
    },
    build: () => PublicListCubit(registry: registry, slug: 'slug'),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<PublicListState>().having(
        (s) => s.status,
        'status',
        PublicListStatus.loading,
      ),
      isA<PublicListState>()
          .having((s) => s.status, 'status', PublicListStatus.ready)
          .having((s) => s.progressFor('i1')?.confirmedCents, 'i1', 400),
    ],
  );
}
