# ADR-0001: Cubits-first state, `provider` `MultiRepositoryProvider` DI

- **Status:** Accepted
- **Date:** 2026-07-20

## Context

The sibling project `indexify/mobile_app` — which this repo borrows its
project-definitions conventions from — uses **BLoC + GetIt**. The Gift Registry
spec (§9), however, explicitly prescribes **`provider` + `flutter_bloc`,
cubits-first**, with repositories injected via `MultiRepositoryProvider`. We had to
choose which convention wins for state management and DI.

## Decision

Follow the spec, **not** indexify:

- **State: Cubits only** (`flutter_bloc`). Every feature's state is a `Cubit`. A
  full event-driven `Bloc` is introduced only if a flow becomes genuinely
  event-heavy — none is in the MVP.
- **DI: `provider` `MultiRepositoryProvider`** at the app root. Cubits receive
  repositories as named required constructor params and read them via
  `context.read<T>()`. **No GetIt.**

## Rationale

- The spec is explicit and web-appropriate; deviating would fight the written
  design for no benefit.
- Cubits carry less boilerplate than event-based Blocs — a good fit for an MVP of
  this size (mostly request/response flows, little event fan-in).
- `MultiRepositoryProvider` keeps the swappable-backend goal a **one-line change**
  at the root (mock → Supabase) without a service-locator registry.

## Consequences

- Contributors coming from indexify must remember: **Cubits, not Blocs; `provider`
  DI, not GetIt.** This is called out in `CLAUDE.md`.
- `GiftCubit` is the one future candidate for promotion to a Bloc (if it later
  gains payment polling/retries under a PSP) — and even then a Cubit likely
  suffices.
