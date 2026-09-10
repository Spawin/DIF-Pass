# Lot D - Sync-ready identifiers (design)

**Date:** 2026-09-10
**Status:** approved, ready for implementation plan

## Goal

Give every independently-created database row a stable global identifier
(`syncId`, a v4 UUID) so a future multi-device merge process can recognise
"the same real-world row" across devices without relying on the local
autoincrement `id`, which collides between devices.

This lot is **schema preparation only**. No merge logic, no sync transport,
no export of `syncId`, no UI. The column is added, backfilled, and kept
unique so that the day sync is built, the identifiers are already there and
already stable in every existing install.

## Background

- Local storage is SQLite via Drift. All 6 tables
  (`Events`, `CustomFields`, `Beneficiaries`, `BeneficiaryValues`,
  `Tickets`, `CheckIns`) use `integer().autoIncrement()` primary keys.
- Those `id` values are per-device counters. Device A's event 5 and device
  B's event 5 are unrelated. Any future merge that keyed on `id` would
  corrupt data.
- `Events.shortCode` (`'EVT' + id`) is a human-facing display label derived
  from the local `id`. It is not a merge key and does not change.

## Scope

### Tables that get `syncId` (5 of 6)

`Events`, `CustomFields`, `Beneficiaries`, `Tickets`, `CheckIns`.

Each of these can be created independently on a device (an organiser adds an
event on their phone; a helper generates tickets on a tablet; check-ins
happen on whichever device scans). A future merge needs to recognise each
such row across devices, so each needs its own global id.

### Table that does NOT get `syncId`

`BeneficiaryValues`. It has no domain class - it is folded into
`Beneficiary.customFieldValues: Map<int, String>` and is never addressed on
its own. A future merge matches a value row by the composite natural key
`(beneficiary.syncId, customField.syncId)`. A third identifier there would
be unused. (YAGNI.)

### Explicitly out of scope

- Merge / conflict-resolution logic
- Sync transport, local-network discovery, online/offline sync
- Export or import of `syncId` (backup keeps exporting the raw file, which
  already carries the column once this lot ships)
- Any UI or user-visible change
- Changing local `id`, primary keys, foreign keys, or `go_router` routes
- Changing `Events.shortCode`

## Data model changes

### Column definition

Each of the 5 tables gets, in its table class:

```dart
TextColumn get syncId => text().nullable().clientDefault(_uuid.v4)();
```

- **`clientDefault(_uuid.v4)`** - Drift generates a v4 UUID in Dart at
  insert time whenever a companion does not set `syncId`. This covers every
  write path automatically: repository inserts, CSV import, tests. No
  repository call sites change.
- **`.nullable()`** - required only because `Migrator.addColumn` on a table
  that already has rows rejects a non-nullable column that has no constant
  SQL default (a UUID is not constant). New rows are never null
  (`clientDefault`); the migration backfills old rows; the unique index
  (below) would reject a second null anyway. "Non-null in practice" is an
  application invariant, marked with a `ponytail:` comment where a row is
  mapped to its domain object (`row.syncId!`).

### Unique index

Each of the 5 tables gets a unique index on `syncId`. On fresh installs this
comes from a `@TableIndex(name: 'idx_<table>_sync_id', columns: {#syncId},
unique: true)` annotation on the table class, so Drift emits it in
`onCreate`. The migration creates the same index by raw statement after
backfill (see below). Both paths converge on identical schema.

### Domain classes

`Event`, `CustomField`, `Beneficiary`, `Ticket`, `CheckIn` each gain a
non-nullable `String syncId` field. Mappers read `row.syncId!` with a
`ponytail:` comment noting the schema column is nullable for migration
reasons only.

`NewBeneficiary` and any other "input" value objects do **not** carry
`syncId` - it is assigned by the database on insert, never supplied by the
caller.

## Migration v2 -> v3

`AppDatabase.schemaVersion` goes from `2` to `3`.

In `migration.onUpgrade`, add a `from < 3` block that, for the 5 tables:

1. `await m.addColumn(table, table.syncId)` - adds the nullable column.
2. Backfill: select all existing rows, and for each write a fresh
   `_uuid.v4()` into `syncId` (one UUID per row, keyed by local `id`).
3. `await customStatement('CREATE UNIQUE INDEX idx_<table>_sync_id ON <table> (sync_id)')`
   - safe now that every row has a distinct value.

The existing `from < 2` block (adds `events.ticketTemplate`) and the
`beforeOpen` PRAGMA stay unchanged. A v1 install upgrading straight to v3
runs both blocks in order.

## Dependency

Add to `pubspec.yaml`:

```yaml
uuid: ^4.5.1
```

(Pin to whatever `4.x` resolves at implementation time.)

In `app_database.dart`: `final _uuid = Uuid();` at library level, passed as
`_uuid.v4` to each `clientDefault`.

## Testing

### Migration test

New case in `test/core/database/app_database_migration_test.dart`, following
the existing pattern (build a legacy DB on disk with the raw `sqlite3`
package, stamp `userVersion`, open it through `AppDatabase.forTesting`,
assert the migrated result):

- Build a **v2** schema on disk: `events` (with `ticket_template`),
  `custom_fields`, `beneficiaries`, `beneficiary_values`, `tickets`,
  `check_ins` - all without `sync_id`. Insert at least 2 events, 1 custom
  field, 1 beneficiary, 1 ticket, 1 check-in. Set `userVersion = 2`.
- Open through `AppDatabase`. For each of the 5 migrated tables assert every
  row's `syncId` is non-null, is a well-formed UUID, and that the values
  are all distinct.

### clientDefault unit test

In `test/core/database/app_database_test.dart` (in-memory DB): insert two
rows into the same table without specifying `syncId`, assert the two
`syncId` values are present and different.

### Unique-index test

Attempt a raw `INSERT` (or a companion insert) that reuses an existing
`sync_id` value; assert it throws a uniqueness error.

### Regeneration

`fvm dart run build_runner build --delete-conflicting-outputs` to
regenerate `app_database.g.dart` after the table-class and schema-version
changes. The generated file is never hand-edited.

### Existing suite

All 158 existing tests must still pass. `clientDefault` means existing
fixtures that insert rows keep working with no change (they just start
getting a `syncId` they ignore).

## Risks and notes

- **Nullable column vs. invariant.** The schema column is nullable but the
  domain field is not. This is a deliberate, documented gap: `addColumn`
  leaves no other option for a UUID column on a populated table without a
  full table rebuild, which is far more invasive. The unique index plus
  `clientDefault` make a null in practice unreachable.
- **Backfill cost.** Real installs hold at most a few thousand rows across
  all tables. A per-row UUID write inside one migration transaction is
  fine; no batching needed.
- **`shortCode` stays derived from `id`.** It is a label, not a key. If a
  future merge needs a stable human code it can be revisited then.
