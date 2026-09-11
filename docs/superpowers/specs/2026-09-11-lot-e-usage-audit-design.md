# Lot E - Local usage audit, opt-in (design)

**Date:** 2026-09-11
**Status:** approved, ready for implementation plan

## Goal

Give organisers who want to help improve the app a way to record, locally,
what they actually do with it - scan outcomes, event/ticket/import flows -
so that a future analysis (done off the device, on the exported file) can
answer real questions from the field. The concrete question that started
this: is the 1.8s check-in feedback delay ([app_settings.dart](../../../lib/core/settings/app_settings.dart))
actually right, or too long/short in practice?

This is opt-in, off by default, and never leaves the device on its own. No
network layer exists in this app and none is added here.

## Principles (privacy by design)

- **Opt-in, off by default.** Nothing is recorded until the user turns it on.
- **Informed, not forced.** A plain-language settings section explains what
  is recorded, why, that it stays on the device, and how to turn it off or
  erase it. No pop-up, no first-run interruption.
- **Data minimisation.** No names, no locations, no logos, no readable
  ticket IDs, no QR payloads, no beneficiary or event content of any kind.
  Only event type, timestamps, counts, durations, and enum-like outcomes.
- **No stable cross-session identifier.** A random session ID is generated
  in memory each time the app starts and is never persisted; it lets a
  future analysis group actions that happened together without being able
  to link two different app launches, or link back to any business record.
- **Purpose limitation.** The data exists to improve the app's UX and
  defaults (timings, flow friction). Nothing else reads it.
- **Storage limitation.** The log is capped by count and by age (below); it
  cannot grow without bound.
- **Right to erasure.** A dedicated "delete audit data" action, independent
  from turning collection off, with a confirmation dialog.
- **No automatic transmission.** The app never uploads anything. Sharing
  the file is a manual, explicit action by the user, same as the existing
  backup export.

## Where the data lives

A single append-only file, `audit.jsonl` (one JSON object per line), in
`getApplicationSupportDirectory()` - app-private internal storage on both
platforms (Android: `/data/data/<package>/files`; not the Documents
directory, since this is not user content and not what the existing backup
feature already exports). Turning the feature on creates the file; turning
it off leaves it in place; deleting removes it.

This is intentionally separate from `dif_pass.sqlite`: no schema migration,
no interaction with the backup/restore feature at all (a restored backup
never touches or overwrites the audit log, and the audit log is never
included in an exported backup).

## What gets recorded

Every line is a JSON object: `{"ts": "<ISO-8601>", "session": "<uuid>",
"type": "<event type>", ...event-specific fields}`.

`session` is a v4 UUID generated once when the app process starts (held in
memory only, in `AuditLogger`), the same value for every line written
during that run.

Event catalogue (six types, all instrumented at the presentation layer -
screens already hold every field below without new repository plumbing):

| `type` | Fields | Where |
| --- | --- | --- |
| `checkin_scan` | `result` (`new` \| `already` \| `not_found`), `presenceMode` (`simple` \| `multiple`), `feedbackDurationMs` (int), `dismissedBy` (`auto` \| `manual`) | `CheckInScanScreen` |
| `event_created` | `presenceMode`, `customFieldCount` (int) | wherever `EventRepository.createEvent` is called from |
| `tickets_generated` | `count` (int), `durationMs` (int) | wherever `TicketRepository.generateMissingTickets` is called from |
| `beneficiaries_imported` | `rowCount` (int), `errorCount` (int), `durationMs` (int) | CSV import screen |
| `event_archive_action` | `action` (`archive` \| `restore`) | events list / event card |
| `backup_action` | `action` (`export` \| `import`) | `SettingsScreen` |

No event carries an `id`, `syncId`, name, or any other value that could
identify a specific event, beneficiary, or ticket. `checkin_scan` is the
only type with a duration tied to UX tuning; the others exist because they
were explicitly asked for ("le flux") and cost nothing extra to add now
that the logger exists.

## Retention

On each app start, before anything is appended, `AuditLogger.init()` reads
the existing file (if any) once and rewrites it keeping only lines that are
both:
- no older than 12 months, and
- among the most recent 20 000 lines.

This keeps the file within roughly 2-3 MB and bounded in age, per the
storage-limitation principle, at a cost of one O(n) pass at startup capped
at 20 000 lines - cheap, and it only runs once per launch, not per write.
Ordinary appends during the session are plain `writeAsString(mode: append)`
calls, no rotation check on the hot path.

## Consent UI

A new section in the existing Settings screen
([settings_screen.dart](../../../lib/features/backup/presentation/screens/settings_screen.dart)),
below the language selector:

- A short explanatory paragraph (localised, FR/EN, no accents in French):
  what is recorded (a short version of the catalogue above, in plain
  language), that it never leaves the device automatically, and that it can
  be turned off and erased at any time.
- A `Switch` bound to a new `AppSettings.auditEnabled` (bool, default
  `false`), persisted the same way `checkinFeedbackDelayMs` is.
- An `OutlinedButton` "Exporter les donnees d'audit" - enabled only when
  the file exists - shares `audit.jsonl` via `SharePlus.instance.share`,
  identical pattern to the existing backup export (temp copy not needed,
  the file is already outside the SQLite backup path).
- A `TextButton` "Supprimer les donnees d'audit" (destructive style) -
  enabled only when the file exists - opens a confirmation dialog (same
  shape as `showImportConfirmDialog`), then deletes the file and shows a
  snackbar.

Turning the switch off stops future writes immediately (`AuditLogger`
checks the live enabled flag on every call) but does not touch the file -
deletion is only ever the explicit button.

## Architecture

### `AuditLogger` (`lib/core/audit/audit_logger.dart`)

A plain class, one instance held by a `Provider<AuditLogger>`
(`auditLoggerProvider`), constructed once at app start with the initial
`enabled` value read from `AppSettings` and a freshly generated session
UUID (`uuid` package, already a dependency since lot D).

```dart
class AuditLogger {
  AuditLogger({required bool enabled, required File Function() fileResolver})
      : _enabled = enabled,
        _fileResolver = fileResolver,
        _sessionId = const Uuid().v4();
  ...
  void setEnabled(bool value); // called by the settings toggle handler
  Future<void> init();         // startup rotation pass, see Retention
  void logCheckinScan({required String result, required String presenceMode,
      required int feedbackDurationMs, required String dismissedBy});
  void logEventCreated({required String presenceMode, required int customFieldCount});
  void logTicketsGenerated({required int count, required int durationMs});
  void logBeneficiariesImported({required int rowCount, required int errorCount, required int durationMs});
  void logEventArchiveAction({required String action});
  void logBackupAction({required String action});
}
```

Each `logX` method is a thin wrapper that, if `_enabled`, builds the map
and calls one private `_append(Map<String, dynamic>)`. `_append` is
fire-and-forget (`unawaited`) and wrapped in `try/catch` that swallows and
`debugPrint`s any failure - **audit logging must never throw into caller
code or affect the real feature it instruments.** This is the one place in
the app where a deliberately silent catch is correct, and it gets a
`ponytail:` comment saying so.

The settings toggle handler calls both `AppSettingsNotifier.setAuditEnabled`
(persists it) and `ref.read(auditLoggerProvider).setEnabled(value)` (updates
the live instance) - the same two-step the delay slider and language
selector do not need only because nothing else currently holds a
long-lived instance keyed off a setting.

### `AppSettings` / `AppSettingsNotifier`

Add `auditEnabled` (bool, default `false`) alongside the two existing
fields, with `saveAuditEnabled` / `setAuditEnabled`, mirroring
`localeOverride`'s save/set pair exactly.

### Instrumentation call sites

Six call sites, each a single `ref.read(auditLoggerProvider).logX(...)`
line added after the action already succeeds - no control flow changes:

1. `CheckInScanScreen._dismissFeedback` gains an `{bool auto = false}`
   parameter (the auto-dismiss timer callback passes `auto: true`; the
   "Passer"/tap-to-dismiss path passes nothing). The screen already knows
   `_feedback` (carries the result) and the presence mode; it records the
   `DateTime.now()` when `_feedback` is set in `_process` and computes the
   elapsed milliseconds at dismiss time.
2. Wherever `EventRepository.createEvent` succeeds in the event form
   screen.
3. Wherever `TicketRepository.generateMissingTickets` succeeds (wrap the
   call in a `Stopwatch` or two `DateTime.now()` reads).
4. The CSV import screen, after it already computes accepted/rejected row
   counts for its own summary UI.
5. The event card's archive/restore action (already a single method each).
6. `SettingsScreen._export` / `_import`, on success only.

## Testing

- `AuditLogger` unit tests (new, `test/core/audit/audit_logger_test.dart`,
  a temp directory + `fileResolver` override): disabled logger writes
  nothing; enabled logger appends a well-formed JSON line with the
  expected keys for each of the six `logX` methods; two log calls from one
  logger instance share the same `session` value; a fresh `AuditLogger`
  instance has a different `session`; `init()` drops lines older than 12
  months and keeps only the most recent 20 000 of what remains; a write
  failure (e.g. an unwritable path) does not throw.
- `AppSettings` / `AppSettingsNotifier` tests: extend the existing pattern
  for `auditEnabled` default/save/load, same shape as `localeOverride`'s.
- `SettingsScreen` widget tests: switch toggles and persists; export/delete
  buttons disabled when no file exists; delete button asks for
  confirmation and only deletes on confirm (mirrors the existing import
  confirmation test).
- The six instrumentation call sites get a smoke assertion only where the
  screen's existing test setup makes it cheap (inject a test `AuditLogger`
  via provider override and assert one `logX` call happened) - not a new
  test file per site. `CheckInScanScreen` is the one call site instrumented
  with a real assertion on the duration/`dismissedBy` fields, since that is
  the case this lot exists for; the other five get a one-line "was it
  called" check appended to their existing success-path test if doing so
  does not require restructuring that test, otherwise skipped as
  disproportionate for now (YAGNI on test infrastructure the plan can flag
  and skip case by case).

## Out of scope

- Any on-device viewer, chart, or dashboard for the audit data - analysis
  happens off-device on the exported file. YAGNI until someone actually
  does that analysis and asks for it.
- Any automatic export, upload, or network transmission, now or later
  without a separate explicit design.
- A first-run consent prompt or any interruption of normal app use.
- Crash reporting, screen-view/navigation tracking, or any identifier that
  survives an app restart.
- Touching the backup/restore feature, the database schema, or lot D's
  `syncId` work in any way.

## Risks and notes

- **Silent catch around every write.** Deliberate: an audit feature must
  never be the reason a check-in or ticket generation fails. Documented
  inline; the unit tests cover the "write failure does not throw" case
  directly rather than relying on production behaviour going unnoticed.
- **`getApplicationSupportDirectory()` vs `getApplicationDocumentsDirectory()`.**
  Both are app-private on Android and iOS; the choice is about intent, not
  additional protection - support-directory content is not meant to be
  user-browsable, which matches an audit log better than the documents
  directory the backup feature already uses for user-facing exports.
- **Startup rotation cost.** Bounded at 20 000 lines (a few MB), one pass,
  once per launch. Not a concern at this app's scale.
