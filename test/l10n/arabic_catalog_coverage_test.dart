import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Set<String> _messageKeys(String path) {
  final decoded = _arb(path);
  return decoded.keys
      .where((key) => key != '@@locale' && !key.startsWith('@'))
      .toSet();
}

Map<String, Set<String>> _placeholderMetadata(String path) {
  final decoded = _arb(path);
  final placeholderMetadata = <String, Set<String>>{};

  for (final entry in decoded.entries) {
    if (!entry.key.startsWith('@') || entry.key == '@@locale') {
      continue;
    }

    final metadata = entry.value;
    if (metadata is! Map<String, dynamic>) {
      continue;
    }

    final placeholders = metadata['placeholders'] ?? metadata['placeholder'];
    if (placeholders is Map<String, dynamic>) {
      placeholderMetadata[entry.key] = placeholders.keys.toSet();
    }
  }

  return placeholderMetadata;
}

void main() {
  test('Arabic ARB covers every English key', () {
    final englishKeys = _messageKeys('lib/l10n/app_en.arb');
    final arabicKeys = _messageKeys('lib/l10n/app_ar.arb');

    final missingArabicKeys = englishKeys.difference(arabicKeys).toList()
      ..sort();
    final unexpectedArabicKeys = arabicKeys.difference(englishKeys).toList()
      ..sort();

    expect(
      missingArabicKeys,
      isEmpty,
      reason: 'Missing Arabic keys: ${missingArabicKeys.join(', ')}',
    );
    expect(
      unexpectedArabicKeys,
      isEmpty,
      reason: 'Unexpected Arabic-only keys: ${unexpectedArabicKeys.join(', ')}',
    );
  });

  test('Arabic ARB provides approved SOS location-sharing copy', () {
    final arabic = _arb('lib/l10n/app_ar.arb');

    expect(arabic['sosShareLocation'], 'مشاركة الموقع');
    expect(arabic['sosShareLocationTooltip'], 'مشاركة موقعك الحالي');
    expect(arabic['sosShareLocationMessage'], 'أنا هنا وأحتاج إلى مساعدتك.');
    expect(
      arabic['sosShareLocationUnavailable'],
      'تعذّر الحصول على موقعك الحالي.',
    );
    expect(
      arabic['sosShareLocationServicesDisabled'],
      'تعذّر الحصول على موقعك الحالي. يُرجى تفعيل خدمات الموقع.',
    );
    expect(
      arabic['sosShareLocationShareFailed'],
      'تعذّر مشاركة رسالة طلب المساعدة الخاصة بك. يُرجى المحاولة مرة أخرى.',
    );
    expect(arabic['sosShareMessage'], 'مشاركة رسالة الاستغاثة');
    expect(arabic['sosShareMessageTooltip'], 'مشاركة رسالة طلب المساعدة');
    expect(arabic['sosDeliveryOptionsTitle'], 'خيارات الإرسال');
    expect(arabic['sosDeliveryChooseApp'], 'اختيار تطبيق');
    expect(arabic['sosDeliverySendToContact'], 'إرسال إلى جهة اتصال شخصية');
    expect(arabic['sosDeliveryOpenMapApp'], 'فتح في تطبيق خرائط');
    expect(arabic['sosDeliveryContactPickerTitle'], 'اختيار جهة اتصال شخصية');
    expect(
      arabic['sosDeliveryNoContactsMessage'],
      'لا توجد جهات اتصال شخصية. أضف جهة اتصال لإرسال رسالة استغاثة مباشرةً.',
    );
    expect(
      arabic['sosDeliveryContactsNeedAttention'],
      'يجب تحديث جهات الاتصال المحفوظة قبل أن يمكن استخدامها لإرسال رسالة استغاثة.',
    );
    expect(arabic['sosDeliveryMethodTitle'], 'طريقة الإرسال إلى {contact}');
    expect(arabic['sosDeliverySms'], 'رسالة نصية (SMS)');
    expect(
      arabic['sosDeliveryWhatsAppInternationalNumber'],
      'للإرسال عبر واتساب، اختر رمز الدولة وأدخل رقم الهاتف الكامل.',
    );
    expect(
      arabic['contactPhoneCountryCodeHint'],
      'اختر رمز الدولة؛ وسيتم حفظه مع رقم الهاتف المحلي.',
    );
    expect(arabic['sosDeliveryEditContacts'], 'تعديل جهات الاتصال');
  });

  test('contact number guidance is localized without requiring a plus prefix', () {
    final english = _arb('lib/l10n/app_en.arb');
    final hebrew = _arb('lib/l10n/app_he.arb');
    final arabic = _arb('lib/l10n/app_ar.arb');

    expect(
      english['contactPhoneCountryCodeHint'],
      'Select a country code; it will be saved with the local phone number.',
    );
    expect(
      hebrew['contactPhoneCountryCodeHint'],
      'בחרו קידומת מדינה; היא תישמר עם מספר הטלפון המקומי.',
    );
    expect(
      arabic['contactPhoneCountryCodeHint'],
      'اختر رمز الدولة؛ وسيتم حفظه مع رقم الهاتف المحلي.',
    );
    expect(
      english['sosDeliveryWhatsAppInternationalNumber'],
      'To send with WhatsApp, choose the country code and enter the full phone number.',
    );
    expect(
      hebrew['sosDeliveryWhatsAppInternationalNumber'],
      'כדי לשלוח ב-WhatsApp, בחרו קידומת מדינה והזינו את מספר הטלפון המלא.',
    );
    expect(
      arabic['sosDeliveryWhatsAppInternationalNumber'],
      'للإرسال عبر واتساب، اختر رمز الدولة وأدخل رقم الهاتف الكامل.',
    );
  });

  test('Arabic ARB preserves English placeholder metadata entries', () {
    final englishMetadata = _placeholderMetadata('lib/l10n/app_en.arb');
    final arabicMetadata = _placeholderMetadata('lib/l10n/app_ar.arb');

    final missingMetadataKeys =
        englishMetadata.keys
            .toSet()
            .difference(arabicMetadata.keys.toSet())
            .toList()
          ..sort();
    final unexpectedMetadataKeys =
        arabicMetadata.keys
            .toSet()
            .difference(englishMetadata.keys.toSet())
            .toList()
          ..sort();

    expect(
      missingMetadataKeys,
      isEmpty,
      reason:
          'Missing Arabic placeholder metadata keys: ${missingMetadataKeys.join(', ')}',
    );
    expect(
      unexpectedMetadataKeys,
      isEmpty,
      reason:
          'Unexpected Arabic placeholder metadata keys: ${unexpectedMetadataKeys.join(', ')}',
    );

    for (final metadataKey in englishMetadata.keys) {
      expect(
        arabicMetadata[metadataKey],
        englishMetadata[metadataKey],
        reason: 'Placeholder names differ for $metadataKey',
      );
    }
  });

  test('Arabic ARB uses the reviewed UI wording for core navigation and actions', () {
    final arabic = _arb('lib/l10n/app_ar.arb');

    expect(
      arabic['menu'],
      '{gender,select,male{القائمة} female{القائمة} other{القائمة}}',
    );
    expect(
      arabic['home'],
      '{gender,select,male{الرئيسية} female{الرئيسية} other{الرئيسية}}',
    );
    expect(
      arabic['closeButton'],
      '{gender,select,male{إلغاء} female{إلغاء} other{إلغاء}}',
    );
    expect(
      arabic['confirmButton'],
      '{gender,select,male{تأكيد} female{تأكيد} other{تأكيد}}',
    );
    expect(
      arabic['saveButton'],
      '{gender,select,male{حفظ} female{حفظ} other{حفظ}}',
    );
    expect(
      arabic['deleteButton'],
      '{gender,select,male{حذف} female{حذف} other{حذف}}',
    );
    expect(
      arabic['nextButton'],
      '{gender,select,male{متابعة} female{متابعة} other{متابعة}}',
    );
    expect(
      arabic['skipButton'],
      '{gender,select,male{تخطي} female{تخطي} other{تخطي}}',
    );
    expect(
      arabic['personalPlanPageFinish'],
      '{gender,select,male{إنهاء} female{إنهاء} other{إنهاء}}',
    );
    expect(
      arabic['dialButton'],
      '{gender,select,male{اتصال} female{اتصال} other{اتصال}}',
    );
    expect(
      arabic['select'],
      '{gender,select,male{اختيار} female{اختيار} other{اختيار}}',
    );
    expect(
      arabic['addFormEdit'],
      '{gender,select,male{تعديل} female{تعديل} other{تعديل}}',
    );
    expect(
      arabic['addFormPageTemplateAdd'],
      '{gender,select,male{إضافة} female{إضافة} other{إضافة}}',
    );
    expect(
      arabic['homePageBack'],
      '{gender,select,male{إغلاق} female{إغلاق} other{إغلاق}}',
    );
    expect(
      arabic['introductionFormFirstPageSkip'],
      '{gender,select,male{تخطي} female{تخطي} other{تخطي}}',
    );
    expect(arabic['shareButtonText'], 'مشاركة');
    expect(
      arabic['inspirationalQuotesNo34'],
      '{gender,select,male{أنا أستحق ذلك} female{أنا أستحق ذلك} other{أنا أستحق ذلك}}',
    );
    expect(arabic['notWillingToSay'], 'أفضل عدم الإفصاح');
    expect(
      arabic['difficultEventsListNo8'],
      '{gender,select,male{الحمل الزائد} female{الحمل الزائد} other{الحمل الزائد}}',
    );
    expect(
      arabic['distractionsListNo3'],
      '{gender,select,male{الرغبة في الانزواء أو الاختباء أو الاختفاء} female{الرغبة في الانزواء أو الاختباء أو الاختفاء} other{الرغبة في الانزواء أو الاختباء أو الاختفاء}}',
    );
    expect(
      arabic['distractionsListNo9'],
      '{gender,select,male{اللامبالاة أو عدم الاكتراث} female{اللامبالاة أو عدم الاكتراث} other{اللامبالاة أو عدم الاكتراث}}',
    );
    expect(
      arabic['difficultEventsListNo4'],
      '{gender,select,male{الظلم والإجحاف وانعدام الإنصاف} female{الظلم والإجحاف وانعدام الإنصاف} other{الظلم والإجحاف وانعدام الإنصاف}}',
    );
    expect(arabic['newTraitOrThanks'], 'عنصر جديد: {item}');
    expect(arabic['camera'], 'كاميرا');
    expect(
      arabic['userSettingsGender'],
      '{gender,select,male{كيف تفضل أن نخاطبك؟} female{كيف تفضلين أن نخاطبك؟} other{ما الصيغة المفضلة للمخاطبة؟}}',
    );
    expect(
      arabic['feelGoodSubTitle'],
      '{gender,select,male{يوصى بإضافة صور مشجعة وملهمة ومبهجة. صور مبتسمة للعائلة والأصدقاء والهوايات والرحلات الناجحة والمزيد} female{يوصى بإضافة صور مشجعة وملهمة ومبهجة. صور مبتسمة للعائلة والأصدقاء والهوايات والرحلات الناجحة والمزيد} other{يوصى بإضافة صور مشجعة وملهمة ومبهجة. صور مبتسمة للعائلة والأصدقاء والهوايات والرحلات الناجحة والمزيد}}',
    );
  });
}
