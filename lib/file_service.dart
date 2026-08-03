
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/PDF/create_pdf.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

const String _customCategoryTitlesKey = 'customCategoryTitles';
const String _customCategoryDescriptionsKey = 'customCategoryDescriptions';

abstract class FileService {
  Future<void> share(
      String message,
      List<dynamic> titles,
      List<dynamic> subTitles,
      Map<String, String> texts,
      ShareFileType saveFormat,
      String textDirection);
  Future<String?> download(
      List<dynamic> titles,
      List<dynamic> subTitles,
      Map<String, String> texts,
      ShareFileType saveFormat,
      String textDirection);
  Future<bool> shareTextOnly(String message);
}

class FileServiceImpl implements FileService {
  static Future<Map<String, dynamic>> getPrefsData() async {
    final service = GetIt.instance<
        PersistentMemoryService>(); // Get the persistent memory service instance

    final futures = <String, Future>{
      'difficultEvents': service.getItem(
          'userSelectionPersonalPlan-DifficultEvents',
          PersistentMemoryType.StringList),
      'makeSafer': service.getItem('userSelectionPersonalPlan-MakeSafer',
          PersistentMemoryType.StringList),
      'feelBetter': service.getItem('userSelectionPersonalPlan-FeelBetter',
          PersistentMemoryType.StringList),
      'distractions': service.getItem('userSelectionPersonalPlan-Distractions',
          PersistentMemoryType.StringList),
      'phoneNames': service.getItem(
          'PhonePageSavedPhoneNames', PersistentMemoryType.StringList),
      'phoneNumbers': service.getItem(
          'PhonePageSavedPhoneNumbers', PersistentMemoryType.StringList),
      'username': service.getItem('name', PersistentMemoryType.String),
      'customCategoryTitles': service.getItem(
          _customCategoryTitlesKey, PersistentMemoryType.StringList),
      'customCategoryDescriptions': service.getItem(
          _customCategoryDescriptionsKey, PersistentMemoryType.StringList),
    };

    final results = await Future.wait(futures.values);
    final data = Map.fromIterables(futures.keys, results);

    return {
      'DifficultEvents': TypeUtils.castToStringList(data['difficultEvents']),
      'MakeSafer': TypeUtils.castToStringList(data['makeSafer']),
      'FeelBetter': TypeUtils.castToStringList(data['feelBetter']),
      'Distractions': TypeUtils.castToStringList(data['distractions']),
      'phoneNames': TypeUtils.castToStringList(data['phoneNames']),
      'phoneNumbers': TypeUtils.castToStringList(data['phoneNumbers']),
      'username': data['username'] ?? '',
      'customCategoryTitles':
          TypeUtils.castToStringList(data['customCategoryTitles']),
      'customCategoryDescriptions':
          TypeUtils.castToStringList(data['customCategoryDescriptions']),
    };
  }

  static List<List<String>> filterEmptyData(List<List<String>> data) {
    final filtered = <List<String>>[];
    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) {
        continue;
      }
      filtered.add(data[i]);
    }
    return filtered;
  }

  static List<String> formatPhonesText(
      List<String> names, List<String> numbers) {
    final formattedText = <String>[];
    for (var i = 0; i < names.length; i++) {
      formattedText.add('${names[i]}:${numbers[i]}');
    }
    return formattedText;
  }

  Future<Map<String, dynamic>> organizeDataForFile(List<dynamic> titles,
      List<dynamic> subTitles, Map<String, String> texts) async {
    // Set the page format to A4

    // Load the font for the PDF
    // Create a new PDF document
    final dataForPDF = await getPrefsData();
    // Retrieve user data from SharedPreferences
    final difficultEvents = dataForPDF['DifficultEvents'] as List<String>;
    final makeSafer = dataForPDF['MakeSafer'] as List<String>;
    final feelBetter = dataForPDF['FeelBetter'] as List<String>;
    final distractions = dataForPDF['Distractions'] as List<String>;
    final phoneNames = dataForPDF['phoneNames'] as List<String>;
    final phoneNumbers = dataForPDF['phoneNumbers'] as List<String>;
    final username = dataForPDF['username'] as String;
    final customCategoryTitles = dataForPDF['customCategoryTitles'] as List<String>;
    final customCategoryDescriptions =
        dataForPDF['customCategoryDescriptions'] as List<String>;
    final phoneDescription = formatPhonesText(phoneNames, phoneNumbers);

    final allTitles = <dynamic>[...titles];
    final allSubTitles = <dynamic>[...subTitles];
    final allData = <List<String>>[
      difficultEvents,
      makeSafer,
      feelBetter,
      distractions,
      phoneDescription
    ];

    for (var i = 0;
        i < customCategoryTitles.length &&
            i < customCategoryDescriptions.length;
        i++) {
      final title = customCategoryTitles[i].trim();
      final description = customCategoryDescriptions[i].trim();
      if (title.isEmpty || description.isEmpty) {
        continue;
      }
      allTitles.add(title);
      allSubTitles.add('');
      allData.add([description]);
    }

    final realTitles = <dynamic>[];
    final realSubTitles = <dynamic>[];
    final realData = <List<String>>[];
    for (var i = 0;
        i < allData.length && i < allTitles.length && i < allSubTitles.length;
        i++) {
      if (allData[i].isEmpty) {
        continue;
      }
      realTitles.add(allTitles[i]);
      realSubTitles.add(allSubTitles[i]);
      realData.add(allData[i]);
    }
    // Create the main title for the PDF
    final mainTitle =
        username == '' ? 'התוכנית המשולבת שלי' : 'התוכנית המשולבת של $username';

    // Retrieve text content for the PDF
    final text1 = texts['firstLine'] ?? '';
    final text2 = texts['firstLinkText'] ?? '';
    final text2Link = texts['firstLinkURL'] ?? '';
    final text3 = texts['secondLine'] ?? '';
    final text4 = texts['thirdLine'] ?? '';
    final text5 = texts['secondLinkText'] ?? '';
    final text5Link = texts['secondLinkURL'] ?? '';
    final text6 = texts['forthLine'] ?? '';

    // Prepare the data to be included in the PDF

    // Load the logo image for the PDF

    // Create widgets for the PDF content
    return {
      'mainTitle': mainTitle,
      'titles': realTitles,
      'subTitles': realSubTitles,
      'realData': realData,
      'texts': {
        'text1': text1,
        'text2': text2,
        'text2Link': text2Link,
        'text3': text3,
        'text4': text4,
        'text5': text5,
        'text5Link': text5Link,
        'text6': text6
      }
    };
  }

//New version of SharePlus can't sennd empty "" message
  String? checkEmptyMessage(String message) {
    return message.isEmpty ? null : message;
  }

  @override
  Future<void> share(
      String message,
      List<dynamic> titles,
      List<dynamic> subTitles,
      Map<String, String> texts,
      ShareFileType saveFormat,
      String textDirection) async {
    try {
      // Add the generated widgets to the PDF
      final dataForFile = await organizeDataForFile(titles, subTitles, texts);
      Map<String, dynamic> file;
      switch (saveFormat) {
        case ShareFileType.PDF:
          file = await createPDF(
              dataForFile['titles'] as List<dynamic>,
              dataForFile['subTitles'] as List<dynamic>,
              dataForFile['texts'] as Map<String, String>,
              dataForFile['mainTitle'] as String,
              dataForFile['realData'] as List<List<String>>,
              textDirection);
          final tempFile = await saveTempPDF(
            file['file'] as pw.Document,
            file['format'] as String,
          );
          final tempXFile = XFile(tempFile.path);

          await SharePlus.instance.share(ShareParams(
              files: [tempXFile], text: checkEmptyMessage(message)));
        default:
          file = {'file': null, 'format': null};
      }

      // Save the PDF and share it
      if (file['file'] == null || file['format'] == null) {
        return;
      }
      final mixPanelService = GetIt.instance<AnalyticsService>();
      mixPanelService.trackEvent('Plan shared');
    } catch (error, stackTrace) {
      final loggerService =
          GetIt.instance<IncidentLoggerService>();
      await loggerService.captureLog(
        error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<String?> saveAndroid(Uint8List data, String format) async {
    try {
      // Open a save file dialog to allow the user to select a location to save the PDF
      final outputFile = await FilePicker.saveFile(
        dialogTitle: 'Please select an output file:', // Dialog title
        fileName: 'התוכנית שלי.$format', // Default file name
        bytes: data, // PDF data to be saved
      );
      //If the user cancels the download
      final mixPanelService = GetIt.instance<AnalyticsService>();
      mixPanelService.trackEvent('Plan downloaded Android');
      return outputFile;
    } catch (error, stackTrace) {
      final loggerService =
          GetIt.instance<IncidentLoggerService>();
      await loggerService.captureLog(
        error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<String?> saveWeb(List<int> data) async {
    // Create a Blob object from the PDF data
    /*final blob = html.Blob([pdfData], 'application/pdf');

    // Generate a URL for the Blob object
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create an anchor element and set its href attribute to the Blob URL
    final anchor = html.AnchorElement(href: url)
      // Set the download attribute with the desired file name
      ..setAttribute('download', 'MyPlan.pdf')
      // Trigger a click on the anchor element to start the download
      ..click();*/

    final mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent('Plan downloaded Web');
    return null;
  }

  @override
  Future<String?> download(
      List<dynamic> titles,
      List<dynamic> subTitles,
      Map<String, String> texts,
      ShareFileType saveFormat,
      String textDirection) async {
    final dataForFile = await organizeDataForFile(titles, subTitles, texts);
    Map<String, dynamic> file;
    var data = Uint8List(0);
    switch (saveFormat) {
      case ShareFileType.PDF:
        file = await createPDF(
            dataForFile['titles'] as List<dynamic>,
            dataForFile['subTitles'] as List<dynamic>,
            dataForFile['texts'] as Map<String, String>,
            dataForFile['mainTitle'] as String,
            dataForFile['realData'] as List<List<String>>,
            textDirection);
        // Save the PDF and share it

        // Save the PDF for download
        data = await (file['file'] as pw.Document).save();

      default:
        file = {'file': null, 'format': null};
    }
    if (file['file'] == null || file['format'] == null) {
      return null;
    }
    if (Platform.isAndroid) {
      return saveAndroid(data, file['format']);
    }
    if (kIsWeb) {
      return saveWeb(data);
    }
    return null;
  }

  @override
  Future<bool> shareTextOnly(String message) async {
    try {
      final result =
          await SharePlus.instance.share(ShareParams(text: message));
      if (result.status != ShareResultStatus.success) {
        return false;
      }
      final mixPanelService = GetIt.instance<AnalyticsService>();
      mixPanelService.trackEvent('Text shared');
      return true;
    } catch (error, stackTrace) {
      final loggerService =
          GetIt.instance<IncidentLoggerService>();
      await loggerService.captureLog(
        error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
