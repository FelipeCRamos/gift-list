# ADR-0003: Mock-first backend, Supabase later

- **Status:** Accepted
- **Date:** 2026-07-20

## Context

The app targets Supabase (Postgres + Auth + Storage + RLS). We could stand Supabase
up first and build against the real backend, or build the UI against in-memory
mock repositories and wire Supabase in a later phase. Repositories are already
abstracted behind interfaces either way.

## Decision

**Build mock-first.** Ship in-memory `InMemory*` repository implementations seeded
with sample data, build the entire UI and cubit layer against them, then implement
the `Supabase*` repositories (plus SQL migrations, RLS, and RPCs) in a dedicated
later phase and swap the DI bindings at the app root.

## Rationale

- No Supabase project or credentials are needed to start building — work begins
  immediately.
- Forces the repository abstraction to be honest: if the UI can run entirely on
  mocks, the backend really is swappable.
- Cubit tests use `mocktail`-mocked repos regardless, so mock-first aligns with the
  test strategy.
- Isolates backend concerns (RLS policy design, security-definer RPCs, the two
  `CHECK` constraints, storage policies) into one focused phase instead of
  interleaving them with UI work.

## Consequences

- Some behavior only Postgres can enforce (RLS, access-aware PII-free progress) is
  **simulated** in the mocks; the real guarantees arrive in the Supabase phase, and
  the RLS rules — not the client — remain authoritative (see
  [ARCHITECTURE.md](../ARCHITECTURE.md)).
- A `.env.example` documents the eventual `SUPABASE_URL` / `SUPABASE_ANON_KEY`
  configuration ahead of that phase.
