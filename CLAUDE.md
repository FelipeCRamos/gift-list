# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) — and any other AI
agent or human contributor — when working with code in this repository.

## Project Overview

**Gift Registry** is a generic, non-monetized gift registry **web app**. A
*creator* signs in and builds a list of desired gifts for any occasion; a
*contributor* opens the list, picks an item, and pays the creator **directly via
Pix** using a Pix key the creator provides. **The platform never touches money** —
there is no PSP, no custom server, no webhooks.

- Product spec (source of truth): [`docs/gift-registry-spec.md`](docs/gift-registry-spec.md)
- Architecture detail: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Decision records: [`docs/decisions/`](docs/decisions/)

## Environment

- **Flutter** `3.44.7` (pinned in `.fvmrc`), **Dart** `3.12`.
- Target: **Flutter Web first** (Chrome for dev).
- Package name: `gift_list`.
- Backend: **Supabase** (Postgres + Auth + Storage + RLS), always **hidden behind
  repository interfaces** so it can be swapped. Currently the app runs against
  **in-memory mock repositories**; Supabase implementations land in a later phase.

## Development Commands

Use the `scripts/glist` CLI (self-documenting — run `./scripts/glist` for usage):

```bash
./scripts/glist run        # flutter run -d chrome (+ --dart-define env)
./scripts/glist build      # flutter build web
./scripts/glist analyze    # flutter analyze
./scripts/glist test       # flutter test
./scripts/glist format      # dart format .
```

- **Always run `./scripts/glist analyze` after making code changes** and resolve
  every issue — the analyzer is configured strict (see Code Style).
- **Always run `./scripts/glist format`** before considering a change done.
- Prefer **separate `StatelessWidget` / `StatefulWidget` classes** over private
  `_buildX()` widget-returning methods.

## Keep documentation in sync (required)

**Whenever you change a rule/convention or implement a new flow, update the docs in
the same change — never leave them stale.** Documentation is part of "done", not a
follow-up.

- **Changed a rule, convention, or constraint** (state/DI/layering rules, naming,
  access-control invariants, the Pix flow, code style) → update **`CLAUDE.md`**, and
  **`docs/ARCHITECTURE.md`** if the structure or data flow shifts.
- **A decision reversed or a new significant choice made** → add or supersede an
  **ADR** in `docs/decisions/` (`NNNN-title.md`; mark the old one `Superseded by …`).
- **Implemented a new flow / feature / screen** → reflect it where it belongs:
  the cubit→feature map and "Adding a feature" recipe in `CLAUDE.md`, the phase
  roadmap / data-flow in `docs/ARCHITECTURE.md`, and product behavior in
  `docs/gift-registry-spec.md` if the behavior itself changed.
- **Added a `scripts/glist` subcommand, dependency, or env var** → update its usage
  block, `README.md` commands, and `.env.example` as applicable.

If a change makes any existing doc statement wrong, fix that statement in the same
change. When unsure which file, prefer `CLAUDE.md` for conventions and
`docs/ARCHITECTURE.md` for structure.

## Architecture

**Lighter Clean Architecture, cubits-first.** Repositories are cross-feature, so
they live in a central `data/` layer; `features/` folders are **presentation-only**
(cubit + pages + widgets + routes). There is **no usecase layer** — cubits call
repositories directly.

```
lib/
  main.dart                 # bootstrap: env, (later) Supabase.init, runApp
  app.dart                  # MultiRepositoryProvider + root AuthCubit + MaterialApp.router
  core/
    config/                 # AppConfig / env (Supabase url + anon key via --dart-define)
    routing/                # app_router.dart (go_router), guards, path constants
    theme/                  # design system (GlTheme, colors, text theme) — Gl-prefixed
    formatting/             # brl_money.dart (cents<->"0.00"), ascii_sanitize.dart
    errors/                 # AccessDeniedException, RepositoryException, ...
    widgets/                # shared cross-feature widgets (barrel export)
  data/
    models/                 # domain models + enums (Equatable, hand-written JSON)
    repositories/           # abstract interfaces
      mock/                 # InMemory* implementations (current default)
      supabase/             # Supabase* implementations (later phase)
  services/
    pix/                    # PixPayloadService (EMV BR Code + CRC16) — pure, no backend
  features/
    auth/ profile/ lists/ allowlist/ items/
    public_list/ contribute/ contributions/
      presentation/         # {feature}_cubit.dart, pages/, widgets/, {feature}_routes.dart
supabase/                   # SQL migrations (schema, RLS, RPCs) — later phase
```

### State management — **Cubits only** (`flutter_bloc`)
Everything is a `Cubit` in this MVP; do **not** introduce a full event-driven
`Bloc` unless a flow becomes genuinely event-heavy (none is today). Cubits take
their repositories as **named required constructor params**. Feature cubits are
provided at the **route level** via `BlocProvider`; the only root-scoped cubit is
`AuthCubit`.

Cubit → feature map: `AuthCubit` (root) · `ProfileCubit` · `ListsCubit` +
`ListEditorCubit` (lists) · `AllowlistCubit` · `ItemsCubit` · `ListGateCubit` +
`PublicListCubit` (public_list) · `GiftCubit` (contribute) · `ContributionsCubit`.

### Dependency injection — **`provider` `MultiRepositoryProvider`**
Repositories are injected once at the app root in `app.dart`. Cubits read them
with `context.read<T>()`. **Do not** use GetIt. Swapping the backend = swapping
one binding (mock → Supabase) at the root.

```dart
MultiRepositoryProvider(
  providers: [
    RepositoryProvider<AuthRepository>(create: (_) => InMemoryAuthRepository()),
    RepositoryProvider<GiftRegistryRepository>(create: (_) => InMemoryGiftRegistryRepository()),
    RepositoryProvider<StorageRepository>(create: (_) => InMemoryStorageRepository()),
    RepositoryProvider<PixPayloadService>(create: (_) => const EmvPixPayloadService()),
  ],
  child: BlocProvider(create: (c) => AuthCubit(authRepository: c.read()), child: const _App()),
)
```

### Routing — `go_router`
Single `GoRouter` in `core/routing/app_router.dart`. Each feature exposes a
`{feature}_routes.dart` with `static final List<GoRoute> routes` and path
constants; the central router spreads them. Authed dashboard routes require a
session; `/l/:slug` is gated dynamically per the list's visibility/auth settings.

### Data flow
`Repository → domain model → Cubit → UI`. Repositories return **domain models**
(never raw DB rows). Money is **always integer cents** (`amount_cents`); format to
`"0.00"` **only** at the Pix payload boundary (`core/formatting/brl_money.dart`).

## Domain: two things to internalize

### Access control (spec §2) — two orthogonal axes
- **Visibility:** `public` (anyone with the link) or `private` (allowlisted
  email/phone only).
- **Contributor auth:** `anonymous` (type a name) or `login_required` (must sign in).
- **Invariant: `private ⇒ login_required`.** `private + anonymous` is invalid,
  enforced in **two places**: a DB `CHECK` constraint *and* the UI (when the
  creator picks `private`, the auth toggle is forced+locked to `login_required`).
  `ListEditorCubit` enforces this client-side.
- The `/l/:slug` gate resolves to one of: `open | needsLogin | private | noAccess |
  ready` (`ListGateCubit`), using the anon-readable `list_access_info(slug)` RPC so
  the UI can show the *right* prompt without leaking list content.

### Pix payment (spec §3, §7) — honor-based, client-side
- A static Pix key produces **no webhook**. Confirmation is two-step: contributor
  taps **"I've paid"** (`awaiting_confirmation`) → creator verifies their bank
  statement and **confirms** (`confirmed`). **Progress counts confirmed only.**
- The "Pix Copia e Cola" (EMV®MPM BR Code) is built **entirely client-side** in
  `services/pix/` — TLV fields + **CRC-16/CCITT-FALSE**. Deterministic, offline,
  **never call a third-party service**. Sanitize merchant name/city to ASCII and
  enforce max lengths (some banks reject non-conforming payloads).

## Code Style

- Analyzer is strict (`analysis_options.yaml`, the Flutter framework ruleset):
  `strict-casts` + `strict-inference` on; `formatter.page_width: 80`.
- **Single quotes** (`prefer_single_quotes`), **relative imports** within `lib/`
  (`prefer_relative_imports`), trailing commas, `prefer_const_constructors`,
  `sort_constructors_first`, `always_declare_return_types`, no `print`
  (`avoid_print`), `use_key_in_widget_constructors`.
- Models extend `Equatable` for value equality; JSON is **hand-written**
  `fromJson`/`toJson` (no `freezed`/`json_serializable`, no codegen).

### Naming conventions
- Files/folders: `snake_case`. Classes: `PascalCase`. Private: `_leading`.
- Layer suffixes: `*_repository.dart` (interface), `*_repository_impl` lives under
  `data/repositories/{mock,supabase}/`; `*_cubit.dart` / `*_state.dart`;
  `{feature}_routes.dart`.
- Design-system widgets: `gl_*_widget.dart` with `Gl`-prefixed classes
  (`GlTheme`, `GlPrimaryButton`, …), barrel-exported.

## Important Patterns

### Adding a feature (the recipe)
1. Add/extend domain **models + enums** in `lib/data/models/`.
2. Add methods to the relevant **repository interface** in
   `lib/data/repositories/` (usually `GiftRegistryRepository`).
3. Implement them in the **mock** impl (`repositories/mock/`) — and later the
   Supabase impl (`repositories/supabase/`).
4. Create the **cubit** (`features/{f}/presentation/{f}_cubit.dart`) + its state,
   taking repos as named required params.
5. Build **pages/widgets**; provide the cubit via `BlocProvider` at the route.
6. Register routes in `features/{f}/presentation/{f}_routes.dart` and spread them
   into `core/routing/app_router.dart`.
7. Write **cubit tests** (`bloc_test` + `mocktail`) and any pure-logic unit tests.
8. **Update the docs** for anything new or changed (see "Keep documentation in
   sync") — the cubit→feature map, the phase roadmap, ADRs, etc.
9. `./scripts/glist analyze && ./scripts/glist format && ./scripts/glist test`.

### Repository / Cubit rules
- Repositories return domain models and throw typed errors (`core/errors/`);
  cubits translate errors into states, never leak exceptions to the UI.
- Access-aware reads (public list progress) must be **PII-free** — never surface
  other givers' names/messages to contributors.

## Testing
`test/` mirrors `lib/`; files end `_test.dart`; **mocktail** for mocks (no codegen),
**bloc_test** for cubits; `group(...)` + `'returns X when Y'` naming. See
[`test/README.md`](test/README.md).

## Deferred (not in the MVP — see spec §12)
Phone/SMS allowlist (costs money — email-only free path for now); card/installments
& PSP dynamic Pix auto-confirm; signed-URL private images.
