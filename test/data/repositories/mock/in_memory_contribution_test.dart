import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/core/errors/errors.dart';
import 'package:gift_list/data/models/models.dart';
import 'package:gift_list/data/repositories/mock/in_memory_auth_repository.dart';
import 'package:gift_list/data/repositories/mock/in_memory_gift_registry_repository.dart';

void main() {
  late InMemoryGiftRegistryRepository registry;

  setUp(() {
    // 'casa-nova-ana' is public + anonymous, so no sign-in is needed:
    //   item-sofa    → whole item, 250000
    //   item-geladeira → partial, 400000
    registry = InMemoryGiftRegistryRepository(auth: InMemoryAuthRepository());
  });

  NewContribution gift(String itemId, int amount) => NewContribution(
    itemId: itemId,
    listId: 'list-casa-nova',
    giverName: 'Tester',
    amountCents: amount,
  );

  group('createContribution — whole item (allow_partial = false)', () {
    test(
      'accepts the full amount, then reserves against further gifts',
      () async {
        await registry.createContribution(gift('item-sofa', 250000));

        expect(
          () => registry.createContribution(gift('item-sofa', 250000)),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('rejects a partial amount on a whole item', () {
      expect(
        () => registry.createContribution(gift('item-sofa', 100000)),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('createContribution — partial item (allow_partial = true)', () {
    test('accepts amounts up to the remaining, rejects beyond it', () async {
      await registry.createContribution(gift('item-geladeira', 100000));

      // 300000 remaining; 350000 would overshoot.
      expect(
        () => registry.createContribution(gift('item-geladeira', 350000)),
        throwsA(isA<ValidationException>()),
      );

      // A second gift within the remaining is fine.
      final Contribution second = await registry.createContribution(
        gift('item-geladeira', 200000),
      );
      expect(second.amountCents, 200000);
    });
  });

  test('rejects a non-positive amount', () {
    expect(
      () => registry.createContribution(gift('item-geladeira', 0)),
      throwsA(isA<ValidationException>()),
    );
  });
}
