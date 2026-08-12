import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/form/phonePageform.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _phonePageData({String key = 'phone'}) => PhonePageData(
  key: key,
  header: 'header',
  subTitle: 'subtitle',
  midTitle: 'middle',
  phoneNameTitle: 'name',
  phoneNumberTitle: 'number',
  phoneNames: const <String>[],
  phoneNumbers: const <String>[],
  savedPhoneNames: const <String>[],
  savedPhoneNumbers: const <String>[],
  phoneDescription: const <String>[],
);

Contact _contact(String number) => Contact(
  displayName: 'Imported contact',
  phones: <Phone>[Phone(number: number)],
);

Future<void> _pumpPhoneForm(
  WidgetTester tester,
  PhonePageData phonePageData,
  UserInformation userInformation,
) {
  return pumpWithProviders(
    tester,
    ChangeNotifierProvider<PhonePageData>.value(
      value: phonePageData,
      child: PhonePageForm(
        phonePageData: phonePageData,
        next: () {},
        prev: () {},
      ),
    ),
    userInformation: userInformation,
    surfaceSize: const Size(1024, 2400),
  );
}

void _importContact(WidgetTester tester, Contact contact) {
  final state = tester.state(find.byType(PhonePageForm)) as dynamic;
  state.addItem(contact);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation userInformation;

  setUp(() {
    registerTestServices(locale: 'en');
    userInformation = UserInformation();
    userInformation.gender = 'other';
    userInformation.localeName = 'en';
  });

  tearDown(resetTestServices);

  testWidgets('imports a formatted Israeli local number in canonical form', (
    tester,
  ) async {
    final phonePageData = _phonePageData();
    userInformation.location = 'IL';
    await _pumpPhoneForm(tester, phonePageData, userInformation);

    _importContact(tester, _contact('054 389-7645'));

    expect(phonePageData.savedPhoneNames, <String>['Imported contact']);
    expect(phonePageData.savedPhoneNumbers, <String>['+972543897645']);
  });

  testWidgets('imports a US local number with the profile country code', (
    tester,
  ) async {
    final phonePageData = _phonePageData();
    userInformation.location = 'US';
    await _pumpPhoneForm(tester, phonePageData, userInformation);

    _importContact(tester, _contact('(555) 123-4567'));

    expect(phonePageData.savedPhoneNumbers, <String>['+15551234567']);
  });

  testWidgets('preserves a bidi-marked international import', (tester) async {
    final phonePageData = _phonePageData();
    userInformation.location = 'ZZ';
    await _pumpPhoneForm(tester, phonePageData, userInformation);

    _importContact(tester, _contact('\u200F+972 54 389 7645'));

    expect(phonePageData.savedPhoneNumbers, <String>['+972543897645']);
  });

  testWidgets('treats a 00 prefix as an international import', (tester) async {
    final phonePageData = _phonePageData();
    userInformation.location = 'ZZ';
    await _pumpPhoneForm(tester, phonePageData, userInformation);

    _importContact(tester, _contact('00 972 54 389 7645'));

    expect(phonePageData.savedPhoneNumbers, <String>['+972543897645']);
  });

  testWidgets(
    'uses the default picker country for unsupported or empty profiles',
    (tester) async {
      for (final profileCountryCode in <String>['ZZ', '']) {
        final phonePageData = _phonePageData(key: 'phone-$profileCountryCode');
        userInformation.location = profileCountryCode;
        await _pumpPhoneForm(tester, phonePageData, userInformation);

        _importContact(tester, _contact('054 389-7645'));

        expect(phonePageData.savedPhoneNumbers, <String>[
          '+972543897645',
        ], reason: 'profile country $profileCountryCode');

        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}
