# Beneficiary photo (design)

**Date:** 2026-09-12
**Status:** approved, ready for implementation plan

## Goal

Let an organiser attach an optional photo to a beneficiary, for visual
identification: on the beneficiary form, the beneficiaries list, the ticket
(all three templates), and - the highest-value spot - the check-in scan
confirmation, so the agent at the door can see "is this the right person"
at the moment of validation.

Optional in every sense: creating or importing a beneficiary never requires
a photo, and every display falls back to a generic placeholder avatar when
none is set.

## Data model

New nullable column on `Beneficiaries`, mirroring `Events.logo` exactly:

```dart
BlobColumn get photo => blob().nullable()();
```

`AppDatabase.schemaVersion` goes from `3` to `4`. In `onUpgrade`, a `from < 4`
block runs `await m.addColumn(beneficiaries, beneficiaries.photo)` - a plain
nullable column with no default requirement, so no backfill is needed
(existing rows simply read `null`, which is the correct "no photo" value).

`Beneficiary` gains `final Uint8List? photo;`. `NewBeneficiary` gains an
optional `final Uint8List? photo;` (default `null`) - CSV import never
supplies one (a CSV row cannot carry binary data), so imported beneficiaries
always start with no photo, same as a manually created one that skips it.

## Capture

The form's "Photo" field opens a bottom sheet with two choices - "Take a
photo" / "Choose from gallery" - then `image_picker` with the same
constraints already used for the event logo (`maxWidth: 512, maxHeight: 512,
imageQuality: 80`), so the two pickers share one small helper instead of
duplicating settings.

iOS needs one new `Info.plist` key, `NSCameraUsageDescription`
(`NSPhotoLibraryUsageDescription` already exists for the event logo).
Android needs no manifest change - `image_picker`'s own manifest already
declares the camera permission, merged in automatically the same way
`mobile_scanner`'s already is.

## Where it displays

- **Beneficiary form** (create/edit): the same circular preview + "Photo"
  action already used for the event logo, same file/component shape.
- **Beneficiaries list**: a `CircleAvatar` leading widget on
  `BeneficiaryListTile`, `MemoryImage(photo)` when set, otherwise a generic
  person icon in a tinted circle (same visual language as `EventCard`'s
  existing leading avatar).
- **Ticket** (`_TicketCard`, all three templates - Compact/Standard/
  Elegant): a small circular medallion placed with the beneficiary name,
  not touching the existing event-logo slot at the top - the two identities
  (event branding vs. the individual) stay visually separate. When absent,
  nothing is drawn in that slot (no placeholder circle on a printed/shared
  ticket - a visible "no photo" avatar next to a real name reads as an
  error on a physical ticket, unlike in the app's own UI).
- **Check-in scan confirmation** (`_CheckInFeedbackOverlay`): a larger
  circular photo above the beneficiary name, shown only when a photo
  exists; the existing success/error icon stays as the primary visual
  regardless (this is the identification step, not a new icon language).
  `processCheckIn` already loads the full `Beneficiary` row via
  `beneficiaryRepository.getBeneficiary(...)` to read its name - reading
  `.photo` from that same object needs no extra repository call.

## Out of scope

- CSV import/export of photos (binary data has no place in a CSV row).
- Editing/cropping the photo after picking it (the same simple flow as the
  event logo - pick, done).
- Any change to the check-in matching logic itself (still ticket-id based);
  the photo is a display-only aid for the human doing the check.

## Testing

- `DriftBeneficiaryRepository`: `createBeneficiary`/`updateBeneficiary`/
  round-trip `photo` bytes; `importBeneficiaries` always leaves `photo` null.
- Migration test (v3 -> v4): existing beneficiary rows read back with
  `photo == null` after upgrade; a fresh install's column matches via
  `sqlite_master` the same way lot D's migration tests checked index
  convergence.
- `BeneficiaryFormScreen`: picking a photo (gallery path, mockable the same
  way the event logo's `ImagePicker` boundary is - untested at the platform
  call itself, same established convention) updates the preview; the photo
  submits with the rest of the form; editing a beneficiary that already has
  a photo shows it pre-filled.
- `BeneficiaryListTile`: shows the photo when present, the placeholder icon
  when absent.
- `_TicketCard`: medallion renders for each of the three templates when a
  photo exists; nothing extra renders when it does not.
- `check_in_processor`/`CheckInFeedback`: `beneficiaryPhoto` flows from the
  loaded `Beneficiary` into both `CheckInFeedbackRecorded` and
  `CheckInFeedbackAlreadyRecorded`; the overlay shows it only when non-null.
