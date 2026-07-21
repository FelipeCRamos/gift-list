# Tests

`test/` **mirrors `lib/`** — a file under `lib/x/y.dart` is tested by
`test/x/y_test.dart`.

## Conventions

- File names end with `_test.dart`.
- **Mocks: [`mocktail`](https://pub.dev/packages/mocktail)** — no codegen. Mock
  repositories by implementing their interface via `class MockX extends Mock
  implements XRepository {}`.
- **Cubits: [`bloc_test`](https://pub.dev/packages/bloc_test)** — assert state
  transitions with `blocTest(...)`, `expect: [...]`.
- Group with `group('<unit>', ...)`; name cases `'returns X when Y'` /
  `'emits [A, B] when Z'`.
- Keep shared fixtures/builders in `test/helpers/`.

## What to test where

| Area | Priority | How |
| --- | --- | --- |
| `services/pix` (EMV payload + CRC16) | **highest** — pure, deterministic | unit tests against known BR Code / CRC vectors |
| `core/formatting` (BRL cents↔display, ASCII sanitize) | high | table-driven unit tests |
| Cubits (`features/**`) | high | `bloc_test` + `mocktail`-mocked repositories |
| Widgets/pages | as needed | widget tests for gate rendering, form validation |

Example cubit expectations to cover:
- `ListEditorCubit` forces + locks `contributor_auth = login_required` when
  visibility is set to `private`.
- `ListGateCubit` emits each of `open | needsLogin | private | noAccess | ready`.
- `GiftCubit` walks `form → generating → awaitingPayment → done` (and `→ error`).

## Running

```bash
./scripts/glist test                 # all tests
./scripts/glist test test/services   # a subtree
flutter test --coverage              # with coverage
```
