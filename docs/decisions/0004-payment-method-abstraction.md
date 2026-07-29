# ADR-0004: Payment method abstraction (`PaymentInstructionService`)

- **Status:** Accepted
- **Date:** 2026-07-29

## Context

The MVP is Pix-only (spec §1), but the product may be used outside Brazil, where
Pix does not exist and creators would be paid via other direct-to-creator methods
(PayPal.me link, IBAN/SEPA transfer, Wise/Revolut tag, …). We want adding a method
later to be an **additive** change — "implement another mechanism and enable it" —
not surgery on the contribute flow.

The Pix EMV/CRC payload engine (`PixPayloadService` / `EmvPixPayloadService`,
Phase 5) is irreducibly Pix-specific: a PayPal or IBAN method produces a link or
bank details, not EMV TLV fields. So the engine must **not** be generalized; the
seam belongs one layer above it.

The core mechanic already generalizes: payment is **honor-based and manual**
(contributor taps "I've paid" → creator confirms against their statement, no
webhook), which is exactly how any direct-to-creator method works.

## Decision

Introduce a method-agnostic seam that the contribute flow depends on, with Pix as
the first implementation:

- `PaymentInstructionService` (`lib/services/payments/`) — `build(PaymentRequest)
  → PaymentInstruction`, plus a `PaymentMethod method` discriminator.
- `PaymentRequest` carries method-agnostic transaction facts (`amountCents`,
  `reference`) plus a **sealed `Payee`** holding method-specific credentials
  (`PixPayee` today).
- **sealed `PaymentInstruction`** is the renderable result (`PixInstruction`
  wraps the copia-e-cola string today).
- `PixInstructionService` (`lib/services/pix/`) implements the seam by adapting
  `PixPayloadService`. It owns Pix-specific **normalization** (ASCII-sanitize +
  length-cap merchant name/city) before the engine **validates** the payload.
- DI binds `PaymentInstructionService` → `PixInstructionService` at the app root.

## Rationale

- Sealed `Payee` / `PaymentInstruction` make the analyzer enforce exhaustive
  handling: adding a variant surfaces every place that must handle it.
- The abstraction is validated against one real method (Pix) as it is built,
  avoiding a speculative interface with no implementation to keep it honest.
- The EMV engine stays a narrow, well-tested leaf; new methods are siblings.

## Consequences

- Adding a method = a new `Payee` variant + `PaymentInstruction` variant + a
  `PaymentInstructionService` impl + a small renderer + a `PaymentMethod` value.
  No edits to the contribute cubit's logic.
- With one method, DI is a single binding. When method #2 lands it becomes a
  resolver/registry keyed by `PaymentMethod` (deferred — not worth the ceremony
  now).
- Method-coupled *data* not yet generalized: `Profile` Pix fields and
  `Contribution.pix_txid`. These stay Pix-shaped until a second method or the
  Supabase schema phase, when `pix_txid` can become a neutral `payment_ref`.
