# Gift Registry

Let your family and friends send you gifts that you want!

A generic, non-monetized **gift registry** web app. A creator builds a list of
desired gifts for any occasion; contributors pick an item and pay the creator
**directly via Pix**. The platform never touches money — no PSP, no server, no
webhooks.

> **Contributors & agents:** read [`CLAUDE.md`](CLAUDE.md) first — it is the
> architecture + conventions guide. The full product spec is
> [`docs/gift-registry-spec.md`](docs/gift-registry-spec.md).

## Environment

| Tool     | Version  | Notes                                      |
| -------- | -------- | ------------------------------------------ |
| Flutter  | `3.44.7` | pinned in `.fvmrc`                         |
| Dart     | `3.12`   | ships with Flutter                         |
| Target   | Web      | Chrome for development                     |
| Backend  | Supabase | behind repository interfaces; mocked today |

## Architecture at a glance

- **Flutter Web** frontend; **Supabase** backend hidden behind repository
  interfaces (swappable). Runs against **in-memory mocks** today.
- **Cubits-first** (`flutter_bloc`) for state; **`provider` `MultiRepositoryProvider`**
  for DI. No usecase layer — cubits call repositories directly.
- **`go_router`** for routing (public + authed + gated routes).
- Client-side **Pix BR Code** generation (EMV + CRC16); no third-party calls.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and
[`docs/decisions/`](docs/decisions/) for the reasoning.

## Development setup

```bash
flutter pub get
./scripts/glist run          # launches the web app in Chrome (mock backend)
```

No credentials are required today — the app boots against seeded in-memory
repositories. When Supabase is wired up, copy `.env.example` → `.env` and fill in
`SUPABASE_URL` / `SUPABASE_ANON_KEY` (injected via `--dart-define`).

## Common commands

```bash
./scripts/glist run        # run in Chrome
./scripts/glist build      # build web release
./scripts/glist analyze    # static analysis (run after every change)
./scripts/glist format     # format
./scripts/glist test       # run tests
```

## Layout

```
lib/core/        cross-cutting infra (config, routing, theme, formatting, errors, widgets)
lib/data/        domain models + repository interfaces + mock/supabase impls
lib/services/    pure client services (Pix BR Code generation)
lib/features/    presentation per feature (cubit + pages + widgets + routes)
docs/            spec, architecture, decision records
scripts/glist    developer CLI
```
