# Task 4 report: reset cancellation error visibility

## Implementation

- `resetData` now closes the active confirmation dialog before showing the
  remote-cancellation failure SnackBar.
- It still returns before local reset or navigation, preserving the existing
  failure behavior.

## TDD evidence

1. Strengthened the existing remote-cancellation-failure widget test.
2. RED: `flutter test --no-pub test/UserSettings/UserSettings_interactions_test.dart`
   failed at the new dialog assertion because one `Dialog` remained mounted.
3. GREEN: the same command passed after adding the pop-before-SnackBar change.

## ModalBarrier investigation

The initially requested `expect(find.byType(ModalBarrier), findsNothing)` did
not describe the dialog lifecycle reliably in this test harness. After the
dialog pop, the widget dump showed one standalone, lower overlay `ModalBarrier`
entry while the current page route and the SnackBar were visible above it. The
dialog itself was absent. The test therefore asserts the observable contract:
no `Dialog`, the `UserSettings` route remains current, no `FirstPage` route is
pushed, local notification data remains intact, and the SnackBar is hit-testable
on the page.

## Verification

`flutter test --no-pub test/UserSettings/UserSettings_interactions_test.dart`

Result: 13 tests passed.
