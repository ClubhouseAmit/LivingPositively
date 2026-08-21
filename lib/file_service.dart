// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'dart:math' show min;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/PDF/create_pdf.dart';
import 'package:mazilon/util/file_save_utils.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/type_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mazilon/AnalyticsService.dart';

const String _customCategoryTitlesKey = 'customCategoryTitles';
const String _customCategoryDescriptionsKey = 'customCategoryDescriptions';

abstract class FileService {
  /// Shares a Personal Plan export with its caller-localized [mainTitle].
  ///
  /// The title is rendered before the sections, including when no sections are
  /// populated. Callers provide a non-empty localized title and [textDirection].
  /// Optional [memoryService] overrides the persistent memory source used to read
  /// user plan selections.
  Future<ShareResult?> share(
      String message,
      List<dynamic> titles,
      List<dynamic> subTitles,
      Map<String, String> texts,
      ShareFileType saveFormat,
      {required String mainTitle,
      required String textDirection,
      PersistentMemoryService? memoryService,
      Set<String>? approvedPdfHosts});
  /// Downloads a Personal Plan export with its caller-localized [mainTitle].
  ///
  /// The title is rendered before the sections, including when no sections are
  /// populated. Callers provide a non-empty localized title and [textDirection].
  /// Optional [memoryService] overrides the persistent memory source used to read
  /// user plan selections.
  Future<String?> download(
      List<dynamic> titles,
      List<dynamic> subTitles,
      Map<String, String> texts,
      ShareFileType saveFormat,
      {required String mainTitle,
      required String textDirection,
      PersistentMemoryService? memoryService,
      Set<String>? approvedPdfHosts});
  Future<bool> shareTextOnly(String message);
}

class FileServiceImpl implements FileService {
  static Future<Map<String, dynamic>> getPrefsData({
    PersistentMemoryService? memoryService,
  }) async {
    PersistentMemoryService service = memoryService ??
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

    final futures = <String, Future>{
      'difficultEvents': service.getItem(
        "userSelectionPersonalPlan-DifficultEvents",
        PersistentMemoryType.StringList,
      ),
      'makeSafer': service.getItem(
        "userSelectionPersonalPlan-MakeSafer",
        PersistentMemoryType.StringList,
      ),
      'feelBetter': service.getItem(
        "userSelectionPersonalPlan-FeelBetter",
        PersistentMemoryType.StringList,
      ),
      'distractions': service.getItem(
        "userSelectionPersonalPlan-Distractions",
        PersistentMemoryType.StringList,
      ),
      'safeEnvironment': service.getItem(
        "userSelectionPersonalPlan-SafeEnvironment",
        PersistentMemoryType.StringList,
      ),
      'dreamsAndGoals': service.getItem(
        "userSelectionPersonalPlan-DreamsAndGoals",
        PersistentMemoryType.StringList,
      ),
      'phoneNames': service.getItem(
        "PhonePageSavedPhoneNames",
        PersistentMemoryType.StringList,
      ),
      'phoneNumbers': service.getItem(
          "PhonePageSavedPhoneNumbers", PersistentMemoryType.StringList),
      'customCategoryTitles': service.getItem(
        _customCategoryTitlesKey,
        PersistentMemoryType.StringList,
      ),
      'customCategoryDescriptions': service.getItem(
        _customCategoryDescriptionsKey,
        PersistentMemoryType.StringList,
      ),
    };

    final results = await Future.wait(futures.values);
    final data = Map.fromIterables(futures.keys, results);

    return {
      'DifficultEvents': TypeUtils.castToStringList(data['difficultEvents']),
      'MakeSafer': TypeUtils.castToStringList(data['makeSafer']),
      'FeelBetter': TypeUtils.castToStringList(data['feelBetter']),
      'Distractions': TypeUtils.castToStringList(data['distractions']),
      'SafeEnvironment': TypeUtils.castToStringList(data['safeEnvironment']),
      'DreamsAndGoals': TypeUtils.castToStringList(data['dreamsAndGoals']),
      'phoneNames': TypeUtils.castToStringList(data['phoneNames']),
      'phoneNumbers': TypeUtils.castToStringList(data['phoneNumbers']),
      'customCategoryTitles':
          TypeUtils.castToStringList(data['customCategoryTitles']),
      'customCategoryDescriptions':
          TypeUtils.castToStringList(data['customCategoryDescriptions']),
    };
  }

  static List<List<String>> filterEmptyData(List<List<String>> data) {
    List<List<String>> filtered = [];
    for (var i = 0; i < data.length; i++) {
      if (data[i].isEmpty) {
        continue;
      }
      filtered.add(data[i]);
    }
    return filtered;
  }

  static List<String> formatPhonesText(
    List<String> names,
    List<String> numbers,
  ) {
    List<String> formattedText = [];
    for (var i = 0; i < names.length; i++) {
      formattedText.add('${names[i]}:${numbers[i]}');
    }
    return formattedText;
  }

  Future<Map<String, dynamic>> organizeDataForFile(List<dynamic> titles,
      List<dynamic> subTitles, Map<String, String> texts,
      {required String mainTitle,
      PersistentMemoryService? memoryService,
      Set<String>? approvedPdfHosts}) async {
    // Set the page format to A4

    // Load the font for the PDF
    // Create a new PDF document
    final dataForPDF = await getPrefsData(memoryService: memoryService);
    // Retrieve user data from SharedPreferences
    List<String> difficultEvents = dataForPDF['DifficultEvents'];
    List<String> makeSafer = dataForPDF['MakeSafer'];
    List<String> feelBetter = dataForPDF['FeelBetter'];
    List<String> distractions = dataForPDF['Distractions'];
    List<String> safeEnvironment = dataForPDF['SafeEnvironment'];
    List<String> dreamsAndGoals = dataForPDF['DreamsAndGoals'];
    List<String> phoneNames = dataForPDF['phoneNames'];
    List<String> phoneNumbers = dataForPDF['phoneNumbers'];
    List<String> customCategoryTitles = dataForPDF['customCategoryTitles'];
    List<String> customCategoryDescriptions =
        dataForPDF['customCategoryDescriptions'];
    List<String> phoneDescription = formatPhonesText(phoneNames, phoneNumbers);

    List<List<String>> personalPlanSectionData = [
      distractions,
      difficultEvents,
      feelBetter,
      makeSafer,
      phoneDescription,
      safeEnvironment,
      dreamsAndGoals,
    ];
    final metadataSectionCount = min(
      personalPlanSectionData.length,
      min(titles.length, subTitles.length),
    );
    personalPlanSectionData = personalPlanSectionData
        .take(metadataSectionCount)
        .toList();
    List<dynamic> allTitles = titles.take(metadataSectionCount).toList();
    List<dynamic> allSubTitles = subTitles.take(metadataSectionCount).toList();

    for (
      var i = 0;
      i < customCategoryTitles.length && i < customCategoryDescriptions.length;
      i++
    ) {
      final title = customCategoryTitles[i].trim();
      final description = customCategoryDescriptions[i].trim();
      if (title.isEmpty || description.isEmpty) {
        continue;
      }
      allTitles.add(title);
      allSubTitles.add('');
      personalPlanSectionData.add([description]);
    }

    List<dynamic> realTitles = [];
    List<dynamic> realSubTitles = [];
    List<List<String>> realData = [];
    for (
      var i = 0;
      i < personalPlanSectionData.length &&
          i < allTitles.length &&
          i < allSubTitles.length;
      i++
    ) {
      if (personalPlanSectionData[i].isEmpty) {
        continue;
      }
      realTitles.add(allTitles[i]);
      realSubTitles.add(allSubTitles[i]);
      realData.add(personalPlanSectionData[i]);
    }

    final hosts = approvedPdfHosts ?? defaultApprovedPdfLinkHosts;

    // Retrieve text content for the PDF
    String text1 = texts['firstLine'] ?? '';
    String text2 = texts['firstLinkText'] ?? '';
    String text2Link =
        sanitizePdfLinkUrl(texts['firstLinkURL'], approvedHosts: hosts);
    String text3 = texts['secondLine'] ?? '';
    String text4 = texts['thirdLine'] ?? '';
    String text5 = texts['secondLinkText'] ?? '';
    String text5Link =
        sanitizePdfLinkUrl(texts['secondLinkURL'], approvedHosts: hosts);
    String text6 = texts['forthLine'] ?? '';

    // Prepare the data to be included in the PDF

    // Load the logo image for the PDF

    // Create widgets for the PDF content
    return {
      "mainTitle": mainTitle,
      "titles": realTitles,
      "subTitles": realSubTitles,
      "realData": realData,
      "texts": {
        "text1": text1,
        "text2": text2,
        "text2Link": text2Link,
        "text3": text3,
        "text4": text4,
        "text5": text5,
        "text5Link": text5Link,
        "text6": text6,
      },
    };
  }

  //New version of SharePlus can't sennd empty "" message
  String? checkEmptyMessage(String message) {
    return message.isEmpty ? null : message;
  }

  @override
  Future<ShareResult?> share(
      String message,
      List<dynamic> titles,
      List<dynamic> subTitles,
      Map<String, String> texts,
      ShareFileType saveFormat,
      {required String mainTitle,
      required String textDirection,
      PersistentMemoryService? memoryService,
      Set<String>? approvedPdfHosts}) async {
    try {
      // Add the generated widgets to the PDF
      final dataForFile = await organizeDataForFile(titles, subTitles, texts,
          mainTitle: mainTitle,
          memoryService: memoryService,
          approvedPdfHosts: approvedPdfHosts);
      Map<String, dynamic> file;
      switch (saveFormat) {
        case ShareFileType.PDF:
          file = await createPDF(
            dataForFile["titles"]!,
            dataForFile["subTitles"]!,
            dataForFile["texts"]!,
            dataForFile["mainTitle"]!,
            dataForFile["realData"]!,
            textDirection,
            approvedHosts: approvedPdfHosts ?? defaultApprovedPdfLinkHosts,
          );
          final tempFile = await saveTempPDF(file["file"], file["format"]);
          XFile tempXFile = XFile(tempFile.path);

          final shareResult = await SharePlus.instance.share(ShareParams(
              files: [tempXFile], text: checkEmptyMessage(message)));
          if (shareResult.status == ShareResultStatus.success) {
            AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
            mixPanelService.trackEvent("Plan shared");
          }
          return shareResult;
        default:
          file = {"file": null, "format": null};
      }

      return null;
    } catch (error, stackTrace) {
      IncidentLoggerService loggerService =
          GetIt.instance<IncidentLoggerService>();
      await loggerService.captureLog(
        error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Saves Personal Plan [data] to user-selected device storage on Android.
  ///
  /// [data] is the binary content to save, and [format] is the target file extension (e.g. `'pdf'`).
  ///
  /// [dialogTitle] is the title displayed on the native save file dialog; defaults to
  /// `'Please select an output file:'` if omitted or null.
  /// [fileName] is the suggested default filename; defaults to `'התוכנית שלי.$format'` if omitted or null.
  ///
  /// [fileSaver] is an optional injected file saver callback used for testing or custom saver delegation.
  /// Accepts [String] file paths or [Uri] results (including `file:` and `content:` URIs).
  ///
  /// Returns the normalized saved file path or URI string upon success, or `null` if the user
  /// cancels the save operation or if saving fails.
  static Future<String?> saveAndroid(
    Uint8List data,
    String format, {
    String? dialogTitle,
    String? fileName,
    Future<dynamic> Function({
      String? dialogTitle,
      String? fileName,
      FileType type,
      String? initialDirectory,
      Uint8List? bytes,
      List<String>? allowedExtensions,
    })? fileSaver,
  }) async {
    try {
      final effectiveDialogTitle =
          dialogTitle ?? 'Please select an output file:';
      final effectiveFileName = fileName ?? 'התוכנית שלי.$format';
      final customSaver = fileSaver;
      final dynamic outputFile;
      if (customSaver != null) {
        outputFile = await customSaver(
          dialogTitle: effectiveDialogTitle,
          fileName: effectiveFileName,
          bytes: data,
        );
      } else {
        outputFile = await FilePicker.saveFile(
          dialogTitle: effectiveDialogTitle,
          fileName: effectiveFileName,
          bytes: data,
        );
      }
      //If the user cancels the download
      AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
      mixPanelService.trackEvent("Plan downloaded Android");
      return FileSaveUtils.normalizeSavedFileDestination(outputFile);
    } catch (error, stackTrace) {
      IncidentLoggerService loggerService =
          GetIt.instance<IncidentLoggerService>();
      await loggerService.captureLog(error, stackTrace: stackTrace);
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

    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent("Plan downloaded Web");
    return null;
  }

  @override
  Future<String?> download(
      List<dynamic> titles,
      List<dynamic> subTitles,
      Map<String, String> texts,
      ShareFileType saveFormat,
      {required String mainTitle,
      required String textDirection,
      PersistentMemoryService? memoryService,
      Set<String>? approvedPdfHosts}) async {
    final dataForFile = await organizeDataForFile(titles, subTitles, texts,
        mainTitle: mainTitle,
        memoryService: memoryService,
        approvedPdfHosts: approvedPdfHosts);
    Map<String, dynamic> file;
    Uint8List data = Uint8List(0);
    switch (saveFormat) {
      case ShareFileType.PDF:
        file = await createPDF(
          dataForFile["titles"]!,
          dataForFile["subTitles"]!,
          dataForFile["texts"]!,
          dataForFile["mainTitle"]!,
          dataForFile["realData"]!,
          textDirection,
          approvedHosts: approvedPdfHosts ?? defaultApprovedPdfLinkHosts,
        );
        // Save the PDF and share it

        // Save the PDF for download
        data = await file["file"].save();

        break;
      default:
        file = {"file": null, "format": null};
    }
    if (file["file"] == null || file["format"] == null) {
      return null;
    }
    if (Platform.isAndroid) {
      return await saveAndroid(data, file["format"]);
    }
    if (kIsWeb) {
      return await saveWeb(data);
    }
    return null;
  }

  @override
  Future<bool> shareTextOnly(String message) async {
    try {
      final result = await SharePlus.instance.share(ShareParams(text: message));
      if (result.status != ShareResultStatus.success) {
        return false;
      }
      AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
      mixPanelService.trackEvent("Text shared");
      return true;
    } catch (error, stackTrace) {
      IncidentLoggerService loggerService =
          GetIt.instance<IncidentLoggerService>();
      await loggerService.captureLog(error, stackTrace: stackTrace);
      return false;
    }
  }
}
