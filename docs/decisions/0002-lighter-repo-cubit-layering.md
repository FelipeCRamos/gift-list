# ADR-0002: Lighter repo → cubit layering (no usecase layer)

- **Status:** Accepted
- **Date:** 2026-07-20

## Context

`indexify/mobile_app` uses full Clean Architecture: per feature, `data/models` +
`domain/entities` + `domain/usecases` + `domain/repositories` +
`presentation/`. The Gift Registry spec has **no usecase layer** — its cubits talk
to repositories directly. We had to decide how deep the layering goes here.

## Decision

Adopt a **lighter** layering: `Repository → domain model → Cubit → UI`.

- **No usecase layer.** Cubits call repository methods directly.
- **No entity/model split.** One set of **domain models** (Equatable, hand-written
  `fromJson`/`toJson`) in `lib/data/models/`. Repositories return these directly.
- Repositories are **cross-feature** and therefore central (`lib/data/`,
  `lib/services/`), not per-feature. `features/` folders are presentation-only.

## Rationale

- The spec's repository interfaces already express the app's operations at the
  right granularity; wrapping each call in a single-method usecase would add files
  without adding clarity for an MVP this size.
- A separate entity/model pair pays off when the wire format and the domain diverge
  significantly; here they don't, so one hand-written model per concept is simpler
  and still swappable.

## Consequences

- Fewer layers and files than indexify; faster to build and read.
- If domain logic later grows heavy, usecases can be introduced incrementally
  between repositories and cubits without reshaping the model or DI layers.
- No codegen (`freezed`/`json_serializable`) — JSON is hand-written, matching
  indexify's convention.
