# Tecno CE9 UI fixes (design)

**Date:** 2026-09-11
**Status:** approved, ready for implementation plan

## Goal

Fix six UI defects found during a real-device test on a Tecno CE9, confirmed
against the current codebase. Two items from the original bug list were
dropped after investigation: the audit-export icon already matches the
backup-export icon in the current code (the screenshot predates it or shows
something else - not reproduced), and the ticket "style instability" is the
existing three-template feature (Compact/Standard/Elegant) working as
designed, not a rendering bug - dropped per the user's decision, including
the card's vertical centering. Beneficiary photo (a new feature) is
deferred to a later, separate design.

## Scope

### 1. Event card text wraps character-by-character

`lib/features/events/presentation/widgets/event_card.dart` - the `ListTile`'s
`trailing` holds 4 widgets (3 `IconButton` + a `PopupMenuButton`), squeezing
the title/subtitle area to near-zero width on a narrow screen, which makes
Flutter wrap the text one character per line.

Fix: reduce `trailing` to 2 direct icons (Tickets, Check-in - the two used
most often once an event is running) and move Beneficiaries into the
existing "more actions" popup menu, alongside Archive and History (now 3
items instead of 2). No other visual change to the card.

### 2. Duplicated call-to-action on empty states

`lib/features/events/presentation/screens/events_list_screen.dart` and
`lib/features/beneficiaries/presentation/screens/beneficiaries_list_screen.dart`
both pass `actionLabel`/`onAction` to `EmptyState` while also declaring a
`FloatingActionButton.extended` doing the same thing - the button appears
twice, and the FAB overlaps the system navigation bar on this device.

Fix: keep the FAB (the app-wide pattern), drop `actionLabel`/`onAction` from
both `EmptyState` calls (the widget itself is unchanged - other callers use
it without an action already). Wrap each FAB in a `Padding` using
`MediaQuery.paddingOf(context).bottom` so it clears the system bar on every
device, not just this one.

### 3. Event form save button gets cut off

`lib/features/events/presentation/screens/event_form_screen.dart` - the form
is already a scrollable `ListView`, but its bottom padding is a flat 16px
with no allowance for the system navigation bar.

Fix: bottom padding becomes `16 + MediaQuery.paddingOf(context).bottom + 24`.
No structural change (no new `SingleChildScrollView` needed, it already
scrolls).

### 4. "Automatique" wraps in the language segmented button

`lib/l10n/app_fr.arb` / `lib/l10n/app_en.arb` - `settingsLanguageAuto` is
"Automatique" / "Automatic", too long for a 3-segment control on a narrow
screen.

Fix: shorten both to "Auto" (identical in French and English, so no
locale-specific wording risk). No layout change needed once the string is
short enough.

### 5. Disabled audit buttons fail contrast

`lib/features/backup/presentation/screens/settings_screen.dart` - the
"Exporter les donnees d'audit" / "Supprimer les donnees d'audit" buttons use
Material 3's default disabled treatment (`onSurface` at 38% opacity), which
computes to roughly 2:1 against this app's `paper` background - below the
3:1 minimum for non-text UI components.

Fix: give both buttons an explicit `style` with
`disabledForegroundColor: AppColors.ink.withValues(alpha: 0.6)` (and
matching disabled icon color via the same `ButtonStyle`). Computed against
`AppColors.paper`, this lands close to 4:1 while staying visibly lighter
than the buttons' active-state color, so disabled remains distinguishable
from enabled at a glance.

### 6. "Generer les tickets" is disabled with no explanation

`lib/features/tickets/presentation/screens/tickets_screen.dart` - disabled
when `beneficiaries.length <= tickets.length`, which covers two distinct,
legitimate cases with no visible reason given.

Fix: a small `Text` (bodySmall, muted color) below the button, shown only
when the button is disabled, with wording depending on which case applies:
- no beneficiaries yet: prompt to add beneficiaries first
- all beneficiaries already have a ticket: say tickets are already generated

Two new ARB keys, no placeholders.

## Out of scope (explicitly dropped this round)

- Audit-export icon (item 5 of the original report) - not reproduced against
  current code, both export buttons already use the same icon.
- Ticket card "style instability" (item 7) - is the existing
  Compact/Standard/Elegant template feature, not a bug. Dropped entirely
  per the user's decision, including the card's vertical-centering layout
  (leaves noticeable empty space above the card on a tall screen) - not
  touched this round.
- Beneficiary photo (item 9) - a new feature, deferred to its own design
  discussion later.

## Testing

- `EventCard` widget test: trailing now has exactly 2 `IconButton`s
  (Tickets, Check-in) and the popup menu has 3 items including
  Beneficiaries; tapping the Beneficiaries menu item still calls
  `onManageBeneficiaries`.
- Events/beneficiaries list empty-state tests: `EmptyState` renders with no
  action button when the list is empty; the FAB is still present and
  tappable.
- Event form test: existing save-flow tests unaffected (padding is a
  visual-only change, no new widget to find).
- Settings screen test: assert the audit export/delete `OutlinedButton`/
  `TextButton` styles carry the new `disabledForegroundColor` when disabled.
- Tickets screen test: hint text appears with the right wording when
  disabled for each of the two reasons, and is absent when the button is
  enabled.
- Language segmented button: existing tests keep passing with the shortened
  label (assert on the ARB key's value / find by segment value, not by the
  literal string "Automatique" if any test hardcodes it - check first).
