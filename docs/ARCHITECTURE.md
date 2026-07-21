# Architecture

This document explains **how the code is organized and why**. The *what* (product
behavior) lives in [`gift-registry-spec.md`](gift-registry-spec.md); the key
*decisions* are recorded as ADRs in [`decisions/`](decisions/).

## Principles

1. **The backend is swappable.** Supabase is an implementation detail hidden
   behind repository interfaces. UI and state never import `supabase_flutter`.
2. **Lighter Clean Architecture.** Layer boundaries where they earn their keep:
   `Repository → domain model → Cubit → UI`. No usecase layer (see
   [ADR-0002](decisions/0002-lighter-repo-cubit-layering.md)).
3. **RLS is the real security boundary.** The Supabase anon key ships in the web
   bundle, so authorization is enforced in Postgres (Row Level Security +
   security-definer RPCs), never only in the client. The client mirrors the rules
   for UX (e.g. locking `private ⇒ login_required`), but Postgres is authoritative.

## Layers

```
┌─────────────────────────────────────────────────────────────┐
│ features/*/presentation   Cubits + pages + widgets + routes  │  UI
├─────────────────────────────────────────────────────────────┤
│ data/repositories         Abstract interfaces                │  contracts
│   ├── mock/               InMemory* (current default)         │
│   └── supabase/           Supabase* (later phase)             │  impls
│ data/models               Domain models + enums (Equatable)   │
│ services/pix              Pure client Pix BR Code service     │
├─────────────────────────────────────────────────────────────┤
│ core/                     config · routing · theme ·          │  infra
│                           formatting · errors · widgets       │
└─────────────────────────────────────────────────────────────┘
```

### Why repositories are central (not per-feature)
The spec defines a small set of **cross-feature** repositories — `AuthRepository`,
`GiftRegistryRepository` (lists + items + allowlist + contributions + public
reads), `StorageRepository`, and the pure `PixPayloadService`. Splitting these per
feature would fragment one cohesive contract, so they live once under `data/` and
`services/`. `features/` folders are therefore **presentation-only**.

## State & DI

- **State: Cubits only** (`flutter_bloc`). One cubit per screen/flow; provided at
  the route via `BlocProvider`. `AuthCubit` is the only root-scoped cubit. See
  [ADR-0001](decisions/0001-cubits-first-provider-di.md).
- **DI: `provider` `MultiRepositoryProvider`** at the app root (`app.dart`). Cubits
  read repos via `context.read<T>()`. Swapping mock → Supabase is a one-line change
  per binding.

## Routing

Single `GoRouter` (`core/routing/app_router.dart`); each feature contributes a
`{feature}_routes.dart` that the router spreads. Two guard styles:

- **Authed dashboard routes** (`/dashboard/**`) require a session.
- **`/l/:slug`** is gated *dynamically*: `ListGateCubit` calls the anon-readable
  `list_access_info(slug)` RPC and resolves to `open | needsLogin | private |
  noAccess | ready`, so an un-authorized visitor sees the right prompt without the
  list's contents leaking.

## Data flow example — a contribution

```
GiftCubit (contribute)
  → GiftRegistryRepository.createContribution(NewContribution)   // awaiting_confirmation, txid, expires_at
  → PixPayloadService.buildCopiaECola(...)                        // EMV TLV + CRC16, client-side
  → UI renders QR (qr_flutter) + copia-e-cola + "I've paid"
      ...creator later...
  ContributionsCubit → GiftRegistryRepository.confirmContribution(id)  // → confirmed
  PublicListCubit progress counts confirmed only
```

## Money & formatting

Money is **integer cents** everywhere (`amount_cents`, BRL). Convert to the dotted
`"0.00"` string **only** at the Pix payload boundary
(`core/formatting/brl_money.dart`). Merchant name/city are ASCII-sanitized and
length-capped (`core/formatting/ascii_sanitize.dart`) before entering the BR Code.

## Testing strategy

- **Pure logic first:** `services/pix` (EMV payload + CRC16) is deterministic and
  unit-tested against known vectors — highest value, zero backend.
- **Cubits:** `bloc_test` + `mocktail`-mocked repositories assert state transitions
  (e.g. `ListEditorCubit` forces `login_required` on `private`; `ListGateCubit`
  emits each gate state; `GiftCubit` walks `form → generating → awaitingPayment →
  done`).
- `test/` mirrors `lib/`. See [`../test/README.md`](../test/README.md).

## Build phases (roadmap)

Mock-backed through phase 7; Supabase in phase 8. Detail in the plan / spec §13.

1. Foundations (models, repo interfaces + mocks, DI, router skeleton)
2. Pix core (EMV + CRC16), test-first
3. Auth + Profile
4. Creator dashboard (lists/editor, items, allowlist)
5. Public list + access gate
6. Contribute flow (QR + copia-e-cola + "I've paid")
7. Contributions inbox + lazy expiry
8. Supabase wiring (schema, RLS, RPCs, storage; swap DI)
9. Polish (image upload/compress, states, partial caps)
