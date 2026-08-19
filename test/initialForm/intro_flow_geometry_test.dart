// Asserts the intro flow's layout against the Figma frames' own coordinates,
// so "is this pixel perfect" has an answer that doesn't depend on eyeballing a
// screenshot.
//
// The view is the design frame: 360x800, with the same platform chrome the
// frame draws — a 24pt status bar and a 48pt Android nav bar, expressed as view
// padding. That makes every assertion below a raw Figma coordinate with no
// mapping arithmetic to get wrong.
//
//   header control top   51    (nodes 1660:2302 / 1660:2340)
//   title block top     104    (Frames 199 / 205 / 207)
//   step dots bottom    726    (Group 470, 26 above the nav bar at 752)
//
// The real device differs. Spacing is reproduced *below* the chrome, so on an
// iPhone reserving 59pt of safe area where this frame reserves 24, everything
// sits 35pt lower down the screen than the frame shows. That is a platform
// difference rather than a spacing bug — see `OnboardingGaps.chromeToHeader`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/initialForm/form.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _phoneData() => PhonePageData(
  key: 'phone',
  header: 'h',
  subTitle: 's',
  midTitle: 'm',
  phoneNameTitle: 'n',
  phoneNumberTitle: 'p',
  phoneNames: const <String>[],
  phoneNumbers: const <String>[],
  savedPhoneNames: const <String>[],
  savedPhoneNumbers: const <String>[],
  phoneDescription: const <String>[],
);

/// The Figma frame, exactly: 360x800.
const Size _frame = Size(360, 800);

/// The chrome the frame draws, as view padding — a 24pt status bar and a 48pt
/// Android nav bar. With these in place the app reproduces the frame's own
/// coordinates, so the assertions below are raw Figma numbers.
const FakeViewPadding _framePadding = FakeViewPadding(top: 24, bottom: 48);

/// Where the frame's bottom chrome begins.
const double _navBarTop = 800 - 48;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'he');
    user = UserInformation();
    user.gender = 'female';
    user.localeName = 'he';
    user.disclaimerSigned = true;
  });

  tearDown(resetTestServices);

  Future<void> pumpFlow(WidgetTester tester, {Size size = _frame}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    tester.view.padding = _framePadding;
    tester.view.viewPadding = _framePadding;
    addTearDown(tester.view.reset);
    await loadTestFonts();
    await pumpWithProviders(
      tester,
      InitialFormProgressIndicator(
        phonePageData: _phoneData(),
        changeLocale: (_) {},
      ),
      userInformation: user,
      locale: const Locale('he'),
    );
  }

  testWidgets('step dots match Figma Group 470', (tester) async {
    await pumpFlow(tester);

    final dots = find.byKey(const ValueKey('intro-step-dot-0'));
    expect(find.byType(AnimatedContainer), findsNWidgets(3));

    const dotSize = 10.0;
    const dotGap = 11.0;
    const dotsToBottom = 26.0;

    for (var i = 0; i < 3; i++) {
      final size = tester.getSize(find.byKey(ValueKey('intro-step-dot-$i')));
      expect(size.height, dotSize, reason: 'dot $i height');
      expect(size.width, dotSize, reason: 'dot $i width');
    }

    // 21pt pitch: 10 wide + 11 between.
    final first = tester.getTopLeft(dots).dx;
    final second = tester
        .getTopLeft(find.byKey(const ValueKey('intro-step-dot-1')))
        .dx;
    expect(
      (second - first).abs(),
      dotSize + dotGap,
      reason: 'dot pitch',
    );

    // Group 470's bottom sits 26 above the content area's bottom edge.
    final dotsBottom = tester.getBottomLeft(dots).dy;
    expect(
      _navBarTop - dotsBottom,
      closeTo(dotsToBottom, 0.5),
      reason: 'dots to the frame bottom chrome (Group 470 bottom is 726)',
    );

    // Centred on the screen, not on the leftover space beside a control.
    final left = tester.getTopLeft(dots).dx;
    final right = tester
        .getTopRight(find.byKey(const ValueKey('intro-step-dot-2')))
        .dx;
    expect((left + right) / 2, closeTo(_frame.width / 2, 0.5));
  });

  testWidgets('header control sits at the frame inset and height', (
    tester,
  ) async {
    await pumpFlow(tester);

    final skip = find.byKey(const Key('intro-header-skip'));
    expect(
      tester.getTopLeft(skip).dy,
      closeTo(51, 1),
      reason: 'header control top (Figma node 1660:2302)',
    );
    // RTL: the skip link sits on the reading-end edge, i.e. the frame's left.
    expect(
      tester.getTopLeft(skip).dx,
      closeTo(15.0, 1),
      reason: 'header control screen inset',
    );

    // The title block is pinned below the header, not floated in the slack.
    expect(
      tester.getTopLeft(find.byKey(const Key('intro-title-block'))).dy,
      closeTo(104, 1),
      reason: 'title block top (Figma Frames 199/205/207 at y 104)',
    );
  });

  testWidgets('every step puts its title block at the same y', (tester) async {
    // Taller than the frame on purpose. At 800 the personal-info form fills the
    // viewport, so a step that centres its content vertically has no slack to
    // shift it and the bug hides. The defect only shows where slack exists —
    // which is every real phone.
    await pumpFlow(tester, size: const Size(360, 1100));

    // Frames 199, 205 and 207 all sit at y 104. Checking only the first step
    // let step 2 drift: it centred its form vertically, dropping the title well
    // below the other two.
    for (var step = 0; step < 3; step++) {
      expect(
        tester.getTopLeft(find.byKey(const Key('intro-title-block'))).dy,
        closeTo(104, 1),
        reason: 'title block top on step ${step + 1}',
      );
      if (step == 2) break;
      await tester.tap(find.byKey(const Key('wizard-primary-action')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      drainOverflowExceptions(tester);
    }
  });

  testWidgets(
    'primary button matches the design pill and its gap to the dots',
    (tester) async {
      await pumpFlow(tester);

      final button = find.byKey(const Key('wizard-primary-action'));
      // The painted pill, not the widget box: `tapTargetSize.padded` keeps the
      // hit area at Material's 48 minimum around the design's 40pt pill, so the
      // widget box is deliberately taller than the paint.
      final pill = find.descendant(of: button, matching: find.byType(Material));
      final buttonBox = tester.getRect(pill.first);

      const screenInset = 15.0;
      const primaryButtonHeight = 40.0;
      const actionsToDots = 28.0;

      expect(
        buttonBox.height,
        closeTo(primaryButtonHeight, 0.5),
        reason: 'primary pill height (Figma node 1660:1272)',
      );
      expect(
        tester.getRect(button).height,
        greaterThanOrEqualTo(48),
        reason: 'tap target stays at the Material minimum around the 40pt pill',
      );
      expect(
        buttonBox.left,
        closeTo(screenInset, 1),
        reason: 'actions block screen inset',
      );
      expect(
        buttonBox.width,
        closeTo(_frame.width - screenInset * 2, 1),
        reason: 'actions block width (330 on a 360 frame)',
      );

      final secondary = find.byKey(const Key('wizard-secondary-action'));
      expect(secondary, findsNothing);

      final dotsTop = tester
          .getTopLeft(find.byKey(const ValueKey('intro-step-dot-0')))
          .dy;
      // The gap the dots follow (from the bottom of the primary button to the dots top).
      expect(
        dotsTop - tester.getRect(button).bottom,
        closeTo(actionsToDots, 1),
        reason: 'primary action to dots (Frame 201 itemSpacing)',
      );
    },
  );

  testWidgets('form fields span the same width as the primary button', (
    tester,
  ) async {
    await pumpFlow(tester);

    // Advance to the personal-info step.
    await tester.tap(find.byKey(const Key('wizard-primary-action')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    drainOverflowExceptions(tester);

    final buttonWidth = tester
        .getRect(find.byKey(const Key('wizard-primary-action')))
        .width;

    // Every field on frame 28 is 330 wide on a 360 frame — the same width as
    // the actions block. A narrower field reads as a different column.
    for (final field in [
      find.byType(TextFormField),
      find.byType(DropdownMenu<String>).first,
    ]) {
      expect(
        tester.getRect(field).width,
        closeTo(buttonWidth, 1),
        reason: 'field width should match the primary button',
      );
    }
  });

  testWidgets('field groups match the Figma 90pt group on a 106pt pitch', (
    tester,
  ) async {
    await pumpFlow(tester);
    await tester.tap(find.byKey(const Key('wizard-primary-action')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    drainOverflowExceptions(tester);

    // Each field paints the design's 53pt box (Groups 141/142/143: a 32pt
    // label, then the field, 90 tall in total).
    final nameField = tester.getRect(find.byType(TextFormField));
    expect(
      nameField.height,
      closeTo(kFormFieldHeight, 1),
      reason: 'field height (Figma Group 75, 53 tall)',
    );

    final dropdowns = find.byType(DropdownMenu<String>);
    expect(
      tester.getRect(dropdowns.at(0)).height,
      closeTo(kFormFieldHeight, 1),
      reason: 'age field height',
    );

    // The design's own numbers, not a restatement of ours. Groups 141 and 142
    // sit at y 341 and 447 — a 106pt pitch — and each group is 90 tall.
    // Asserting the constants we happened to pick would prove nothing.
    const designGroupPitch = 447.0 - 341.0;
    const designGroupHeight = 90.0;

    final ageField = tester.getRect(dropdowns.at(0));
    final genderField = tester.getRect(dropdowns.at(1));
    expect(
      genderField.top - ageField.top,
      closeTo(designGroupPitch, 1),
      reason:
          'field group pitch (Figma: Group 141 top 341 -> Group 142 top 447)',
    );
    expect(
      kFormFieldLabelBox +
          OnboardingGaps.labelToField +
          kFormFieldHeight,
      closeTo(designGroupHeight, 0.5),
      reason: "label + gap + field should make the design's 90pt group",
    );

    // Submitting empty fails validation and shows the error line beneath the
    // field. The field grows by that line — what it must not do is shrink its
    // own box to make room, which is what `InputDecoration.constraints` caused:
    // that bounds the whole decorator, error text included, so the bordered box
    // was squeezed the moment validation failed.
    final before = tester.getRect(find.byType(TextFormField)).height;
    await tester.tap(find.byKey(const Key('wizard-primary-action')));
    await tester.pumpAndSettle();
    drainOverflowExceptions(tester);
    expect(
      tester.getRect(find.byType(TextFormField)).height,
      greaterThan(before),
      reason:
          'the error line must add height, not be squeezed inside the field box',
    );
  });
}
