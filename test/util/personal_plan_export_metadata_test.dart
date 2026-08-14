import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/l10n/app_localizations_ar.dart';
import 'package:mazilon/l10n/app_localizations_en.dart';
import 'package:mazilon/l10n/app_localizations_he.dart';
import 'package:mazilon/util/personal_plan_export_metadata.dart';

void main() {
  final titleCases = <({AppLocalizations locale, String username, String title})>[
    (locale: AppLocalizationsEn(), username: '', title: 'My Personal Plan'),
    (locale: AppLocalizationsEn(), username: 'Alex', title: "Alex's Personal Plan"),
    (locale: AppLocalizationsHe(), username: '', title: 'התוכנית האישית שלי'),
    (locale: AppLocalizationsHe(), username: 'אלכס', title: 'התוכנית האישית של אלכס'),
    (locale: AppLocalizationsAr(), username: '', title: 'خطتي الشخصية'),
    (locale: AppLocalizationsAr(), username: 'أليكس', title: 'الخطة الشخصية لـأليكس'),
  ];
  for (final titleCase in titleCases) {
    test('should build the localized PDF title for ${titleCase.locale.localeName}', () {
      expect(
        buildPersonalPlanExportMetadata(titleCase.locale, 'male', titleCase.username).mainTitle,
        titleCase.title,
      );
    });
  }

  test('builds complete fixed English Personal Plan export metadata', () {
    final metadata = buildPersonalPlanExportMetadata(
      AppLocalizationsEn(),
      'male',
      '',
    );

    expect(metadata.titles, const <String>[
      'Symptoms and warning signs',
      'Reminders of common triggers and escalation factors',
      'What to do to help myself balance and maintain a healthy lifestyle '
          '(Wellness Tools) - Personal medications',
      'Support and help from the environment when I experience early warning '
          'signs, how I would like to be helped',
      'Who are the people who support me, that I can turn to if I am in '
          'distress or thinking about self-harm',
      'What will help me make the situation and environment safer for me',
    ]);
    expect(metadata.subTitles, const <String>[
      'Reminders of things that have appeared personally for me in the past',
      'Factors and events that have been challenging for me in the past',
      'What helps me improve my mood, relax and feel less stressed?\n'
          'Methods for preventative maintenance, and even increase dosages - '
          'in emergency situations.',
      'Ways my surroundings can help me cope',
      'The people who love me and will help me get through the tough moments '
          'are:',
      'Steps I can take to make my situation and environment safer',
    ]);
  });

  const hebrewCases = <Map<String, String>>[
    {
      'gender': 'male',
      'phonesHeader':
          'מי האנשים שתומכים בי, שאני יכול לפנות אליהם אם אני במצוקה או במחשבה על לפגוע בעצמי',
      'wellnessSubTitle':
          'מה עוזר לי לשפר את מצב הרוח, להירגע, להרגיש קצת פחות לחץ. דרכים שבהן כדאי לי להשתמש ולהיעזר כתחזוקה מונעת, וכשיש צורך במצבי חירום אפילו להגביר מינונים.',
    },
    {
      'gender': 'female',
      'phonesHeader':
          'מי האנשים שתומכים בי, שאני יכולה לפנות אליהם אם אני במצוקה או במחשבה על לפגוע בעצמי',
      'wellnessSubTitle':
          'דרכים שבהן כדאי לי להשתמש ולהיעזר כתחזוקה מונעת, וכשיש צורך במצבי חירום אפילו להגביר מינונים.',
    },
    {
      'gender': 'other',
      'phonesHeader':
          'מי האנשים שתומכים בי, שניתן לפנות אליהם אם אני במצוקה או במחשבה על לפגוע בעצמי',
      'wellnessSubTitle':
          'דרכים שבהן כדאי לי להשתמש ולהיעזר כתחזוקה מונעת, וכשיש צורך במצבי חירום אפילו להגביר מינונים.',
    },
    {
      'gender': '',
      'phonesHeader':
          'מי האנשים שתומכים בי, שניתן לפנות אליהם אם אני במצוקה או במחשבה על לפגוע בעצמי',
      'wellnessSubTitle':
          'דרכים שבהן כדאי לי להשתמש ולהיעזר כתחזוקה מונעת, וכשיש צורך במצבי חירום אפילו להגביר מינונים.',
    },
  ];

  for (final testCase in hebrewCases) {
    final gender = testCase['gender']!;
    test(
      'uses fixed Hebrew metadata for ${gender.isEmpty ? 'empty' : gender}',
      () {
        final metadata = buildPersonalPlanExportMetadata(
          AppLocalizationsHe(),
          gender,
          '',
        );

        expect(metadata.titles, hasLength(6));
        expect(metadata.subTitles, hasLength(6));
        expect(metadata.titles[4], testCase['phonesHeader']);
        expect(metadata.subTitles[2], testCase['wellnessSubTitle']);
      },
    );
  }

  test('uses fixed Arabic Safe Environment export metadata', () {
    final metadata = buildPersonalPlanExportMetadata(
      AppLocalizationsAr(),
      'male',
      '',
    );

    expect(metadata.titles, hasLength(6));
    expect(metadata.subTitles, hasLength(6));
    expect(
      metadata.titles[5],
      'ما الذي سيساعدني على جعل الوضع والبيئة أكثر أمانًا بالنسبة لي',
    );
    expect(
      metadata.subTitles[5],
      'خطوات يمكنني اتخاذها لجعل وضعي وبيئتي أكثر أمانًا',
    );
  });
}
