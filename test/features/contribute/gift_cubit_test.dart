import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/core/errors/errors.dart';
import 'package:gift_list/data/models/models.dart';
import 'package:gift_list/data/repositories/auth_repository.dart';
import 'package:gift_list/data/repositories/gift_registry_repository.dart';
import 'package:gift_list/features/contribute/presentation/gift_cubit.dart';
import 'package:gift_list/services/payments/payment_instruction.dart';
import 'package:gift_list/services/payments/payment_instruction_service.dart';
import 'package:gift_list/services/payments/payment_request.dart';
import 'package:mocktail/mocktail.dart';

class MockRegistry extends Mock implements GiftRegistryRepository {}

class MockAuth extends Mock implements AuthRepository {}

class MockPayments extends Mock implements PaymentInstructionService {}

GiftItem _item({
  required String id,
  required bool partial,
  required int target,
}) {
  return GiftItem(
    id: id,
    listId: 'L',
    title: 'Item $id',
    targetAmountCents: target,
    allowPartial: partial,
    position: 0,
    createdAt: DateTime(2026),
  );
}

PublicList _list(List<GiftItem> items) => PublicList(
  slug: 'slug',
  title: 'T',
  occasion: Occasion.other,
  merchantName: 'ANA',
  merchantCity: 'SAO PAULO',
  pixKey: 'ana@x.com',
  pixKeyType: PixKeyType.email,
  items: items,
);

ItemProgress _progress({
  required String id,
  required int target,
  int confirmed = 0,
  int reserved = 0,
  ItemState state = ItemState.open,
}) => ItemProgress(
  itemId: id,
  targetAmountCents: target,
  confirmedCents: confirmed,
  reservedCents: reserved,
  state: state,
);

Contribution _contribution(int amount) => Contribution(
  id: 'c1',
  itemId: 'w1',
  listId: 'L',
  giverName: 'Ana',
  amountCents: amount,
  status: ContributionStatus.awaitingConfirmation,
  pixTxid: 'TX123',
  createdAt: DateTime(2026),
  expiresAt: DateTime(2026, 1, 1, 0, 45),
);

void main() {
  late MockRegistry registry;
  late MockAuth auth;
  late MockPayments payments;

  setUpAll(() {
    registerFallbackValue(
      const NewContribution(
        itemId: 'x',
        listId: 'L',
        giverName: 'n',
        amountCents: 1,
      ),
    );
    registerFallbackValue(
      const PaymentRequest(
        amountCents: 1,
        reference: 'r',
        payee: PixPayee(
          pixKey: 'k',
          keyType: PixKeyType.email,
          merchantName: 'M',
          merchantCity: 'C',
        ),
      ),
    );
  });

  setUp(() {
    registry = MockRegistry();
    auth = MockAuth();
    payments = MockPayments();
    when(() => auth.currentUser).thenReturn(null);
  });

  GiftCubit build(String itemId) => GiftCubit(
    registry: registry,
    payments: payments,
    auth: auth,
    slug: 'slug',
    itemId: itemId,
  );

  blocTest<GiftCubit, GiftState>(
    'load emits ready with the remaining amount for an available item',
    setUp: () {
      when(() => registry.getPublicList('slug')).thenAnswer(
        (_) async => _list([_item(id: 'w1', partial: false, target: 60000)]),
      );
      when(
        () => registry.publicProgress('slug'),
      ).thenAnswer((_) async => [_progress(id: 'w1', target: 60000)]);
    },
    build: () => build('w1'),
    act: (c) => c.load(),
    verify: (c) {
      expect(c.state.status, GiftStatus.ready);
      expect(c.state.remainingCents, 60000);
      expect(c.state.item?.id, 'w1');
    },
  );

  blocTest<GiftCubit, GiftState>(
    'load emits unavailable when the item is already complete',
    setUp: () {
      when(() => registry.getPublicList('slug')).thenAnswer(
        (_) async => _list([_item(id: 'w1', partial: false, target: 60000)]),
      );
      when(() => registry.publicProgress('slug')).thenAnswer(
        (_) async => [
          _progress(
            id: 'w1',
            target: 60000,
            confirmed: 60000,
            state: ItemState.complete,
          ),
        ],
      );
    },
    build: () => build('w1'),
    act: (c) => c.load(),
    verify: (c) => expect(c.state.status, GiftStatus.unavailable),
  );

  blocTest<GiftCubit, GiftState>(
    'load emits denied when access is denied',
    setUp: () {
      when(
        () => registry.getPublicList('slug'),
      ).thenThrow(const AccessDeniedException());
    },
    build: () => build('w1'),
    act: (c) => c.load(),
    verify: (c) => expect(c.state.status, GiftStatus.denied),
  );

  blocTest<GiftCubit, GiftState>(
    'submit walks ready → submitting → awaitingPayment with a Pix instruction',
    setUp: () {
      when(() => registry.getPublicList('slug')).thenAnswer(
        (_) async => _list([_item(id: 'w1', partial: false, target: 60000)]),
      );
      when(
        () => registry.publicProgress('slug'),
      ).thenAnswer((_) async => [_progress(id: 'w1', target: 60000)]);
      when(
        () => registry.createContribution(any()),
      ).thenAnswer((_) async => _contribution(60000));
      when(
        () => payments.build(any()),
      ).thenReturn(const PixInstruction(copiaECola: 'PIXCODE'));
    },
    build: () => build('w1'),
    act: (c) async {
      await c.load();
      await c.submit(giverName: 'Ana', amountCents: 60000);
    },
    verify: (c) {
      expect(c.state.status, GiftStatus.awaitingPayment);
      expect(c.state.instruction, isA<PixInstruction>());
      expect(c.state.contribution?.pixTxid, 'TX123');
      verify(() => registry.createContribution(any())).called(1);
    },
  );

  blocTest<GiftCubit, GiftState>(
    'submit returns to ready with the reason when the repository rejects it',
    setUp: () {
      when(() => registry.getPublicList('slug')).thenAnswer(
        (_) async => _list([_item(id: 'w1', partial: false, target: 60000)]),
      );
      when(
        () => registry.publicProgress('slug'),
      ).thenAnswer((_) async => [_progress(id: 'w1', target: 60000)]);
      when(() => registry.createContribution(any())).thenThrow(
        const ValidationException('This item is no longer available.'),
      );
    },
    build: () => build('w1'),
    act: (c) async {
      await c.load();
      await c.submit(giverName: 'Ana', amountCents: 60000);
    },
    verify: (c) {
      expect(c.state.status, GiftStatus.ready);
      expect(c.state.errorMessage, 'This item is no longer available.');
    },
  );
}
