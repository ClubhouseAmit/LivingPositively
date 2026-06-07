# Mazilon Manual Regression Test Guide

Use this guide before merging UI, navigation, persistence, locale, notification, or Personal Plan changes. It is written for a tester using a local Flutter checkout and an Android emulator, with optional web checks.

## 1. Test Setup

### Devices

- Primary manual device: Android emulator, preferably `emulator-5554` / Pixel 9a2.
- Secondary checks when relevant: Chrome web and one narrow-screen Android viewport.
- App package: `com.matzilon.mezilon`.

### Baseline Commands

Run these before a manual regression pass:

```powershell
flutter pub get
adb devices
flutter analyze
flutter test
```

If the full suite is too slow for a quick smoke pass, run the focused high-risk checks:

```powershell
flutter test test/form/shareform_test.dart
flutter test test/file_service_custom_categories_test.dart test/personal_plan_custom_categories_test.dart
flutter test test/MenuTest/reminder_visibility_test.dart test/MenuTest/Wellness/wellnessTools_test.dart
flutter test test/EmergencyPhones_test.dart test/emergency_whatsapp_test.dart
```

For the custom-category Android regression:

```powershell
flutter test integration_test/custom_categories_e2e_test.dart -d emulator-5554
```

### Reset App State

Use a clean state when testing onboarding, disclaimer, first-run language, or saved-plan persistence:

```powershell
adb -s emulator-5554 shell pm clear com.matzilon.mezilon
flutter run -d emulator-5554
```

Use an existing state when testing persistence across restart, editing, repeated additions, notifications, and saved user data.

### Evidence Capture

For visual evidence:

```powershell
New-Item -ItemType Directory -Force .\tmp
adb -s emulator-5554 exec-out screencap -p > .\tmp\regression-screen.png
```

For UI-tree evidence when a tap seems wrong:

```powershell
New-Item -ItemType Directory -Force .\tmp
adb -s emulator-5554 exec-out uiautomator dump /dev/tty > .\tmp\ui-tree.xml
```

For crash logs:

```powershell
New-Item -ItemType Directory -Force .\tmp
adb -s emulator-5554 logcat -c
adb -s emulator-5554 shell pidof -s com.matzilon.mezilon
adb -s emulator-5554 logcat -d > .\tmp\logcat.txt
```

When testing Hebrew menu hit targets, use the UI tree or accessibility labels when possible rather than guessing from screenshots.

## 2. Smoke Pass

Run this after every branch that touches UI, navigation, localization, local persistence, PDF/share, phone/SOS, notifications, or the Personal Plan.

| Area | Steps | Expected Result |
|---|---|---|
| Launch | Install or run the app on Android. | App opens without crash, blank screen, or stuck loader. |
| Home | Confirm the main screen renders with bottom navigation and SOS button. | Home content is visible and no controls overlap. |
| Bottom nav | Tap Home, My Plan, Feel Good, and Support Tools. | Each tab opens the correct page and selected state updates. |
| SOS | Tap the center SOS floating button. | Emergency phone page opens. |
| Main menu | Open the hamburger/menu button from Home. | Menu appears near the tapped control and is not clipped. |
| Back handling | Press Android back from a secondary page. | App returns to Home or exits only from Home. |
| Restart | Close and reopen the app. | Saved local state still loads and no first-run screen reappears incorrectly. |

## 3. First-Run And Locale Regression

Use a clean app state for this section.

1. Launch the app.
2. Verify the disclaimer and language selector appear when expected.
3. Accept the disclaimer.
4. Choose Hebrew, English, and Arabic in separate passes.
5. Confirm RTL pages align correctly in Hebrew and Arabic.
6. Confirm English pages are LTR.
7. Restart the app.

Expected:

- The selected language persists after restart.
- Hebrew and Arabic text is readable, aligned correctly, and not clipped.
- Buttons and dropdowns remain tappable in both RTL and LTR.
- No raw localization keys such as `sharePage...` or `finishedDownloading` appear.

## 4. Personal Plan Flow

This is a high-risk regression area because the app stores safety-plan data and exports it.

1. Start from a clean state.
2. Complete the onboarding and Personal Plan form with realistic input in Hebrew.
3. Include at least one answer in each standard section.
4. Add emergency contacts when prompted.
5. Reach the final share/update page.
6. Tap `סיימתי!`.
7. Open My Plan from bottom navigation.
8. Restart the app and open My Plan again.

Expected:

- The flow can be completed without being trapped on a page.
- User-entered text remains in the original language.
- My Plan shows the saved sections in the expected order.
- Empty answers are not displayed as blank plan items.
- Bottom navigation and SOS remain usable after completing the flow.

## 5. Custom Categories Regression

Run this whenever `lib/form/shareform.dart`, `file_service.dart`, My Plan, PDF/share, or localization changes.

1. Reach the final Personal Plan share/update page.
2. Tap `+ הוספת קטגוריה`.
3. Tap the category title field.
4. Confirm all dropdown suggestions are shown:
   - `משפטים מחזקים שחשוב לי לזכור`
   - `אירועים מהעבר לתזכורת`
   - `דברים עלי שחשוב לי שנזכור`
   - `אפשרות לכתוב משהו מקורי משלי`
5. Choose a predefined title and enter a free-text description.
6. Save the category.
7. Tap `+ הוספת קטגוריה` again without leaving the page.
8. Tap the title field again.
9. Confirm the same dropdown suggestions appear again.
10. Add a second category using a completely custom title.
11. Edit the first saved category.
12. Confirm the edit form is prefilled and the dropdown suggestions are still available from the title field.
13. Save the edited category.
14. Delete the second category.
15. Restart the app and open My Plan.

Expected:

- Dropdown suggestions are available every time the user adds or edits a category.
- Custom title and description text is not translated by the app.
- Edited text replaces the old text and persists after restart.
- Deleted categories disappear immediately and do not reappear after restart.
- `סיימתי!` is below the custom-category area, not above it.
- My Plan and PDF/share output include only the current saved custom categories.

## 6. Emergency Phones And SOS

Run on Android with a realistic country selection.

1. Open SOS from the floating button.
2. Verify emergency phone categories render.
3. Tap a phone row.
4. If a confirmation/dialog appears, verify the displayed number and action text.
5. Add a manual contact through the phone form.
6. Edit the contact name and number.
7. Delete the contact.
8. Restart the app.

Expected:

- Emergency categories and numbers match the selected country.
- Phone links do not crash the app.
- Manual contacts can be added, edited, deleted, and persist correctly.
- Deletions do not return after restart.

## 7. Main Menu, Settings, Contact, And Reminders

Menu hit targets have regressed before, so verify each path separately.

1. Open the main menu from Home.
2. Tap About.
3. Return Home and open the menu again.
4. Tap Settings / `הגדרות`.
5. Change name, age, gender, and language.
6. Save or leave according to the current UI.
7. Return Home and verify displayed language/user data.
8. Open the menu again.
9. Tap Reminders / `תזכורות` if shown on Android.
10. Return Home and open the menu again.
11. Tap Contact Us.
12. Open the menu again and tap Share App.

Expected:

- About opens the About page.
- Settings opens user settings, not reminders.
- Reminders opens the reminder page, not settings.
- Contact Us opens the support URL in the right language:
  - Hebrew UI: Hebrew support site.
  - English/Arabic UI: English support site.
- Share App opens the platform share sheet without crashing.

## 8. Notifications Regression

Run on Android only. Reminder controls are intentionally hidden or disabled on unsupported platforms.

1. Open Reminders from the main menu.
2. Select a reminder time.
3. Save or schedule the reminder.
4. Leave the page and return.
5. Cancel the reminder.
6. Restart the app and return to Reminders.

Expected:

- Reminder page is reachable on Android.
- Time picker displays the selected hour/minute correctly.
- Scheduling does not crash or show plugin errors.
- Cancel action clears the active reminder state.
- Reminder controls do not appear on web/iOS/macOS if the platform gate says unsupported.

## 9. Journal And Positive Traits

1. Open the gratitude journal.
2. Add a gratitude item.
3. Edit the item.
4. Delete the item.
5. Restart the app.
6. Open Positive Traits.
7. Add a trait.
8. Edit and delete it.
9. Restart the app again.

Expected:

- Add/edit/delete works for both lists.
- User-entered Hebrew and English text remains exactly as typed.
- Empty states are readable.
- Deleted items do not reappear.
- The UI does not resize or overlap when text is long.

## 10. Feel Good And Wellness Tools

1. Open Feel Good from bottom navigation.
2. Add an image if the feature is available on the target platform.
3. Delete the image.
4. Open Support Tools / Wellness Tools.
5. Open a video item.
6. Toggle full-screen video mode if available.
7. Return to the main app.

Expected:

- Image picker permission handling does not crash the app.
- Deleted images disappear.
- Video list filters by the active locale.
- Full-screen mode hides bottom navigation and SOS while active.
- Exiting full-screen restores normal navigation.

## 11. PDF, Download, And Share

Run after creating a plan with standard sections, emergency phones, and custom categories.

1. Open the final share/update page.
2. Tap the share icon.
3. Cancel the platform share sheet.
4. Tap the download icon.
5. Check for success/failure toast.
6. Open the generated PDF if available.

Expected:

- Share and download actions do not crash.
- PDF includes standard plan sections, phone section, and custom categories.
- Hebrew/Arabic text direction is readable in exported content.
- Empty sections are omitted or rendered according to existing behavior.

## 12. Web Regression Pass

Run this when touching localization, layout, file/share behavior, or browser-specific code:

```powershell
flutter run -d chrome
```

Check:

- App launches in Chrome without console errors that break the UI.
- Hebrew and Arabic pages use RTL layout.
- Bottom navigation fits on narrow browser widths.
- Contact Us opens a new tab.
- Android-only reminder controls are hidden.
- Phone links and share/download behavior degrade gracefully.

## 13. Regression Triage Rules

Use these rules before filing or fixing a regression:

- Reproduce once from clean app state and once from existing saved state when persistence is involved.
- For Hebrew menu issues, verify the exact tapped row: `תזכורות` and `הגדרות` are separate flows.
- Capture a screenshot and, for hit-target bugs, a UI tree.
- Record device, locale, branch, commit, and whether app data was cleared.
- Do not infer Android behavior from Chrome or Chrome behavior from Android.
- If a bug affects saved Personal Plan content, PDF export, emergency phones, disclaimer, or reminders, treat it as high priority.

## 14. Suggested Release Checklist

Before a release candidate, complete this minimum manual set:

- Clean first-run flow in Hebrew.
- Existing-state restart/persistence check.
- Personal Plan completion and My Plan review.
- Custom categories add, second add dropdown, edit, delete, restart.
- SOS and emergency phone page.
- Main menu settings/reminders/contact/share.
- Reminder schedule/cancel on Android.
- PDF share/download from a populated plan.
- One English pass and one Arabic RTL pass.
- One Chrome launch/layout pass if the release includes web.

Record results as:

```text
Branch:
Commit:
Device:
Locale:
App data cleared: yes/no
Checks passed:
Issues found:
Screenshots/logs:
```
