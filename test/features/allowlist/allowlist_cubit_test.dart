import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift_list/data/models/models.dart';
import 'package:gift_list/data/repositories/gift_registry_repository.dart';
import 'package:gift_list/features/allowlist/presentation/allowlist_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockRegistry extends Mock implements GiftRegistryRepository {}

void main() {
  late MockRegistry registry;

  setUpAll(() => registerFallbackValue(<AllowlistEntry>[]));
  setUp(() => registry = MockRegistry());

  AllowlistCubit build() =>
      AllowlistCubit(registry: registry, listId: 'list-1');

  blocTest<AllowlistCubit, AllowlistState>(
    'addEmail normalizes, persists, and reloads',
    setUp: () {
      when(() => registry.getAllowlist('list-1')).thenAnswer((_) async => []);
      when(() => registry.setAllowlist(any(), any())).thenAnswer((_) async {});
      when(() => registry.getAllowlist('list-1')).thenAnswer(
        (_) async => const [AllowlistEntry(id: '1', email: 'guest@x.com')],
      );
    },
    build: build,
    act: (cubit) => cubit.addEmail('  GUEST@x.com '),
    verify: (cubit) {
      final captured =
          verify(
                () => registry.setAllowlist('list-1', captureAny()),
              ).captured.single
              as List<AllowlistEntry>;
      expect(captured.single.email, 'guest@x.com');
      expect(cubit.state.entries.single.email, 'guest@x.com');
    },
  );

  blocTest<AllowlistCubit, AllowlistState>(
    'addEmail is a no-op for a duplicate',
    seed: () => const AllowlistState(
      status: AllowlistStatus.ready,
      entries: [AllowlistEntry(id: '1', email: 'guest@x.com')],
    ),
    build: build,
    act: (cubit) => cubit.addEmail('guest@x.com'),
    verify: (_) => verifyNever(() => registry.setAllowlist(any(), any())),
  );
}
