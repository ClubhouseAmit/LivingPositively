# ADR-017: Expand the existing reminders settings page

- **Status:** proposed
- **Date:** 2026-09-25
- **Issue:** [#237](https://github.com/ClubhouseAmit/LivingPositively/issues/237)

## Context and specification

The app already has a reminders page, one persisted `default` schedule, and an
authenticated FCM scheduler. That scheduler reads a localized resilience quote
from the existing Firestore quote pool for each delivery. The issue adds eleven
independent quick reminders, multiple custom reminders, clock and language
controls, and a summary. The linked Claude artifact describes interactions and
general layout; current design tokens determine the actual appearance.

The issue calls the app reminder "opt-in" while also requiring it to be enabled
by default. We interpret this as an enabled initial preference, subject to the
device's notification permission. It must never silently create a remote
schedule without a valid authenticated user and permission.

## Decision (SPARC architecture)

1. Keep `NotificationPage` in `lib/pages/` and place its parts in the existing
   notifications feature. The page owns presentation state; the existing
   notification repository owns persisted schedules and custom reminder data.
2. Keep `default` as the only dynamic notification type. The scheduler selects
   a localized quote at delivery time using a stable, per-user shuffled order.
   Adjacent days use different quotes when the pool has more than one entry.
   Rescheduling after a language change updates the selected quote collection.
3. Give each quick and custom reminder a distinct stable `typeId`. The FCM
   registration endpoint accepts bounded, validated static content only for
   those IDs and stores it with the authenticated user's schedule. The worker
   sends that saved content; it does not read an arbitrary client collection.
   New user-defined schedules are capped at 32 per account.
4. Reuse Flutter's Material dial time picker. It already has hour-to-minute
   progression, hour/minute header selection, 24-hour inner/outer rings, and
   AM/PM controls. Apply the page's format choice via `MediaQuery`.
5. Keep the app's existing language control; do not add one on the reminders
   page, per the collaborator's clarification. On a language change, refresh
   every active built-in schedule so quick reminder push text and the dynamic
   app reminder use the current locale. Page copy uses localized ARB strings,
   and the app's existing RTL behavior applies in Hebrew and Arabic.
6. Follow the supplied prototype screenshot's centered introduction, narrow
   reminder column, compact disabled rows, and consistent reminder switches.
   Use the app's color scheme for the header, enabled borders, and LP badge.
   Put the time-format control in the header on wider screens and above the
   quick list on phones. Keep the language control in the app shell.

## Pseudocode and refinement

On entry, read saved preferences and custom definitions; show the app reminder
first, quick reminders next, the custom form, then a summary of enabled entries.
For a toggle or time change, call the scheduler with that entry's ID and time;
update the visible state only after a successful response. A failed operation
keeps the prior state and shows the existing error message. Save custom metadata
before scheduling it, and remove its schedule before deleting its metadata.
Changing language resubmits enabled static schedules with localized quick text.
If custom scheduling has an uncertain result, retain its card and require a
server cancellation before removing it. Reset and sign-out also cancel every
saved custom ID, including entries without a local enabled preference.
Registration compensation clears local state without marking an explicit
default opt-out. Editing custom metadata replaces its item in place to preserve
list order.

The registration boundary validates type IDs and text length. Existing auth,
mutation-version, reset-fence, and cancellation behavior stay in force.
Legacy stored preference maps without an opt-out key retain an absent default
schedule as an explicit off choice. A device with no local default preference
reads the server's current default schedule; it shows an active server time
without changing it, or leaves the card off for the user to enable.
Legacy Android alarm migration also reads the server first. It adopts an active
server time or cancellation record and uploads the legacy time only when the
server has no reminder history. An unreadable server schedule is reported as
absent while its mutation version remains available for repair or cancellation.
Account sign-out retires remote schedules and stores quick and custom choices
for reactivation when the signed-in user next opens the page with permission.
An explicit new schedule clears that reminder's paused choice and stale saved
time. Reactivated quick reminders use the current app language; custom reminders
retain their saved text. Queued reactivation reads the latest paused time when
it registers, skips a choice the user has already enabled, and a failed local
save restores the paused choice.
Reactivation changes each card to on only after its server registration succeeds.
Reminder preferences and pending choices are saved per account UID on shared
devices. Switching accounts activates only that account's local snapshot; a
different user cannot see or reactivate the previous user's reminders.
Account cleanup cancels all fixed quick IDs, including registrations without a
local acknowledgement. The server serializes new custom registrations through
a per-user transaction lock before checking the 32-reminder limit.
The app checks its active reminder count before saving a new custom reminder.
If another device fills the limit first, a server 429 shows a specific message
and the rejected custom reminder is removed from local metadata.
Failed reset or sign-out compensation uses a saved title as the notification
body when legacy stored content lacks a body.
The custom form, persisted model, and backend measure labels in UTF-16 code
units and accept at most 240. The scheduler reads provisioned notification type
documents only for IDs outside the user reminder namespace.

## Consequences

Every enabled reminder has one daily FCM schedule. Custom labels may be sent to
the app's FCM backend as notification content. App reminder content still comes
from the existing quote collections. A device with denied permission can edit
local presentation choices but cannot enable a remote reminder until permission
is granted.
