# ADR-011: Approve Native SMS Composer Handoff

- **Status**: accepted
- **Date**: 2026-08-08
- **Deciders**: Lubac (repository collaborator)
- **Tags**: sms, mobile, crisis, platform-channel

## Context

The existing `openTextMessage` helper used an `sms:` URI through
`url_launcher`. That remains suitable as a non-mobile fallback, but a URI body
parameter does not provide a reliable, supported way to prefill an SMS message
on both Android and iOS. SOS and emergency-number flows need the recipient and
prepared text to reach the system composer without sending a message on the
user's behalf.

The volatile concern is the platform composer API. The stable Dart boundary is
the existing `openTextMessage(String, {String body = ''})` helper used by the
phone and emergency-dialog flows. Creating a new application service for this
single platform handoff would add an unsupported boundary without another
consumer.

## Decision

Retain `openTextMessage` as the public helper and approve its mobile platform
channel, `com.matzilon.mezilon/sms_compose`.

- The channel exposes one method: `composeSms`.
- Its arguments are typed strings: `number` (a non-blank recipient) and
  `body` (which may be empty).
- Android uses `ACTION_SENDTO` with an `smsto:` recipient and `sms_body` extra.
  It returns `false` for invalid arguments, unavailable handlers, or launch
  failures.
- iOS uses `MFMessageComposeViewController` when text messaging is available.
- Web and desktop retain the existing `sms:` URI fallback through
  `url_launcher`.
- Neither path sends automatically. A `true` result means the native composer
  was successfully handed off to the user; it does not mean that a recipient
  received a message. On iOS, dismissing the shown composer is a user decision,
  not an app-launch failure.

## Consequences

- SOS, emergency, and ordinary text actions keep one Dart-facing API and the
  existing `launchWithFeedback` behavior for an unavailable or rejected
  handoff.
- The platform-specific implementation remains confined to `MainActivity` and
  `AppDelegate`; callers do not construct SMS intents or platform views.
- No dependency, permission, background behavior, recipient targeting, or
  automatic delivery is introduced.

## Links

- `lib/util/Phone/phoneTextAndIcon.dart`
- `android/app/src/main/kotlin/com/example/mezilon/MainActivity.kt`
- `ios/Runner/AppDelegate.swift`
