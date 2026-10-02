# ADR-019: Unify app time formatting with the system preference

- **Status:** accepted
- **Date:** 2026-10-02
- **Supersedes:** the app-owned clock-format choice and controls in
  [ADR-017](ADR-017-reminders-settings-expansion.md), decisions 4 and 6.

The owner requested removal of the reminders page's clock-format controls and
subsequently required a unified time format throughout the app. Review found
that a reminders-only Hebrew override disagreed with dark-mode scheduling and
loaded asynchronously, leaving newly mounted pages and dialogs temporarily
empty. Flutter web also exposes no OS hour-cycle flag, so removing the manual
toggle without a browser fallback prevented English 24-hour presentation.

Set the hour-cycle policy once at the root `MaterialApp`. Native platforms use
the ambient `MediaQuery.alwaysUse24HourFormat` flag. On web, the app shell reads
the browser's preferred hour cycle through `Intl.DateTimeFormat` with an hour
component and `resolvedOptions().hourCycle`; it applies that choice through
root `MediaQuery`, independently of the app language. If the browser cannot
report a cycle, retain Flutter's platform fallback. Browsers expose their
own formatting preference rather than a separate native OS settings API.

Register an app-wide Hebrew Material localization delegate in the existing
locale infrastructure under `lib/util/async/`. Its Hebrew translation subclass
has a 12-hour default, and the inherited formatter switches to 24-hour time
when the platform or browser flag is true. Arabic and English retain their
existing Material translations and 12-hour defaults. The shell owns the root
format wrapper; feature widgets do not load their own localization bundles.
Reminder and appearance schedule labels, summaries, forms, and navigator
picker routes all inherit the same policy and localized strings.
Pickers inherit the live root `MediaQuery`; they must not capture and reapply
the hour-cycle flag when opened. An OS preference change while a picker is
open updates its presentation without changing the selected or saved time.

Preserve the synchronous behavior of Flutter's localization loader by mapping
its future with `then` and returning the translation directly. Do not wrap it
in an `async` function or an asynchronous future. Flutter's `SynchronousFuture`
then remains synchronous, so adding this presentation override does not defer
the first rendered frame. Remove the old page and picker localization wrappers.

Remove the obsolete header failure/format callbacks, panel format callback,
their caller arguments, and unused clock-control ARB keys. Keep the panel's
mutation failure callback, which still handles actual failures. Preserve the
legacy repository `__use24HourFormat` metadata for older clients and persisted
snapshots, but remove the obsolete `setUse24HourFormat` mutation method. Tests
load legacy snapshots directly to verify compatibility; current UI neither
reads nor changes that metadata. Persisted schedule times and scheduling
behavior are unchanged.

Web build jobs are parked behind manual dispatch in
`.github/workflows/disabled-web.yml`. No runs were returned for that workflow
by the 2026-10-02 investigation; that does not establish whether an older build
is still deployed. The browser fallback applies regardless of deployment state.

SPARC validation covers Arabic, English, and Hebrew under both hour cycles on
Android and iOS, agreement between reminders and appearance scheduling,
platform updates while pages and picker dialogs remain mounted, conflicting
legacy metadata, and content on
the first page/dialog frame without `pumpAndSettle`. Browser tests exercise
both hour cycles independently of the app language. Run the section-0 checker,
Flutter analysis, and the full Flutter test suite before reporting completion.
Physical Hebrew-device transition smoothness requires a connected mobile device;
none was available during this change.

Sources: Flutter's
[platform flag documentation](https://api.flutter.dev/flutter/widgets/MediaQueryData/alwaysUse24HourFormat.html),
[time formatter](https://api.flutter.dev/flutter/material/TimeOfDay/format.html),
and [synchronous future implementation](https://api.flutter.dev/flutter/foundation/SynchronousFuture/then.html),
plus the browser
[resolved hour-cycle documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/resolvedOptions).
