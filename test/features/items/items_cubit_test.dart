import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/data/models/models.dart';
import 'package:gift_list/data/repositories/gift_registry_repository.dart';
import 'package:gift_list/features/items/presentation/items_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockRegistry extends Mock implements GiftRegistryRepository {}

GiftItem _item(String id, int position) => GiftItem(
  id: id,
  listId: 'list-1',
  title: id,
  targetAmountCents: 1000,
  allowPartial: false,
  position: position,
  createdAt: DateTime(2026),
);

void main() {
  late MockRegistry registry;

  setUpAll(() {
    registerFallbackValue(const NewItem(title: 'x', targetAmountCents: 0));
    registerFallbackValue(const ItemUpdate());
  });
  setUp(() => registry = MockRegistry());

  ItemsCubit build() => ItemsCubit(registry: registry, listId: 'list-1');

  blocTest<ItemsCubit, ItemsState>(
    'add appends the created item with a tail position',
    setUp: () {
      when(() => registry.itemsForList('list-1')).thenAnswer((_) async => []);
      when(
        () => registry.addItem(any(), any()),
      ).thenAnswer((_) async => _item('a', 0));
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.add(const NewItem(title: 'a', targetAmountCents: 1000));
    },
    verify: (cubit) {
      expect(cubit.state.items.map((i) => i.id), ['a']);
      final captured =
          verify(() => registry.addItem('list-1', captureAny())).captured.single
              as NewItem;
      expect(captured.position, 0);
    },
  );

  blocTest<ItemsCubit, ItemsState>(
    'reorder moves the item and persists new positions',
    setUp: () {
      when(
        () => registry.itemsForList('list-1'),
      ).thenAnswer((_) async => [_item('a', 0), _item('b', 1), _item('c', 2)]);
      when(
        () => registry.updateItem(any(), any()),
      ).thenAnswer((_) async => _item('x', 0));
    },
    build: build,
    act: (cubit) async {
      await cubit.load();
      await cubit.reorder(0, 3); // move 'a' to the end
    },
    verify: (cubit) {
      expect(cubit.state.items.map((i) => i.id), ['b', 'c', 'a']);
      verify(() => registry.updateItem(any(), any())).called(greaterThan(0));
    },
  );
}
