# Living Positively Regression Test Suite

Full pre-release regression pass, derived from the 14-screen Figma flow (login, home, daily mood check-in, personal plan, tools hub, breathing/audio player, profile, trends, PDF export, and SOS crisis support). Covers functional, UI, negative, localization (Hebrew/RTL), accessibility, and basic security/non-functional checks across **125 test cases**.

This is the source-controlled version of the regression suite that previously lived only in `LP_Regression_Test_Suite.xlsx`. See [`manual-regression-test-guide.md`](./manual-regression-test-guide.md) for device setup, baseline commands, and evidence-capture steps to use while running these cases.

**Note on execution state:** this file is the test-case spec, not a run log. Track `Status` / `Actual Result` / `Tested By` / `Date` for a given pass outside this doc (a spreadsheet, a GitHub issue/project board, or a CI report) — keep this file limited to the stable case definitions so diffs stay meaningful in PR review.

## How To Use This Suite

1. For a quick smoke pass before a hotfix, run **Critical** and **High** priority cases only.
2. For a full regression before a major release, run every case.
3. Log any failure with repro steps, device, and build number wherever this pass's results are tracked.
4. Log reproducible defects in the project's issue tracker and reference the Test ID (e.g. `TC-062`) in the title.

### Priority Legend

- **Critical** — crash, data loss, or blocks a core flow (login, SOS/crisis contacts, mood save). Release-blocking.
- **High** — a primary feature is broken or clearly wrong (checklist, plan, exercise player, export).
- **Medium** — secondary feature or edge case; workaround usually exists.
- **Low** — cosmetic, copy, or very rare edge case.

### Type Legend

Functional · UI · Negative (invalid input / error handling) · Localization (Hebrew/RTL) · Accessibility · Performance · Security · Non-functional

### Assumptions

This suite was written from static design screens, not a live build or spec. Some flows (e.g. exact reminder scheduling rules, account deletion, data sync conflict handling) are inferred from typical app behavior and are flagged inline where the expected result says to confirm against the actual PRD.

### Case Counts By Module

| Module | Cases |
|---|---|
| 01. Auth & Onboarding | 8 |
| 02. Home Dashboard | 10 |
| 03. Daily Mood Check-in | 10 |
| 04. My Plan | 7 |
| 05. Category Checklist | 5 |
| 06. Tools — Exercises | 7 |
| 07. Tools — Photos | 6 |
| 08. Tools — Sentences | 6 |
| 09. Tools — Reminders | 6 |
| 10. Exercise Player | 10 |
| 11. Profile & Settings | 10 |
| 12. Trends & Analytics | 8 |
| 13. PDF Export | 8 |
| 14. SOS Help | 12 |
| 15. Cross-Cutting / Non-Functional | 12 |
| **Total** | **125** |

### Case Counts By Priority

| Priority | Cases |
|---|---|
| Critical | 17 |
| High | 34 |
| Medium | 57 |
| Low | 17 |

## Test Cases

### 01. Auth & Onboarding

**TC-001** · High · UI — Login screen renders all elements

Setup: Fresh app install, no saved session

Steps:
1. Launch the app
2. Observe the login/welcome screen

Expected:
- Logo, 'Living Positively' title, tagline, 'Google / Apple / Email' sign-in buttons, 'Continue without account' link, and the privacy disclaimer with lock icon all render, correctly right-aligned (RTL) and not clipped.

**TC-002** · Critical · Functional — Sign in with Google — happy path

Setup: Valid Google account available on device

Steps:
1. Tap 'המשך עם Google'
2. Complete Google auth consent
3. Return to app

Expected:
- User is authenticated and lands on the Home screen with their Google display name shown in the greeting.

**TC-003** · Critical · Functional — Sign in with Apple — happy path

Setup: Valid Apple ID available on device

Steps:
1. Tap 'המשך עם Apple'
2. Complete Apple auth (Face ID/passcode)
3. Return to app

Expected:
- User is authenticated and lands on the Home screen.

**TC-004** · High · Functional — Sign in with Email

Steps:
1. Tap 'התחבר עם מייל'
2. Enter a valid email/password or magic-link flow
3. Submit

Expected:
- User proceeds to an email/verification step and, on success, reaches Home.

**TC-005** · High · Functional — Continue without an account (guest mode)

Steps:
1. Tap 'המשך בלי חשבון'
2. Observe Home screen

Expected:
- User enters the app in guest mode. Data is stored locally only. Profile screen later reflects 'Data stored on this device only' and prompts to link an account for backup, matching the design.

**TC-006** · Medium · Negative — Cancel sign-in mid-flow

Setup: Google/Apple auth sheet is open

Steps:
1. Start Google or Apple sign-in
2. Cancel/back out of the system auth dialog

Expected:
- App returns cleanly to the login screen with no crash, no partial session, and no error toast loop.

**TC-007** · High · Negative — Sign-in attempt with no network connection

Setup: Device is in airplane mode

Steps:
1. Enable airplane mode
2. Attempt Google/Apple/Email sign-in

Expected:
- A clear, friendly offline error message is shown; app does not freeze or crash; retry is possible once network returns.

**TC-008** · Medium · Localization — RTL layout correctness on login screen

Steps:
1. Launch app on a Hebrew-locale device
2. Inspect alignment of logo, text, buttons, icons

Expected:
- All text is right-aligned, icons (Google/Apple glyphs) sit on the correct side of their labels, and the bottom home-indicator bar is centered.


### 02. Home Dashboard

**TC-009** · High · Functional — Greeting reflects user name and time of day

Setup: User is logged in with a display name; device time is set to afternoon

Steps:
1. Open the Home tab
2. Read the greeting header

Expected:
- Greeting shows a time-appropriate salutation (e.g. 'צהריים טובים') followed by the user's first name, with the supporting line 'טוב לראות אותך :)'.

**TC-010** · Medium · Functional — Motivational quote card refresh

Setup: Home screen is loaded

Steps:
1. Note the current quote text in the purple card
2. Tap 'טען עוד' (refresh)
3. Repeat 3-4 times

Expected:
- A different motivational quote is shown each time (no immediate repeat of the last-seen quote); animation/transition is smooth with no flicker.

**TC-011** · Critical · Functional — Open mood check-in from Home

Setup: Home screen is loaded

Steps: Tap the 'איך אני מרגיש עכשיו?' row

Expected:
- The daily mood check-in modal opens at step 1/2 ('איך אני מרגיש היום?').

**TC-012** · High · Functional — Personal treatments checklist shows correct progress

Setup: User has completed 1 of 4 personal-treatment tasks

Steps:
1. Open Home
2. Inspect the '(1/4)' counter and the checkbox states below it

Expected:
- Counter accurately reflects completed vs total items; the completed item shows a filled green check and strikethrough/dim styling; incomplete items show an empty circle.

**TC-013** · High · Functional — Complete a checklist item from Home

Setup: At least one incomplete item is visible

Steps: Tap the empty circle next to an incomplete item

Expected:
- Item is marked complete instantly (optimistic UI), the '(x/4)' counter increments, and the change is reflected in the My Plan progress ring without needing a manual refresh.

**TC-014** · Medium · Functional — Un-complete a checklist item from Home

Setup: At least one completed item is visible

Steps: Tap the checkmark of a completed item to toggle it back

Expected:
- Item returns to incomplete state and the progress counters (Home + My Plan) decrement accordingly.

**TC-015** · Critical · UI — Bottom navigation bar — all tabs present

Setup: Any main app screen is open

Steps: Inspect the bottom tab bar

Expected:
- Five icons are present in the correct RTL order and labelled: פרופיל (Profile), כלים (Tools), SOS עזרה (Help), התכנית (Plan), בית (Home).

**TC-016** · Critical · Functional — Bottom navigation — each tab routes correctly

Setup: Any main app screen is open

Steps:
1. Tap פרופיל, verify screen
2. Tap כלים, verify screen
3. Tap עזרה, verify screen
4. Tap התכנית, verify screen
5. Tap בית, verify screen

Expected:
- Each tap navigates to its corresponding screen with no lag (<300ms) and the tapped icon becomes visually active/highlighted.

**TC-017** · Low · UI — Active tab indicator on Home

Setup: Home screen is open

Steps: Observe the בית icon while on the Home screen

Expected:
- The Home icon is visually highlighted (filled/dark pill) to indicate the current tab, matching the design's active state.

**TC-018** · Medium · Functional — Home state for a brand-new user

Setup: Freshly created account, no check-ins or tasks completed yet

Steps:
1. Log in as a new user
2. Open Home

Expected:
- Greeting still renders correctly; checklist shows 0/N with a sensible empty/starter state rather than a blank area or a crash; a default motivational quote is present.


### 03. Daily Mood Check-in

**TC-019** · Medium · UI — Step indicator and title render

Setup: Mood check-in modal is open

Steps:
1. Open the check-in modal
2. Inspect the header

Expected:
- Header shows 'מעקב יומי 1/2' and the question 'איך אני מרגיש היום?' directly below it.

**TC-020** · Critical · Functional — Select a mood — single-select behavior

Setup: Mood check-in modal is open at step 1/2

Steps:
1. Tap 'טוב'
2. Then tap 'מצוין'
3. Observe selection state

Expected:
- Only one mood is ever selected at a time; selecting a new mood clearly deselects the previous one (border/highlight moves); the emoji + label pair is legible for all 5 options (Sad/נמוך/בסדר/טוב/מצוין).

**TC-021** · High · Functional — Multi-select feeling tags

Setup: A mood is selected

Steps:
1. Tap 'רגוע'
2. Tap 'עצוב'
3. Tap 'מוקאג'
4. Tap 'רגוע' again to deselect

Expected:
- Multiple tags can be active simultaneously (shown filled/purple); tapping an active tag again removes only that tag and leaves the others selected.

**TC-022** · Medium · Functional — Add a custom feeling tag

Setup: Check-in modal is open

Steps:
1. Tap 'הוסף משלך +'
2. Type a custom word (e.g. 'נרגש')
3. Confirm

Expected:
- The custom tag appears as a new selectable chip in the same style as the presets and is selected by default.

**TC-023** · Medium · Functional — Free-text journal entry

Setup: Check-in modal is open

Steps:
1. Tap the 'משהו שרוצה להישאר כתוב...' field
2. Type a multi-line note
3. Dismiss keyboard

Expected:
- Text field accepts multi-line Hebrew input, expands sensibly, and the entered text is retained if the user scrolls away and back before submitting.

**TC-024** · Critical · Functional — Complete check-in — happy path

Setup: A mood and at least one tag are selected

Steps: Tap 'המשך לתרופות האישיות שלי'

Expected:
- User advances to step 2/2 (personal treatments), and the mood entry for today is persisted (verify later in Trends).

**TC-025** · High · Negative — Attempt to continue with no mood selected

Setup: Check-in modal is open, no mood tapped

Steps:
1. Leave all moods unselected
2. Tap 'המשך לתרופות האישיות שלי'

Expected:
- Per PRD: either the button is disabled/no-ops, or a validation message prompts the user to pick a mood — confirm actual intended behavior with product owner and update this expectation before first run.

**TC-026** · Medium · Functional — Dismiss check-in via 'Not now'

Setup: Check-in modal is open, some fields filled in

Steps:
1. Fill in a mood/tags
2. Tap 'לא עכשיו'

Expected:
- Modal closes without saving a mood entry for today; Home's 'How do I feel now' row remains in its not-yet-logged state so the user is prompted again later.

**TC-027** · Medium · Functional — Dismiss check-in via close (X)

Setup: Check-in modal is open

Steps: Tap the X in the top-left corner

Expected:
- Modal closes with the same no-save behavior as 'Not now' (or a confirmation prompt if unsaved changes exist — confirm with design).

**TC-028** · High · Negative — Duplicate check-in on the same day

Setup: User already submitted a mood check-in today

Steps:
1. Re-open the check-in modal from Home
2. Submit a different mood

Expected:
- Confirm intended behavior: either today's entry is overwritten with the latest submission, or the app blocks a second entry with a clear message. Verify Trends shows only one data point for today either way.


### 04. My Plan

**TC-029** · High · Functional — Overall progress ring accuracy

Setup: User has a mix of complete/incomplete items across all plan categories

Steps:
1. Open התכנית (My Plan)
2. Compare the % shown in the ring to (completed items / total items) across all categories

Expected:
- Displayed percentage matches the actual completion ratio (e.g. 80%) and the ring visually fills to the matching arc length.

**TC-030** · High · UI — All plan categories present with correct counts

Setup: My Plan screen is open

Steps: Inspect each row and its numeric badge

Expected:
- Categories render as: סימפטומים ואזהרה (warning signs, badge 3), טריגרים וגורמי הסלמה (triggers, badge 3), כלים לאיזון ואורח חיים בריא (tools, badge 4), תמיכה ועזרה מהסביבה (support, badge 2), אנשי קשר כשיש צורך (emergency contacts, badge 2) — each with its distinct icon/color.

**TC-031** · High · Functional — Drill into a plan category

Setup: My Plan screen is open

Steps: Tap 'כלים לאיזון ואורח חיים בריא'

Expected:
- Navigates to the category detail screen showing its checklist ('הליכה של 20 דקות בשכונה', 'תרגול נשימה של 4 היסודות', etc.) with an 'עריכה' (edit) affordance and back navigation.

**TC-032** · Medium · Functional — Progress ring updates after completing an item in a category

Setup: A category detail screen is open with an incomplete item

Steps:
1. Mark an item complete inside the category
2. Navigate back to My Plan

Expected:
- The overall progress ring percentage and the category's item count both update to reflect the change immediately.

**TC-033** · Medium · Functional — Edit mode on a category

Setup: Category detail screen is open

Steps:
1. Tap 'עריכה' (Edit)
2. Attempt to reorder or remove an item
3. Save

Expected:
- User can reorder/remove personal items; system-suggested items (if any are non-removable) are clearly distinguished; changes persist after leaving and re-entering the screen.

**TC-034** · Low · UI — Forward/share arrow on category header

Setup: Category detail screen is open

Steps: Tap the top-right forward arrow icon

Expected:
- Confirm intended action (e.g. share this category, or advance to next category) and verify it fires correctly with no dead tap.

**TC-035** · Medium · Functional — My Plan reflects a completed mood check-in

Setup: User just completed today's mood check-in

Steps:
1. Complete a check-in from Home
2. Open My Plan

Expected:
- Any check-in-linked task/category state updates accordingly (e.g. a 'daily check-in' item, if tracked in the plan, shows as done for today).


### 05. Category Checklist

**TC-036** · Medium · UI — Checklist item list renders correctly

Setup: A plan category with items is open

Steps: Open a category detail screen

Expected:
- Each item shows full title text without truncation/clipping, correct RTL alignment, and a tappable checkbox on the leading (right) edge.

**TC-037** · High · Functional — Toggle item completion

Setup: Category detail screen is open

Steps:
1. Tap an item's checkbox
2. Tap it again

Expected:
- State toggles cleanly between complete/incomplete with immediate visual feedback (green check ↔ empty circle) and no double-fire on fast taps.

**TC-038** · Medium · Functional — Add a new personal item

Setup: Category detail screen is open, in edit mode if required

Steps:
1. Tap the '+' add-item control
2. Enter item text
3. Confirm

Expected:
- New item appears at the expected position in the list, is included in the category's badge count, and persists after navigating away and back.

**TC-039** · Medium · Functional — Remove an item

Setup: Category has at least one user-added item

Steps:
1. Enter edit mode
2. Delete a user-added item
3. Confirm/save

Expected:
- Item is removed from the list and the category/overall progress counts recalculate correctly.

**TC-040** · Low · UI — Empty category state

Setup: A category with zero items (edge case / new user)

Steps: Open a category with no items

Expected:
- A sensible empty state (illustration/copy + call to action to add an item) is shown instead of a blank screen.


### 06. Tools — Exercises

**TC-041** · High · UI — Tools hub tab bar renders and defaults correctly

Steps:
1. Tap כלים from the bottom nav
2. Observe the 4 sub-tabs

Expected:
- Tabs render in order: תזכורות, משפטים, תמונות, תרגולים (RTL order matches design) and the screen opens on a sensible default tab (confirm intended default with product).

**TC-042** · Medium · UI — Switching sub-tabs updates content and active indicator

Setup: Tools hub is open

Steps: Tap through all 4 sub-tabs in sequence

Expected:
- Each tap swaps the content area instantly, the tapped tab is visually active (white pill), and no content from the previous tab flashes/lingers.

**TC-043** · High · UI — Featured/recommended exercise card

Setup: Exercises tab is open

Steps: Inspect the top featured card

Expected:
- Card shows the 'מומלץ עכשיו' badge, thumbnail image, title 'תרגול 4 היסודות להפחתת לחץ', meta line '9 דקות · אדמה · מים · אוויר · אור', and a play button — all legible over the image.

**TC-044** · Critical · Functional — Launch featured exercise

Setup: Exercises tab is open

Steps: Tap the play button or 'התחל תרגול' on the featured card

Expected:
- The breathing/audio exercise player screen opens and begins loading/playing the correct content.

**TC-045** · Medium · Functional — Additional exercises list scrolls and plays

Setup: Exercises tab is open, more than one item in 'סרטונים נוספים'

Steps:
1. Scroll the list
2. Tap a non-featured video's play icon

Expected:
- List scrolls smoothly (and paginates/lazy-loads if long); tapping a list item's play button opens the player with that specific content, not the featured one.

**TC-046** · Low · Functional — Filter/sort control on exercises list

Setup: Exercises tab is open

Steps:
1. Tap the filter icon next to 'סרטונים נוספים'
2. Apply a filter

Expected:
- Filter options apply and the list updates accordingly; clearing the filter restores the full list.

**TC-047** · Medium · Negative — Exercises tab with no network / video CDN unreachable

Setup: Airplane mode enabled

Steps:
1. Open Exercises tab offline
2. Attempt to play a video

Expected:
- A clear offline/error state is shown per item rather than an infinite spinner or crash; previously downloaded/cached exercises (if supported) still play.


### 07. Tools — Photos

**TC-048** · Medium · UI — Photo grid renders with captions

Setup: Photos tab is open, user has existing photos

Steps: Open the תמונות tab

Expected:
- Existing photos render in a 2-column grid with their captions ('ארוחת שישי בבית', 'טיול בגליל, אביב', 'אלוף אזורי בג'ודו') legible over the image.

**TC-049** · High · Functional — Add a new photo

Setup: Photos tab is open

Steps:
1. Tap the dashed 'הוספת תמונה +' tile
2. Choose an image from gallery/camera
3. Confirm/caption it

Expected:
- Photo picker opens, selected image uploads/saves, and the new tile appears in the grid without needing to leave and re-enter the tab.

**TC-050** · Medium · Negative — Add an oversized or unsupported file

Setup: Photos tab is open

Steps: Attempt to select a very large image or an unsupported file type (if picker allows)

Expected:
- App either compresses/handles it gracefully or shows a clear size/format error — no crash or infinite upload spinner.

**TC-051** · Medium · Functional — Delete a photo

Setup: At least one user-added photo exists

Steps:
1. Long-press or open a photo's options menu
2. Choose delete
3. Confirm

Expected:
- Photo is removed from the grid after confirmation and does not reappear after app restart.

**TC-052** · Low · Functional — Open photo detail/full-screen view

Setup: Photos tab has at least one photo

Steps: Tap an existing photo tile

Expected:
- Photo opens full-screen (or in a lightbox) with its caption visible and an obvious way to close back to the grid.

**TC-053** · Medium · Negative — Cancel the add-photo flow midway

Setup: Photo picker is open

Steps:
1. Tap 'הוספת תמונה'
2. Cancel out of the system picker before selecting

Expected:
- Returns cleanly to the Photos grid with no placeholder/broken tile added.


### 08. Tools — Sentences

**TC-054** · Medium · UI — Affirmation cards render correctly

Setup: Sentences tab is open

Steps: Open the משפטים tab

Expected:
- Pre-loaded affirmation quote cards render with the quote-mark icon, full Hebrew text (no clipping), and consistent card styling.

**TC-055** · Medium · Functional — Add a custom affirmation

Setup: Sentences tab is open

Steps:
1. Tap 'הוספת משפט שלי +'
2. Enter custom text
3. Save

Expected:
- New affirmation appears in the list in the same style as presets and persists after navigating away.

**TC-056** · Low · Functional — Edit a custom affirmation

Setup: A user-created affirmation exists

Steps:
1. Open the custom affirmation's edit option
2. Change the text
3. Save

Expected:
- Updated text is reflected immediately in the list.

**TC-057** · Medium · Functional — Delete a custom affirmation

Setup: A user-created affirmation exists

Steps:
1. Open its options menu
2. Delete
3. Confirm

Expected:
- Item is removed from the list and does not reappear after app restart.

**TC-058** · Low · Negative — Save an empty affirmation

Setup: Add-affirmation input is open

Steps:
1. Leave the text field empty
2. Tap Save

Expected:
- Save is blocked or button is disabled — no blank card is added to the list.

**TC-059** · Low · Negative — Very long affirmation text

Setup: Add-affirmation input is open

Steps:
1. Paste an unusually long string (500+ characters)
2. Save

Expected:
- Input is either capped at a sane limit with visible feedback, or the resulting card truncates/expands gracefully without breaking layout.


### 09. Tools — Reminders

**TC-060** · Medium · UI — Empty state for Reminders

Setup: No reminders configured yet

Steps: Open the תזכורות tab

Expected:
- A clear empty state with explanatory copy and a call-to-action to create the first reminder is shown (not a blank screen).

**TC-061** · High · Functional — Create a new reminder

Setup: Reminders tab is open

Steps:
1. Tap the create/add control
2. Set a time, frequency, and message
3. Save

Expected:
- Reminder is created, appears in the list with correct time/frequency summary, and a system notification permission prompt appears if not yet granted.

**TC-062** · Critical · Functional — Reminder fires at the scheduled time

Setup: A reminder is set for 2 minutes from now

Steps: Wait for the scheduled time with the app backgrounded

Expected:
- A push notification is delivered on time with the correct message, and tapping it deep-links into the relevant screen (e.g. mood check-in).

**TC-063** · Medium · Functional — Edit an existing reminder

Setup: At least one reminder exists

Steps:
1. Open the reminder
2. Change its time/frequency
3. Save

Expected:
- Updated schedule is reflected in the list and the old scheduled notification is cancelled/replaced (no duplicate firing).

**TC-064** · Medium · Functional — Delete a reminder

Setup: At least one reminder exists

Steps:
1. Delete a reminder
2. Confirm

Expected:
- Reminder is removed from the list and no notification fires for it afterward.

**TC-065** · High · Functional — Reminders persist after app restart / device reboot

Setup: At least one reminder is configured

Steps:
1. Force-close the app (or reboot the device)
2. Reopen the app and Reminders tab

Expected:
- All previously configured reminders are still present and still scheduled to fire.


### 10. Exercise Player

**TC-066** · High · UI — 4-stage progress tabs render

Setup: An exercise (e.g. '4 Elements') is playing

Steps:
1. Open the player
2. Inspect the top stage tabs

Expected:
- Four stages (אור / מים / אוויר / אדמה) render as progress segments; the current stage ('אוויר') is highlighted while completed stages and upcoming stages are visually distinct.

**TC-067** · Critical · Functional — Countdown timer accuracy

Setup: Exercise player is open on the 'אוויר' stage showing 02:15

Steps:
1. Start playback
2. Time the countdown against a stopwatch for 30 seconds

Expected:
- Timer counts down in real time (±1s tolerance) and does not freeze, jump, or run backward.

**TC-068** · Critical · Functional — Play / Pause toggle

Setup: Exercise is playing

Steps:
1. Tap the center pause button
2. Tap it again to resume

Expected:
- Audio and timer pause together on first tap (icon changes to play ▶) and resume together in sync on second tap.

**TC-069** · Medium · Functional — Skip forward / back between stages

Setup: Exercise player is open, not on the first or last stage

Steps:
1. Tap the skip-forward control
2. Tap the skip-back control

Expected:
- Playback jumps to the next/previous stage's content and the stage tab indicator updates to match.

**TC-070** · Medium · Functional — Playback speed toggle

Setup: Exercise player is open

Steps: Tap the 'X2' speed control repeatedly

Expected:
- Label cycles through the supported speeds (e.g. x1 → x2 → back to x1) and audio/timer pacing changes accordingly.

**TC-071** · Medium · Functional — Loop/repeat toggle

Setup: Exercise player is open

Steps:
1. Enable the loop icon
2. Let the current stage finish

Expected:
- When enabled, the stage (or full exercise) restarts automatically at completion instead of stopping or auto-advancing.

**TC-072** · High · Functional — Backgrounding behavior during playback

Setup: Exercise is actively playing

Steps:
1. Send the app to background (Home button/gesture)
2. Return to the app after 10-15 seconds

Expected:
- Confirm intended behavior: audio continues in background (common for guided-breathing apps) or pauses and resumes correctly on return — no audio overlap/duplication and timer stays in sync.

**TC-073** · Medium · Functional — Exercise completion flow

Setup: Exercise reaches its final stage and finishes with loop disabled

Steps: Let the exercise play to completion

Expected:
- Player shows a clear completion state, the activity is logged (reflected later in Trends' activity count), and the user is returned to the Tools/Exercises screen or a summary.

**TC-074** · Low · Non-functional — Screen stays awake during a session

Setup: Exercise player is actively playing

Steps:
1. Start an exercise
2. Leave the device untouched for the device's normal auto-lock duration

Expected:
- Screen does not auto-dim/lock mid-session (or if it does per OS policy, audio/timer continue unaffected) — confirm intended behavior with design.

**TC-075** · Medium · Negative — Playback with device on silent/mute

Setup: Device silent switch is enabled

Steps: Start an exercise with device muted

Expected:
- Confirm and verify the intended behavior (e.g. guided-audio media respects a 'media volume' channel and still plays, or a clear muted indicator is shown) — avoid a silent, confusing session.


### 11. Profile & Settings

**TC-076** · Medium · UI — Profile screen renders user info

Setup: User is logged in (guest or linked account)

Steps: Open פרופיל

Expected:
- User's name and account-status subtext ('הנתונים נשמרים על המכשיר בלבד' for guest users) render correctly.

**TC-077** · High · Functional — Link a guest account to Apple

Setup: User is currently in guest mode

Steps:
1. Tap the 'Apple' link-account button in the purple prompt
2. Complete Apple auth

Expected:
- Account becomes linked; the linking prompt disappears or updates to a linked/synced state; existing local data (check-ins, plan, photos) is preserved and now backed up.

**TC-078** · High · Functional — Link a guest account to Google

Setup: User is currently in guest mode

Steps:
1. Tap the 'Google' link-account button
2. Complete Google auth

Expected:
- Account becomes linked with the same data-preservation guarantee as the Apple case above.

**TC-079** · Medium · Functional — My Tracking summary links to Trends

Setup: Profile screen is open, user has check-in history

Steps: Tap 'מגמות והיסטוריה'

Expected:
- Navigates to the Trends screen; the average shown on the Profile card (e.g. 3.5 מתוך 5) matches the value shown on the Trends screen for the same period.

**TC-080** · Medium · Functional — PDF export entry point

Setup: Profile screen is open

Steps: Tap the 'PDF — ייצוא ושיתוף עם מטפל' row

Expected:
- The export/share modal opens (see module 13 for detailed export cases).

**TC-081** · Medium · Functional — Change appearance to Dark

Setup: Profile > Settings section is visible

Steps: Tap 'כהה' under מראה

Expected:
- Entire app switches to a dark color scheme immediately, with sufficient contrast maintained on all screens (Home, Tools, Player, etc.).

**TC-082** · Medium · Functional — Change appearance to Light

Setup: App is currently in Dark or System mode

Steps: Tap 'בהיר' under מראה

Expected:
- App switches to the light/cream color scheme shown in the original design.

**TC-083** · Low · Functional — Appearance set to System

Setup: Device OS theme can be toggled

Steps:
1. Tap 'מערכת'
2. Toggle the device's OS-level dark mode setting
3. Return to the app

Expected:
- App theme follows the OS setting automatically without needing an app restart.

**TC-084** · Medium · Functional — Settings persist after restart

Setup: Appearance is set to Dark (or any non-default)

Steps:
1. Force-close the app
2. Reopen it

Expected:
- The previously chosen appearance setting is still applied on launch.

**TC-085** · High · Security — Account/data deletion flow

Setup: User is logged in

Steps:
1. Locate and trigger the delete-account / delete-my-data option (if present in this build)
2. Confirm deletion

Expected:
- All personal data (check-ins, journal text, photos, plan) is irreversibly deleted both locally and from any backend, and the user is returned to the login screen. Flag as a gap if this control does not yet exist — required for privacy-law compliance (health-adjacent data).


### 12. Trends & Analytics

**TC-086** · Medium · UI — Default tab and layout

Setup: Trends screen is opened from Profile

Steps: Open 'מגמות והיסטוריה'

Expected:
- Screen opens with tabs יום / שבוע / חודש / שנה; the 'שבוע' (Week) tab is active by default per the design, showing the mood line chart plotted against emoji y-axis labels.

**TC-087** · Medium · Functional — Switching time-range tabs updates the chart

Setup: Trends screen is open, user has data across several weeks

Steps:
1. Tap יום, verify chart scope
2. Tap חודש, verify chart scope
3. Tap שנה, verify chart scope

Expected:
- Chart data, x-axis labels, and the stats row (average / streak / activities) all recalculate to match the selected range with no stale data left over from the previous tab.

**TC-088** · High · Functional — Chart data-point accuracy

Setup: A known set of mood check-ins exists for the current week (test data)

Steps: Cross-reference each plotted point on the weekly chart against the actual logged mood values for those days

Expected:
- Each point matches the logged mood exactly (correct day, correct emoji-equivalent value); missing days show no point rather than a false zero.

**TC-089** · Medium · Functional — Stats row accuracy

Setup: Trends screen is open with known history

Steps:
1. Manually compute expected average score, day-streak, and completed-activity count for the period
2. Compare to the displayed '3.5 / 6 / 15' style stats

Expected:
- All three stats match the manually computed values.

**TC-090** · Low · Functional — Weekly insight text

Setup: Trends screen is open with varied data (some higher, some lower-rated days)

Steps: Read the 'מה נראה השבוע' insight paragraph

Expected:
- Insight text is coherent, references real patterns in the underlying data (not a generic/static placeholder unless intentionally so), and reads correctly in Hebrew.

**TC-091** · Medium · Functional — Empty-state for a new user

Setup: User has zero check-in history

Steps: Open Trends as a brand-new user

Expected:
- Chart and stats show a clear empty/zero state with encouraging copy to start checking in, rather than a broken chart or dashes.

**TC-092** · Low · Non-functional — Chart readability with a full year of data

Setup: User has ~365 days of check-in history (test/seed data)

Steps: Switch to the שנה (Year) tab

Expected:
- Chart renders without performance lag, points/labels don't overlap into unreadable clutter, and scrolling/zooming (if supported) works smoothly.

**TC-093** · Low · UI — Back navigation from Trends

Setup: Trends screen is open

Steps: Tap the back arrow (top-left)

Expected:
- Returns to the Profile screen without losing the Profile screen's scroll position.


### 13. PDF Export

**TC-094** · Medium · UI — Export modal content and defaults

Setup: Export modal is open from Profile

Steps:
1. Open 'ייצוא ושיתוף'
2. Read the description and check the toggle's default state

Expected:
- Description text explains the export covers the last month's mood, activities and trends; 'לכלול את טקסט היומן' toggle is ON by default, matching the design.

**TC-095** · High · Functional — Toggle journal text off and export

Setup: Export modal is open

Steps:
1. Turn OFF 'לכלול את טקסט היומן'
2. Tap 'יצירת PDF ושיתוף'
3. Open the generated PDF

Expected:
- Generated PDF includes mood/activity/trend summary but excludes any free-text journal entries.

**TC-096** · High · Functional — Export with journal text included (default)

Setup: Export modal is open, toggle left ON

Steps:
1. Tap 'יצירת PDF ושיתוף'
2. Open the generated PDF

Expected:
- Generated PDF includes the mood/activity/trend summary AND the user's journal text entries for the period.

**TC-097** · High · Functional — Share sheet opens with a valid file

Setup: PDF generation has completed

Steps: Observe the native share sheet after generation

Expected:
- OS share sheet opens with relevant targets (Mail, Messages, AirDrop/Nearby Share, Save to Files, etc.) and the attached file is a valid, openable PDF.

**TC-098** · Medium · Functional — PDF content accuracy spot-check

Setup: A generated PDF is available, underlying data is known

Steps: Compare 2-3 data points in the PDF (e.g. weekly average, a specific journal date) against the in-app Trends screen

Expected:
- PDF values match the in-app values exactly for the same period.

**TC-099** · Medium · Negative — Cancel export mid-generation

Setup: PDF is generating (simulate slow device/large history if possible)

Steps: Tap outside the modal or press back while the spinner/progress is showing

Expected:
- Generation is cancelled cleanly with no orphaned/corrupt file left in the share sheet or device storage.

**TC-100** · Medium · Negative — Export with no history

Setup: Brand-new user with zero logged data

Steps:
1. Open export modal
2. Tap 'יצירת PDF ושיתוף'

Expected:
- Export either completes with a clear 'no data yet' PDF/state or the CTA is disabled with explanatory copy — it does not crash or produce a broken/blank file.

**TC-101** · Low · Negative — Export while offline

Setup: Airplane mode enabled

Steps: Attempt to generate and share a PDF while offline

Expected:
- If generation is fully local it should still succeed; if it depends on a backend call, a clear offline error is shown instead of a hang.


### 14. SOS Help

**TC-102** · Critical · Performance — SOS is reachable within 2 taps from anywhere

Setup: App is open on any arbitrary screen (deep in a sub-flow, e.g. inside the exercise player)

Steps: From several different deep screens, tap the SOS icon in the bottom nav

Expected:
- SOS/Help screen opens in ≤1 tap from the bottom nav on every single screen, and loads in under 1 second with no loading spinner blocking the contact list.

**TC-103** · Critical · UI — Help Now screen content

Setup: SOS screen is open

Steps: Read the header and supporting text

Expected:
- Headline 'עזרה עכשיו' and empathetic subtext ('אתה לא צריך לעבור את זה לבד...') render fully and correctly, with no truncation.

**TC-104** · Critical · Functional — Emergency contact list accuracy

Setup: SOS screen is open

Steps: Inspect every contact row's name, role, and phone number

Expected:
- All pre-loaded contacts render with correct label and number, matching config (e.g. 'ער‎ ן – עזרה ראשונה נפשית' 1201, 'מד"א – חירום רפואי 24/7' 101, plus the user's personal support contacts, e.g. נועה/דני).

**TC-105** · Critical · Functional — Dial button places a call

Setup: SOS screen is open, on a device capable of making calls

Steps: Tap 'חיוג' next to any contact

Expected:
- Device's native phone dialer opens (or immediately places the call, per OS convention) with the correct number pre-filled — no typo, no wrong contact.

**TC-106** · Critical · Functional — Emergency numbers are correct and untouched

Setup: SOS screen is open

Steps: Verify 101 and 1201 (or the locale-appropriate national crisis/emergency numbers) against the official published numbers

Expected:
- Numbers exactly match the real national emergency/crisis line numbers for the target country/locale — this must never be wrong.

**TC-107** · Medium · Functional — Add a custom personal support contact

Setup: SOS screen is open (assuming this is configured from Profile/My Plan support category)

Steps:
1. Navigate to add a personal contact (via My Plan > support category)
2. Fill in name, relation, number
3. Save
4. Return to SOS screen

Expected:
- New contact appears correctly in the SOS list with a working Dial button.

**TC-108** · Medium · Functional — Remove a custom support contact

Setup: A user-added contact exists

Steps:
1. Remove it from its source (My Plan > support category)
2. Return to SOS screen

Expected:
- Contact no longer appears in the SOS list. Default emergency services entries (101/1201-equivalent) can never be removed.

**TC-109** · High · Functional — 'Moment exercise' quick action

Setup: SOS screen is open

Steps: Tap 'תרגול הרגע'

Expected:
- Immediately launches a short calming/breathing exercise (bypassing the Tools hub navigation) appropriate for an acute-distress moment.

**TC-110** · Medium · Functional — 'My Plan' quick action from SOS

Setup: SOS screen is open

Steps: Tap 'התכנית שלי'

Expected:
- Navigates directly to the My Plan screen.

**TC-111** · Critical · Functional — SOS works with no network connection

Setup: Airplane mode enabled / no signal

Steps:
1. Open SOS screen offline
2. Tap Dial on a contact

Expected:
- Screen and contact list render fully from local/cached data with no network dependency, and the native dialer still opens correctly (standard cellular calls don't require data connectivity).

**TC-112** · High · Accessibility — SOS screen accessible with screen reader

Setup: VoiceOver/TalkBack enabled

Steps:
1. Navigate the SOS screen using the screen reader
2. Confirm each contact and its Dial button are announced clearly

Expected:
- Every contact name, role, number, and the Dial action are properly labelled and reachable in a logical order — this is a safety-critical screen and must be fully accessible.

**TC-113** · Medium · UI — SOS icon visually distinct in bottom nav

Setup: Any main screen is open

Steps: Compare the SOS icon's styling to the other 4 nav icons

Expected:
- SOS retains its distinct dark/badge styling (as in the design) so it's instantly recognizable in a moment of distress, on both light and dark app themes.


### 15. Cross-Cutting / Non-Functional

**TC-114** · High · Localization — RTL correctness across the full app

Steps:
1. Walk through all main screens (Home, Plan, Tools x4 tabs, Player, Profile, Trends, SOS)
2. Check text alignment, icon placement, chevrons, and swipe/back gesture direction

Expected:
- Every screen is fully mirrored for RTL: text right-aligned, back chevrons point right, tab order reads right-to-left, and no LTR-leftover elements (e.g. mis-mirrored icons) are present.

**TC-115** · Medium · Localization — Hebrew text rendering

Steps: Inspect longer Hebrew strings across screens, including nikud/quote characters (e.g. 'שׁוֹמֵר עָלַי')

Expected:
- All Hebrew renders with correct characters, no tofu/box glyphs, no clipped or overlapping text, and nikud (if used) displays correctly on both iOS and Android.

**TC-116** · High · Performance — Cold start time

Setup: App is force-closed / not in memory

Steps:
1. Launch the app from a cold start
2. Time to first interactive screen

Expected:
- App reaches the login or Home screen within an acceptable threshold (confirm target, e.g. <2-3s) on both a current-gen and a low/mid-range device.

**TC-117** · High · Functional — Data persists after force-close

Setup: User has made several changes across the app (mood check-in, plan edits, a new photo)

Steps:
1. Force-close the app completely
2. Reopen it

Expected:
- All changes are present exactly as left; no data loss or reversion to a stale cached state.

**TC-118** · Medium · Accessibility — Screen reader labels on interactive elements

Setup: VoiceOver/TalkBack enabled

Steps: Navigate Home, mood check-in, and Tools hub using only the screen reader

Expected:
- Every button, tab, checkbox, and icon-only control has a meaningful accessible label (not 'button' or blank) and focus order follows a logical reading order.

**TC-119** · Medium · Accessibility — Dynamic type / large font support

Setup: Device accessibility text size is set to a large/maximum setting

Steps:
1. Increase system font size to max
2. Revisit Home, check-in modal, and Profile

Expected:
- Text scales up without clipping, overlapping, or pushing critical buttons off-screen; layouts reflow or become scrollable as needed.

**TC-120** · Low · Accessibility — Color contrast

Steps: Check contrast ratio of key text (navy on cream, white on purple buttons, muted gray secondary text)

Expected:
- Primary text/background combinations meet at least WCAG AA contrast ratios (4.5:1 for normal text).

**TC-121** · Medium · Functional — Deep link / notification tap routing

Setup: A reminder notification has been received

Steps: Tap the notification from the lock screen/notification shade

Expected:
- App opens directly to the relevant screen (e.g. mood check-in) rather than always defaulting to Home.

**TC-122** · Low · UI — Splash screen and status bar styling

Steps: Cold-launch the app and observe the splash screen and status bar colors

Expected:
- Splash screen matches brand styling (logo on cream/navy), and status bar icons remain legible against the app's top bar color in both light and dark mode.

**TC-123** · High · Security — Sensitive data not exposed in logs

Setup: Dev/staging build with logging enabled

Steps:
1. Perform a mood check-in with journal text
2. Inspect device logs (adb logcat / Xcode console)

Expected:
- No plaintext journal content, phone numbers, or auth tokens appear in application logs.

**TC-124** · Medium · Security — Data-at-rest protection

Setup: App has local check-in/journal data stored

Steps: Inspect the app's local storage/database file directly (rooted/jailbroken test device or simulator)

Expected:
- Journal and mood data is not stored as fully readable plaintext where the OS sandboxing model expects app-level encryption for sensitive data (confirm against the team's data-classification policy).

**TC-125** · Low · Functional — Orientation change handling

Setup: If the app supports rotation on any screen

Steps:
1. Rotate the device to landscape on Home, the Player, and Trends
2. Rotate back

Expected:
- Layout adapts or the app enforces portrait-only gracefully (no stretched/overlapping UI, no lost state, no crash).

