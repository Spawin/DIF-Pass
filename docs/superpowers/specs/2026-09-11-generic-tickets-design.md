# Generic (nameless) ticket generation (design)

**Date:** 2026-09-11
**Status:** approved, ready for implementation plan

## Goal

Let an organiser generate a batch of tickets for an event where entry is
controlled purely by presenting a ticket - no beneficiary name needed at
creation time (e.g. general-admission access). Each generated ticket stays
an individual, one-scan ticket exactly like today; only the "who is it for"
step is skipped.

## Approach

No schema change, no change to check-in, presence counting, export, or the
beneficiaries list. A generic ticket is, underneath, a normal `Beneficiary`
row with an auto-assigned name and its normal `Ticket` row - every existing
code path that already understands "a ticket belongs to a beneficiary"
keeps working unmodified.

Two alternatives were considered and rejected for a first version:

- **Nullable `Ticket.beneficiaryId`** - would touch check-in feedback,
  ticket preview, CSV export, presence counting, and the tickets list badge,
  all of which currently assume a beneficiary exists. Large blast radius for
  a feature whose only requirement is "skip typing a name."
- **A reusable/shared ticket** (one ticket, many uses) - explicitly ruled
  out; each generated ticket must remain a single scannable entry, matching
  today's check-in model exactly.

### Naming

The placeholder beneficiary is named `Ticket <readableId>` (e.g.
`Ticket 0007`), using the ticket's own readable ID - already unique within
the event, already computed before either row is inserted (`generateTicketId`
is pure, no DB round-trip needed to know the name up front). This is a fixed
convention, not localised (same reasoning as `Events.shortCode`'s `'EVT' +
id'` prefix already being fixed regardless of locale).

These beneficiaries are ordinary rows: visible in the beneficiaries list,
renameable, deletable, exportable - nothing marks them as "generic" beyond
their name. If a future need shows up (bulk identification, a visual badge,
filtering them out of some view), it can be layered on later; not built now.

### Entry point

A second action on the tickets screen, next to "Generate tickets": "Add
generic tickets", opening a small dialog that asks for a count (a positive
integer, capped at 500 to guard against a fat-fingered huge number - well
above any realistic single-event batch, cheap to raise later if ever
needed). Confirming creates that many beneficiary+ticket pairs in one
transaction and shows a snackbar with the count added.

### Data flow

New repository method, `TicketRepository.generateGenericTickets(int eventId,
int count)`, implemented in `DriftTicketRepository` by extending the exact
sequence-numbering logic `generateMissingTickets` already uses (scan
existing tickets for the event, take the highest parsed `readableId` + 1,
increment locally per new ticket - this method can run before or after
`generateMissingTickets` without ever colliding on `readableId`). For each
of `count`: compute `generateTicketId(sequence: n)`, insert a
`BeneficiariesCompanion` named `'Ticket ${generated.readableId}'`, then
insert the matching `TicketsCompanion` for that new beneficiary id. One
`_db.transaction`, same as the existing method.

## Out of scope

- Any visual marker distinguishing generic beneficiaries from named ones.
- Bulk rename / bulk delete of generic tickets.
- Reusable/multi-use tickets.
- Any change to check-in, presence counting, CSV import/export, or the
  ticket card/template.

## Testing

- `DriftTicketRepository.generateGenericTickets`: creates `count` beneficiary
  rows named `Ticket <readableId>` and `count` matching ticket rows for the
  event; sequence numbering picks up correctly after existing tickets
  (including ones from `generateMissingTickets`) and does not collide with
  them; each generated ticket's `qrPayload` is well-formed
  (`payloadFor(event.shortCode)`); running it twice in a row does not
  reuse a `readableId`.
- `TicketsScreen` widget test: the new action opens a dialog; entering a
  valid count and confirming calls `generateGenericTickets` with that count
  and shows a success snackbar; cancelling does not call it; a non-numeric
  or zero/negative entry is rejected with a validation message instead of
  submitting.
- `FakeTicketRepository` gains a `generateGenericTickets` implementation for
  use by that test and any other test that pumps `TicketsScreen`, following
  the existing `beneficiaryIdsForEvent` pattern for staying decoupled from a
  concrete beneficiary-repository type (a test that needs the created
  beneficiaries visible elsewhere wires a callback the same way).
