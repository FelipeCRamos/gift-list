# Gift Registry — System Outline (Flutter Web + Supabase, Pix-only MVP)

## 1. Overview

A generic, non-monetized gift registry web app. A **creator** logs in and builds a list of desired gifts for any occasion (new home, birthday, wedding, baby shower, etc.). Each item has a target amount. **Contributors** open the list, pick an item, and pay the creator **directly via Pix** using a Pix key the creator provides. The platform never touches money.

Access to a list is configurable by the creator (see §2): a list can be public or private, and can allow anonymous contributions or require contributors to sign in.

### Goals
- Generic across occasions (occasion is just metadata + theme).
- Zero payment intermediation: money flows contributor → creator's Pix key directly.
- Minimal infrastructure: no PSP, no custom backend server, no webhooks.
- Flutter Web frontend + Supabase (Postgres, Auth, Storage, RLS) as the only backend, **abstracted behind a repository layer** so it can be swapped.

### Non-goals (for this MVP)
- No credit card / installments (Pix only for now).
- No automatic payment confirmation (Pix static key gives no webhook — confirmation is manual/honor-based; see §6).
- No fund custody, no split, no marketplace logic → no Bacen payment-arranger exposure.

## 2. Access Control Model (NEW — read carefully)

Two **orthogonal** axes, both set by the creator per list:

### Axis A — Visibility (who is allowed)
- `public`: anyone with the link.
- `private`: only people whose verified email or phone is on the list's **allowlist**.

### Axis B — Contributor authentication (login or not)
- `anonymous`: contributors don't log in; they type a display name when contributing.
- `login_required`: contributors must be signed in **to view and to contribute**.

### Valid combinations
| Visibility | Contributor auth | View access | Contribute |
|-----------|------------------|-------------|-----------|
| public | anonymous | anyone with link, no login | anyone, types name |
| public | login_required | any signed-in user | any signed-in user |
| private | login_required | signed-in users on the allowlist (+ owner) | same |
| private | anonymous | **INVALID** | — |

**Rule:** `private` implies `login_required`. You cannot enforce an email/phone allowlist without authenticating the person, so `private + anonymous` is rejected (DB CHECK constraint + app-level validation). When the creator picks `private`, the UI forces and locks the auth toggle to `login_required`.

`is_published` remains a separate, orthogonal flag: an unpublished list is a draft visible only to its owner, regardless of visibility/auth settings.

### Auth cost caveat (relevant to the hobby budget)
- **Email / magic-link auth is free** on Supabase → use email for both creator and contributor sign-in, and allowlist **by email** as the default free path.
- **Phone (SMS OTP) auth requires a paid SMS provider** (Twilio/MessageBird, etc.) and breaks the R$0 budget. Allowlist-by-phone is therefore **optional** and only works if SMS auth is wired up. Default the MVP to email-only; treat phone as a later add-on.

## 3. Core Payment Model (Pix static "Copia e Cola")

The creator stores a Pix key (email, phone, CPF/CNPJ, or random EVP key) per list. When a contributor chooses an item, the app **generates a Pix BR Code (EMV payload) entirely on the client**, encoding the creator's key + amount + a reference id. The contributor scans the QR (or copies the "copia e cola" string) and pays in their own bank app. Money lands directly in the creator's account.

A static Pix key produces **no payment webhook**, so payment is confirmed with a two-step honor flow:
1. Contributor taps **"I've paid"** → contribution moves to `awaiting_confirmation`.
2. Creator checks their bank statement and **confirms** (or rejects) → contribution moves to `confirmed`. Item progress is computed from confirmed contributions only.

Accepted limitation of Pix-only + no PSP. (Future: PSP dynamic Pix for auto-confirmation — see §12.)

## 4. Tech Stack

- **Flutter Web** (web-first).
- **Supabase**: Postgres + Auth (email/password + magic link; phone optional) + Storage (images) + Row Level Security. **Default backend, hidden behind repositories** (§9) so Firebase or a self-hosted Supabase can be swapped without touching UI/state.
- State management: **`provider` + `flutter_bloc`, cubits-first.** Use Cubits for all feature state; promote to a full event-driven Bloc only if a flow becomes genuinely event-heavy (none in this MVP). See §9.
- Packages:
  - `supabase_flutter` — client + auth (used only inside the Supabase repository implementations).
  - `flutter_bloc` + `provider` — state + DI.
  - `go_router` — routing (public + authed + gated routes).
  - `qr_flutter` — render the BR Code as a QR image.
- No custom server. Logic = Flutter client + Postgres RLS + a few Postgres functions/views.

## 5. Data Model (Postgres)

Money is stored as integer cents (`amount_cents`), currency always BRL. Format to `"0.00"` only at the Pix-payload boundary.

### `profiles`
Extends `auth.users` (1:1, `id = auth.uid()`). Every authenticated user gets one — creators **and** signed-in contributors. Pix fields stay null for pure contributors.
- `id` uuid PK (FK → auth.users)
- `display_name` text
- `default_pix_key` text (nullable)
- `pix_key_type` text enum: `email | phone | cpf | cnpj | evp` (nullable)
- `merchant_city` text (ASCII, ≤15 chars; nullable)
- `created_at` timestamptz default now()

### `lists`
- `id` uuid PK default gen_random_uuid()
- `owner_id` uuid FK → profiles.id
- `slug` text UNIQUE — public URL segment
- `title` text
- `occasion` text enum: `new_home | birthday | wedding | baby | graduation | other`
- `description` text (nullable)
- `cover_image_url` text (nullable)
- `pix_key` text — Pix key for THIS list (prefill from profile, overridable)
- `pix_key_type` text enum (same values as profile)
- `merchant_name` text — name shown in the BR Code (ASCII, ≤25 chars)
- `visibility` text enum: `public | private` — default `public`
- `contributor_auth` text enum: `anonymous | login_required` — default `anonymous`
- `event_date` date (nullable)
- `is_published` boolean default false
- `created_at` timestamptz default now()
- **CHECK constraint:** `NOT (visibility = 'private' AND contributor_auth = 'anonymous')`

### `list_allowlist` (NEW)
One row per permitted contact for a `private` list.
- `id` uuid PK default gen_random_uuid()
- `list_id` uuid FK → lists.id (on delete cascade)
- `email` text (nullable, lowercased)
- `phone` text (nullable, E.164)
- `created_at` timestamptz default now()
- **CHECK constraint:** `email IS NOT NULL OR phone IS NOT NULL`
- Index on `(list_id, email)` and `(list_id, phone)` for fast membership checks.

### `items`
- `id` uuid PK default gen_random_uuid()
- `list_id` uuid FK → lists.id (on delete cascade)
- `title` text
- `description` text (nullable)
- `image_url` text (nullable)
- `target_amount_cents` integer
- `allow_partial` boolean default false — true = contributors may give a partial amount (quota/"cotas" style); false = single full-amount contribution
- `position` integer default 0
- `created_at` timestamptz default now()

Item completion is derived: `sum(confirmed contributions) >= target_amount_cents`. Exposed via the access-aware progress RPC (§6/§8).

### `contributions`
- `id` uuid PK default gen_random_uuid()
- `item_id` uuid FK → items.id (on delete cascade)
- `list_id` uuid — denormalized FK → lists.id (simplifies RLS)
- `contributor_id` uuid (nullable) FK → auth.users — **set when the contributor is signed in; null when anonymous**
- `giver_name` text — typed for anonymous; prefilled from profile for signed-in users, still stored here
- `giver_message` text (nullable)
- `amount_cents` integer
- `status` text enum: `awaiting_confirmation | confirmed | cancelled | expired`
- `pix_txid` text — reference embedded in the BR Code (§7), for the creator to cross-check
- `created_at` timestamptz default now()
- `confirmed_at` timestamptz (nullable)
- `expires_at` timestamptz — soft reservation TTL (e.g. now() + 45 min)

### Relationships
`profiles 1—* lists 1—* items 1—* contributions`; `lists 1—* list_allowlist`. `contributions.list_id` and `contributions.contributor_id` denormalized/added for RLS.

## 6. Security Model (RLS + functions) — substantially expanded

RLS is the real boundary (the anon key ships in the web bundle). Enable RLS on all tables. Supabase exposes the caller identity via `auth.uid()`, `auth.jwt() ->> 'email'`, and `auth.jwt() ->> 'phone'` — use these for allowlist checks.

### Helper: `has_list_access(list_id)` (SQL function, security-definer)
Returns true if the current caller may **view** the given list. Logic:
- Owner (`lists.owner_id = auth.uid()`) → true.
- List not published → false (for non-owners).
- `visibility = 'public'`:
  - `contributor_auth = 'anonymous'` → true (anon or authed).
  - `contributor_auth = 'login_required'` → true only if `auth.uid() IS NOT NULL`.
- `visibility = 'private'` → true only if authenticated AND an allowlist row matches `auth.jwt()->>'email'` or `auth.jwt()->>'phone'`.

Use this helper inside the policies/RPCs below to avoid duplicating logic.

### Table policies
- **profiles**: caller can select/update own row (`auth.uid() = id`). No public read.
- **lists**:
  - `SELECT`: `has_list_access(id)` true.
  - Owner full CRUD (`owner_id = auth.uid()`).
- **list_allowlist**: only the list owner can select/insert/update/delete (`EXISTS (select 1 from lists where lists.id = list_id and lists.owner_id = auth.uid())`). Contributors never read the allowlist.
- **items**:
  - `SELECT`: `has_list_access(list_id)` true.
  - Owner full CRUD on items of own lists.
- **contributions**:
  - `INSERT` (WITH CHECK): parent list is published, `has_list_access(list_id)` is true, AND the contribution respects the auth mode:
    - if the list is `login_required` (incl. all private lists): require `auth.uid() IS NOT NULL` and set `contributor_id = auth.uid()`.
    - if `anonymous`: allow `anon` role; `contributor_id` must be null.
    - status must be `awaiting_confirmation`.
  - `SELECT`/`UPDATE`/`DELETE`: only the list owner (to confirm/reject/thank). Contributors do **not** read the contributions table (PII of others). A signed-in contributor MAY read **their own** rows (`contributor_id = auth.uid()`) if you want a "my gifts" view — optional.

### Access-aware progress (no PII leak)
Contributors must see per-item progress (open / reserved / complete) but never other givers' names/messages. Provide a **security-definer RPC** `public_item_progress(list_slug)` that:
1. Resolves the list by slug.
2. Internally enforces `has_list_access(list.id)` — returns empty/error if the caller lacks access (this is how private/login-gated progress stays hidden).
3. Returns per item: `target_amount_cents`, `confirmed_cents`, `reserved_cents` (sum of non-expired `awaiting_confirmation`), derived `state` (`open | reserved | complete`). No names, no messages.

### Pre-auth gate metadata (so the UI can render the right prompt)
Problem: if a list is `login_required` or `private`, an anonymous visitor can't read it — but the app still needs to know *why* to show "Please sign in" vs "This list is private" instead of a blank error. Provide a **public** (anon-readable) security-definer RPC `list_access_info(slug)` returning only non-sensitive gate metadata: `{ exists, title, cover_image_url, visibility, contributor_auth }` — **no items, no amounts, no allowlist**. The client calls this first to decide the gate; the actual content read is still governed by the policies above.

### Reservation / double-gift handling (unchanged)
- `allow_partial = false`: a live `awaiting_confirmation` contribution reserves the item for the TTL; progress reports `reserved` and the contribute button is disabled. If unconfirmed, `expires_at` passes and it reopens.
- `allow_partial = true`: accumulate multiple contributions; optionally cap so `reserved + confirmed` ≤ target.
- Prefer **lazy expiry** (treat `awaiting_confirmation` with `expires_at < now()` as expired at read time) to avoid depending on pg_cron on the free tier.

## 7. Pix BR Code Generation (client-side) — implement carefully

The "Pix Copia e Cola" string is an **EMV®MPM** payload: TLV fields `ID(2) + LEN(2, zero-padded) + VALUE`, ending with a CRC16. Build a `PixPayloadService`. Deterministic and offline — **do not** call any third-party service.

### Required fields (in order)
| ID | Name | Value |
|----|------|-------|
| 00 | Payload Format Indicator | `01` |
| 01 | Point of Initiation Method | `12` (single-use; amount is fixed) |
| 26 | Merchant Account Info (Pix) | nested: `00`=`br.gov.bcb.pix`, `01`=creator Pix key |
| 52 | Merchant Category Code | `0000` |
| 53 | Transaction Currency | `986` (BRL) |
| 54 | Transaction Amount | e.g. `150.00` (cents/100, dot decimal, 2 places) |
| 58 | Country Code | `BR` |
| 59 | Merchant Name | list `merchant_name`, ASCII, ≤25 chars |
| 60 | Merchant City | `merchant_city`, ASCII, ≤15 chars |
| 62 | Additional Data Field | nested: subfield `05` = reference id (txid) |
| 63 | CRC16 | 4 uppercase hex chars, computed last |

- Field 62 subfield `05` (txid): match `^[A-Za-z0-9]{1,25}$`. Generate per contribution (e.g. first 10 hex of a UUID, uppercased), store in `contributions.pix_txid`. Caveat: whether it surfaces in the creator's statement depends on the payer's bank — best-effort reconciliation aid, not a guarantee; the app's own record (amount + time + giver) is primary.

### CRC16 (CRC-16/CCITT-FALSE): poly `0x1021`, init `0xFFFF`, no reflection, xorout `0x0000`, uppercase 4-hex.
```dart
String crc16(String payload) {
  int crc = 0xFFFF;
  for (final byte in payload.codeUnits) {
    crc ^= (byte << 8) & 0xFFFF;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF;
    }
  }
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}
```
Full copia-e-cola = `<all fields> + "6304" + crc16(<all fields> + "6304")`.

### Rendering
- Feed the final string to `qr_flutter`; provide a copy button for the raw string.
- Sanitize `merchant_name` / `merchant_city`: strip accents, uppercase, ASCII-only, enforce max lengths — some banks reject non-conforming payloads.

## 8. App Structure & Routes (go_router)

### Public / gated
- `/` — landing / "create your list" CTA.
- `/l/:slug` — list view. On load: call `list_access_info(slug)` → decide gate:
  - public + anonymous → render immediately.
  - login_required (or private) and no session → render a **sign-in gate** ("This list requires sign-in" / "This list is private — sign in to check access").
  - private + signed-in but not allowlisted → render **no-access** screen.
  - access granted → load items + progress.
- `/l/:slug/gift/:itemId` — contribute flow (modal ok): name (typed if anonymous, prefilled if signed in) + optional message + amount. Submit → create contribution (`awaiting_confirmation`, txid, expires_at, contributor_id if signed in) → show QR + copia-e-cola + **"I've paid"**.
- `/l/:slug/thanks` — post-payment screen.

### Authed (creator dashboard)
- `/auth` — sign in / sign up (email+password / magic link; phone optional).
- `/dashboard` — my lists (+ create).
- `/dashboard/lists/:id/edit` — metadata, Pix key, cover, publish, **visibility + contributor_auth toggles** (private locks auth to login_required).
- `/dashboard/lists/:id/allowlist` — manage allowlist (add/remove emails; phones only if SMS auth enabled). Shown only when visibility = private.
- `/dashboard/lists/:id/items` — item CRUD, images, ordering, `allow_partial`.
- `/dashboard/lists/:id/contributions` — inbox of `awaiting_confirmation` → confirm/reject; thank-you wall of confirmed (owner sees names/messages).
- `/dashboard/profile` — display name, default Pix key + type, merchant city.

Route guards: authed routes require a session. The `/l/:slug` gate is dynamic per the list's settings.

## 9. State Management & DI (provider + flutter_bloc, cubits-first)

### DI / repositories (injected at app root via `MultiRepositoryProvider`)
Abstract interfaces (Supabase implementations live behind them so the backend is swappable):
```dart
abstract class AuthRepository {
  Stream<AuthUser?> authState();
  AuthUser? get currentUser;
  Future<void> signInWithPassword(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> sendMagicLink(String email);
  Future<void> signOut();
}

abstract class GiftRegistryRepository {
  // Owner — lists
  Future<GiftList> createList(NewList data);
  Future<GiftList> updateList(String id, ListUpdate data); // incl. visibility/contributor_auth
  Future<void> setPublished(String id, bool published);
  Future<List<GiftList>> myLists();
  // Owner — allowlist
  Future<List<AllowlistEntry>> getAllowlist(String listId);
  Future<void> setAllowlist(String listId, List<AllowlistEntry> entries);
  // Owner — items
  Future<GiftItem> addItem(String listId, NewItem data);
  Future<GiftItem> updateItem(String id, ItemUpdate data);
  Future<void> removeItem(String id);
  Future<List<GiftItem>> itemsForList(String listId);
  // Owner — contributions inbox
  Future<List<Contribution>> contributionsForList(String listId);
  Future<void> confirmContribution(String id);
  Future<void> rejectContribution(String id);
  // Public / contributor
  Future<ListAccessInfo> getListAccessInfo(String slug); // anon-readable gate metadata
  Future<PublicList> getPublicList(String slug);          // throws AccessDenied per RLS
  Future<List<ItemProgress>> publicProgress(String slug);
  Future<Contribution> createContribution(NewContribution data); // anon or authed
}

abstract class StorageRepository {
  Future<String> uploadImage(String path, Uint8List bytes); // returns public URL
}

// Pure client-side, no backend:
abstract class PixPayloadService {
  String buildCopiaECola({
    required String pixKey,
    required int amountCents,
    required String merchantName,
    required String merchantCity,
    required String txid,
  });
}
```

### Cubits (feature state)
Root-scoped: `AuthCubit` (session). Feature-scoped (created via `BlocProvider` at the relevant go_router route):
- `ProfileCubit` — load/save profile.
- `ListsCubit` — dashboard lists.
- `ListEditorCubit` — edit metadata + visibility/auth + publish (enforces the private⇒login_required rule client-side).
- `AllowlistCubit` — manage allowlist entries.
- `ItemsCubit` — item CRUD.
- `ListGateCubit` — resolves `list_access_info` + session → emits gate state (`open | needsLogin | private | noAccess | ready`).
- `PublicListCubit` — loads items + progress once the gate is `ready`.
- `GiftCubit` — contribute flow (`form → generating → awaitingPayment → done → error`).
- `ContributionsCubit` — owner inbox (confirm/reject).

**Bloc vs Cubit:** everything is a Cubit in the MVP. The only future candidate for a full Bloc is `GiftCubit`, *if* it later gains payment polling/retries under a PSP — and even then a Cubit likely suffices. Don't force events where a Cubit is enough.

## 10. Postgres Functions / Triggers

- `handle_new_user()` trigger on `auth.users` insert → create matching `profiles` row (applies to creators and contributors).
- `has_list_access(list_id)` — security-definer, per §6.
- `public_item_progress(list_slug)` — security-definer, access-checked aggregates, no PII.
- `list_access_info(slug)` — security-definer, anon-readable gate metadata only.
- Lazy reservation expiry inside the progress function (no pg_cron dependency).
- Optional `slugify()` for unique slug generation.

## 11. Supabase Storage

- Bucket `list-images` (public read).
- Paths: `{owner_id}/{list_id}/cover.jpg`, `{owner_id}/{list_id}/items/{item_id}.jpg`.
- Storage RLS: authenticated users write only under their own `{owner_id}/…` prefix; public read.
- Client: compress/resize before upload to conserve the free-tier 1 GB storage + 5 GB egress.
- Note: images are public-URL even for `private` lists (the gating is on data, not on image URLs). If image privacy matters for private lists, switch to a private bucket + signed URLs — deferred, not MVP.

## 12. Future Extensions (design so they slot in)

- **Card + installments**: each creator gets their own PSP (e.g. Asaas) sub-account/account (KYC); generate dynamic charges (Pix à vista or card in N parcelas) to the creator's account; consume the PSP **webhook** to auto-confirm (drops the manual honor step). No cut taken → still no split/marketplace.
- **Dynamic Pix auto-confirm** even without cards (PSP-issued dynamic Pix + webhook).
- **Additional / international payment methods** (PayPal.me link, IBAN/SEPA
  transfer, Wise/Revolut tag) for creators outside Brazil where Pix is
  unavailable. The honor-based manual confirmation model already generalizes, and
  the `PaymentInstructionService` seam (ADR-0004) makes each new method additive —
  a `Payee` + `PaymentInstruction` variant + service impl + renderer.
- **Phone allowlist** once SMS auth is funded.
- Signed-URL private images; "my gifts" view for signed-in contributors; thank-you automation; contributor-covers-fee toggle; RSVP.

## 13. MVP Scope Checklist

- [ ] Supabase: tables + enums + the two CHECK constraints, `list_allowlist`, RLS, `handle_new_user` trigger, `has_list_access`, `public_item_progress`, `list_access_info`, storage bucket + policies.
- [ ] Auth (email/password + magic link) with route guards; contributor sign-in reuses the same auth.
- [ ] Repository interfaces + Supabase implementations (backend fully behind them).
- [ ] Profile screen (Pix key, type, merchant city).
- [ ] List CRUD + publish + slug uniqueness + cover upload + **visibility + contributor_auth toggles** (private locks auth to login_required).
- [ ] Allowlist management screen (email; phone gated behind SMS availability).
- [ ] Item CRUD + images + `allow_partial` + ordering.
- [ ] `/l/:slug` **gate logic**: access_info → open / needs-login / private / no-access / ready.
- [ ] Public list view with PII-free progress badges (access-aware).
- [x] Contribute flow: contribution insert (anon or authed, contributor_id) + reservation TTL + **client-side BR Code (EMV + CRC16)** + QR + copy + "I've paid". *(mock-backed; Supabase RLS insert lands in the backend phase)*
- [x] Contributions inbox: confirm/reject + thank-you wall. *(mock-backed)*
- [x] Lazy expiry of stale reservations. *(mock read marks past-TTL reservations expired)*
- [ ] Cubit tree + DI wiring per §9; empty/error/loading states; BRL cent↔display formatting; merchant name/city sanitization.

### Explicit MVP constraints
- Pix only, static key, money direct to creator; platform never holds funds.
- Payment confirmation is manual (creator verifies against bank statement). No webhook, by design.
- Access control: public/private × anonymous/login_required, with `private ⇒ login_required` enforced.
- Email auth + email allowlist are the free path; phone/SMS auth is optional and costs money.
- No fees, no split, no PSP.
