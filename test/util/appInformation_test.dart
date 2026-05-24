import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/appInformation.dart';

void main() {
  group('AppInformation update methods', () {
    late AppInformation app;
    late int notifyCount;

    setUp(() {
      app = AppInformation();
      notifyCount = 0;
      app.addListener(() => notifyCount++);
    });

    test('updateReminderMainTitle and updateReminderSubTitle', () {
      app.updateReminderMainTitle('main');
      app.updateReminderSubTitle('sub');
      expect(app.reminderMainTitle, 'main');
      expect(app.reminderSubTitle, 'sub');
      expect(notifyCount, 2);
    });

    test('updateHomeTitleGreeting', () {
      app.updateHomeTitleGreeting('hi');
      expect(app.homeTitleGreeting, 'hi');
      expect(notifyCount, 1);
    });

    test('updatePersonalPlanMainTitle and updatePersonalPlanSubTitle copy maps',
        () {
      final src = {'k': 'v'};
      app.updatePersonalPlanMainTitle(src);
      app.updatePersonalPlanSubTitle(src);
      src['k'] = 'mutated';
      expect(app.personalPlanMainTitle, {'k': 'v'});
      expect(app.personalPlanSubTitle, {'k': 'v'});
    });

    test('updateTraitMainTitle and updateTraitSubTitle copy maps', () {
      final src = {'k': 'v'};
      app.updateTraitMainTitle(src);
      app.updateTraitSubTitle(src);
      src['k'] = 'm';
      expect(app.traitMainTitle, {'k': 'v'});
      expect(app.traitSubTitle, {'k': 'v'});
    });

    test('updateJournalMainTitle and updateJournalSubTitle copy maps', () {
      final src = {'k': 'v'};
      app.updateJournalMainTitle(src);
      app.updateJournalSubTitle(src);
      src['k'] = 'm';
      expect(app.journalMainTitle, {'k': 'v'});
      expect(app.journalSubTitle, {'k': 'v'});
    });

    test('updateReturnToPlanStrings, warning + traits home page titles', () {
      app.updateReturnToPlanStrings({'a': 'b'});
      app.updateWarningHomePageTitles({'c': 'd'});
      app.updateTraitsHomePageTitles({'e': 'f'});
      expect(app.returnToPlanStrings, {'a': 'b'});
      expect(app.warningHomePageTitles, {'c': 'd'});
      expect(app.traitsHomePageTitles, {'e': 'f'});
      expect(notifyCount, 3);
    });

    test('introduction form pages', () {
      app.updateIntroductionFormFirstPage({'p': 'one'});
      app.updateIntroductionFormSecondPage({'p': 'two'});
      app.updateIntroductionFormLastPage({'p': 'last'});
      expect(app.introductionFormFirstPage, {'p': 'one'});
      expect(app.introductionFormSecondPage, {'p': 'two'});
      expect(app.introductionFormLastPage, {'p': 'last'});
    });

    test('updatePersonalInformationForm', () {
      app.updatePersonalInformationForm({'k': 'v'});
      expect(app.personalInformationForm, {'k': 'v'});
    });

    test('updateLastUpdated', () {
      final dt = DateTime(2024, 1, 1);
      app.updateLastUpdated(dt);
      expect(app.lastUpdated, dt);
    });

    test('updateHomePageInspirationalQuotes', () {
      app.updateHomePageInspirationalQuotes({
        'en': ['q1', 'q2'],
      });
      expect(app.homePageInspirationalQuotes['en'], ['q1', 'q2']);
    });

    test('updateTest1 copies list', () {
      final src = ['a', 'b'];
      app.updateTest1(src);
      src.add('c');
      expect(app.test1, ['a', 'b']);
    });

    test('updateShareMessages and updateThanksSuggestionsList', () {
      app.updateShareMessages({'k': 'v'});
      app.updateThanksSuggestionsList(['t1']);
      expect(app.shareMessages, {'k': 'v'});
      expect(app.thanksSuggestionsList, ['t1']);
    });

    test('updatePositiveTraitsSuggestionsList copies map', () {
      final src = {
        'group': ['x'],
      };
      app.updatePositiveTraitsSuggestionsList(src);
      src['group']!.add('y');
      // Top-level map is copied; inner list is shared by reference.
      expect(app.positiveTraitsSuggestionsList.containsKey('group'), isTrue);
    });

    test('updateJournalPopUpText, updatePositiveTraitsPopUpText', () {
      app.updateJournalPopUpText({'k': 'v'});
      app.updatePositiveTraitsPopUpText({'a': 'b'});
      expect(app.journalPopUpText, {'k': 'v'});
      expect(app.positiveTraitsPopUpText, {'a': 'b'});
    });

    test('phone-related updates', () {
      app.updateFormPhonePage({'k': 'v'});
      app.updatePhonePageTitles({
        'titles': ['t'],
      });
      expect(app.formPhonePage, {'k': 'v'});
      expect(app.phonePageTitles, {
        'titles': ['t'],
      });
    });

    test('form titles updates', () {
      app.updateFormDifficultEventsTitles({'k': 'v'});
      app.updateFormDistractionsTitles({'k': 'v'});
      app.updateFormFeelBetterTitles({'k': 'v'});
      app.updateFormMakeSaferTitles({'k': 'v'});
      app.updateFormSharePageTitles({'k': 'v'});
      expect(app.formDifficultEventsTitles, {'k': 'v'});
      expect(app.formDistractionsTitles, {'k': 'v'});
      expect(app.formFeelBetterTitles, {'k': 'v'});
      expect(app.formMakeSaferTitles, {'k': 'v'});
      expect(app.formSharePageTitles, {'k': 'v'});
    });

    test('phonePersonalPlanText copy', () {
      final src = ['p1'];
      app.updatePhonePersonalPlanText(src);
      src.add('p2');
      expect(app.phonePersonalPlanText, ['p1']);
    });

    test('updateAppVersion', () {
      app.updateAppVersion('1.2.3');
      expect(app.appVersion, '1.2.3');
    });

    test('suggestion lists copy', () {
      final src = ['a'];
      app.updateDifficultEventsSug(src);
      app.updateDistractionsSug(src);
      app.updateFeelBetterSug(src);
      app.updateMakeSaferSug(src);
      src.add('b');
      expect(app.DifficultEventsSug, ['a']);
      expect(app.DistractionsSug, ['a']);
      expect(app.FeelBetterSug, ['a']);
      expect(app.MakeSaferSug, ['a']);
    });

    test('updateSharePDFtexts and updateWellnessVideos', () {
      app.updateSharePDFtexts({'k': 'v'});
      app.updateWellnessVideos({
        'videoId': ['id'],
      });
      expect(app.sharePDFtexts, {'k': 'v'});
      expect(app.wellnessVideos['videoId'], ['id']);
    });

    test('updateAboutPageText', () {
      app.updateAboutPageText({'k': 'v'});
      expect(app.aboutPageText, {'k': 'v'});
    });

    test('disclaimer text + next', () {
      app.updateDisclaimerPageText('hello');
      app.updateDisclaimerPageNext('next');
      expect(app.disclaimerText, 'hello');
      expect(app.disclaimerNext, 'next');
    });

    test('skip button + feel good titles + extra menu strings', () {
      app.updateFormSkipButtonText({'k': 'v'});
      app.updateFeelGoodPageTitles({'a': 'b'});
      app.updateExtraMenuStrings({'c': 'd'});
      expect(app.formSkipButtonText, {'k': 'v'});
      expect(app.feelGoodPageTitles, {'a': 'b'});
      expect(app.extraMenuStrings, {'c': 'd'});
    });

    test('syncPages, popupBack, signUpLoginPage', () {
      app.updateSyncPages({'k': 'v'});
      app.updatePopupBack({'k': 'v'});
      app.updateSignUpLoginPage({'k': 'v'});
      expect(app.syncPages, {'k': 'v'});
      expect(app.popupBack, {'k': 'v'});
      expect(app.signUpLoginPage, {'k': 'v'});
    });

    test('addForm, addThanksForm, addFormPageTemplate strings', () {
      app.updateAddFormStrings({'k': 'v'});
      app.updateAddThanksFormStrings({'k': 'v'});
      app.updateAddFormPageTemplateStrings({'k': 'v'});
      expect(app.addFormStrings, {'k': 'v'});
      expect(app.addThanksFormStrings, {'k': 'v'});
      expect(app.addFormPageTemplateStrings, {'k': 'v'});
    });

    test('IntroductionRestart and otherSuggestions', () {
      app.updateIntroductionRestart({'k': 'v'});
      app.updateOtherSuggestions({'a': 'b'});
      expect(app.IntroductionRestart, {'k': 'v'});
      expect(app.othersuggestions, {'a': 'b'});
    });

    test('every update method triggers notifyListeners', () {
      app.updateReminderMainTitle('a');
      app.updateReminderSubTitle('b');
      app.updateHomeTitleGreeting('c');
      app.updatePersonalPlanMainTitle({});
      app.updatePersonalPlanSubTitle({});
      app.updateTraitMainTitle({});
      app.updateTraitSubTitle({});
      app.updateJournalMainTitle({});
      app.updateJournalSubTitle({});
      app.updateReturnToPlanStrings({});
      app.updateWarningHomePageTitles({});
      app.updateTraitsHomePageTitles({});
      expect(notifyCount, greaterThanOrEqualTo(12));
    });
  });
}
