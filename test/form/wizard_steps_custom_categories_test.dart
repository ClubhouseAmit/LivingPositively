import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/personal_plan/ui/custom_category/add_step.dart';
import 'package:mazilon/features/personal_plan/ui/custom_category/step.dart';
import 'package:mazilon/features/personal_plan/ui/form_page_template/form_page_template.dart';
import 'package:mazilon/features/personal_plan/ui/phone_page/form.dart';
import 'package:mazilon/features/personal_plan/ui/share_form/share_form.dart';
import 'package:mazilon/features/personal_plan/ui/wizard_steps.dart';
import 'package:mazilon/features/personal_plan/data/phone_models.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _phoneData() => PhonePageData(
  key: 'phone',
  header: '',
  subTitle: '',
  midTitle: '',
  phoneNameTitle: '',
  phoneNumberTitle: '',
  phoneNames: const [],
  phoneNumbers: const [],
  savedPhoneNames: const [],
  savedPhoneNumbers: const [],
  phoneDescription: const [],
);

void main() {
  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      FakePersistentMemoryService(),
    );
  });

  tearDown(() => GetIt.instance.reset());

  test('keeps built-in order and inserts saved categories before add step', () {
    final steps = buildWizardSteps(
      next: () {},
      prev: () {},
      phonePageData: _phoneData(),
      submit: (_) {},
      customCategories: const [
        MapEntry('First custom', 'First notes'),
        MapEntry('עברית', 'תיאור'),
      ],
    );

    expect(steps.length, 11);
    expect(steps.take(6).every((step) => step is FormPageTemplate), isTrue);
    expect(steps[6], isA<CustomCategoryStep>());
    expect(steps[7], isA<CustomCategoryStep>());
    expect(steps[8], isA<AddCustomCategoryStep>());
    expect(steps[9], isA<PhonePageForm>());
    expect(steps.last, isA<ShareForm>());
  });

  test('always exposes the add step when no custom category exists', () {
    final steps = buildWizardSteps(
      next: () {},
      prev: () {},
      phonePageData: _phoneData(),
      submit: (_) {},
    );

    expect(steps.length, 9);
    expect(steps[6], isA<AddCustomCategoryStep>());
    expect(steps[7], isA<PhonePageForm>());
    expect(steps.last, isA<ShareForm>());
  });
}
