import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Maps the `'rtl'` direction token to RTL; all other values fall back to LTR.
pw.TextDirection pdfTextDirectionForDirection(String textDirection) =>
    textDirection == 'rtl' ? pw.TextDirection.rtl : pw.TextDirection.ltr;

/// Maps the `'rtl'` direction token to right alignment; all other values use left.
pw.Alignment pdfAlignmentForDirection(String textDirection) =>
    textDirection == 'rtl' ? pw.Alignment.centerRight : pw.Alignment.centerLeft;

/// Maps the `'rtl'` direction token to right text alignment; all other values use left.
pw.TextAlign pdfTextAlignForDirection(String textDirection) =>
    textDirection == 'rtl' ? pw.TextAlign.right : pw.TextAlign.left;

/// Default production domains approved for clickable PDF links.
const Set<String> defaultApprovedPdfLinkHosts = {
  'livepositively.club',
  'mazilon.com',
};

/// Supported keys in [sharePDFtexts] that represent external URL destinations.
const List<String> supportedPdfLinkUrlKeys = [
  'firstLinkURL',
  'secondLinkURL',
];

/// Validates whether [host] belongs to [approvedHosts] or any subdomain thereof.
bool isApprovedPdfLinkHost(
  String host, {
  Set<String> approvedHosts = defaultApprovedPdfLinkHosts,
}) {
  final lowerHost = host.toLowerCase();
  for (final approved in approvedHosts) {
    final lowerApproved = approved.toLowerCase();
    if (lowerHost == lowerApproved || lowerHost.endsWith('.$lowerApproved')) {
      return true;
    }
  }
  return false;
}

/// Sanitizes [rawUrl], requiring an HTTPS scheme, default HTTPS port (unspecified or 443),
/// and a host matching [approvedHosts].
/// Returns the valid trimmed URL, or an empty string if invalid or unapproved.
String sanitizePdfLinkUrl(
  String? rawUrl, {
  Set<String> approvedHosts = defaultApprovedPdfLinkHosts,
}) {
  if (rawUrl == null || rawUrl.trim().isEmpty) {
    return '';
  }
  try {
    final uri = Uri.parse(rawUrl.trim());
    if (uri.scheme.toLowerCase() != 'https') {
      return '';
    }
    if (uri.host.isEmpty) {
      return '';
    }
    if (uri.hasPort && uri.port != 443) {
      return '';
    }
    if (!isApprovedPdfLinkHost(uri.host, approvedHosts: approvedHosts)) {
      return '';
    }
    return uri.toString();
  } catch (_) {
    return '';
  }
}

/// Sanitizes all recognized link URLs within [texts] prior to PDF creation or download.
Map<String, String> sanitizeSharePdfTexts(
  Map<String, String> texts, {
  Set<String> approvedHosts = defaultApprovedPdfLinkHosts,
  List<String> urlKeys = supportedPdfLinkUrlKeys,
}) {
  final sanitized = Map<String, String>.from(texts);
  for (final key in urlKeys) {
    if (sanitized.containsKey(key)) {
      sanitized[key] = sanitizePdfLinkUrl(
        sanitized[key],
        approvedHosts: approvedHosts,
      );
    }
  }
  return sanitized;
}

Future<Map<String, dynamic>> createPDF(
  List<dynamic> titles,
  List<dynamic> subTitles,
  Map<String, String> texts,
  String mainTitle,
  List<List<String>> data,
  String textDirection, {
  Set<String> approvedHosts = defaultApprovedPdfLinkHosts,
}) async {
  final pageFormat = PdfPageFormat.a4;
  final ByteData fontData = await rootBundle.load('assets/fonts/CALIBRI.TTF');
  final ttf = pw.Font.ttf(fontData.buffer.asByteData());
  final imageData = await rootBundle.load('assets/images/Logo.png');
  final imageBytes = imageData.buffer.asUint8List();
  final image = pw.Image(pw.MemoryImage(imageBytes));
  final pdf = pw.Document();
  List<pw.Widget> widgets = [];
  final pdfTextDirection = pdfTextDirectionForDirection(textDirection);
  final alignment = pdfAlignmentForDirection(textDirection);
  final textAlign = pdfTextAlignForDirection(textDirection);
  if (mainTitle.isNotEmpty) {
    widgets.add(
      pw.Container(
        width: pageFormat.availableWidth,
        child: pw.Align(
          alignment: alignment,
          child: pw.Directionality(
            textDirection: pdfTextDirection,
            child: pw.Text(
              mainTitle,
              style: pw.TextStyle(fontSize: 40, font: ttf),
            ),
          ),
        ),
      ),
    );
  }
  var hasRenderedSection = false;
  for (var i = 0; i < data.length; i++) {
    if (data[i].isEmpty) {
      continue;
    }

    if (hasRenderedSection) {
      widgets.add(pw.SizedBox(height: 25));
    }

    // Add the title, subtitle, and data for each section
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.all(8.0),
        child: pw.Directionality(
          textDirection: pdfTextDirection,
          child: pw.Column(
            children: [
              pw.Container(
                width: pageFormat.availableWidth,
                child: pw.Align(
                  alignment: alignment,
                  child: pw.Text(
                    titles[i],
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      font: ttf,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Container(
                width: pageFormat.availableWidth,
                child: pw.Align(
                  alignment: alignment,
                  child: pw.Text(
                    subTitles[i],
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      font: ttf,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Container(
                color: const PdfColor.fromInt(0xfaf6fd),
                child: pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    for (var entry in data[i].asMap().entries)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(right: 5),
                            child: pw.Text(
                              '${entry.key + 1}. ${entry.value}',
                              style: pw.TextStyle(fontSize: 20, font: ttf),
                              textAlign: textAlign,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    hasRenderedSection = true;
  }

  // Add space before footer
  widgets.add(pw.Expanded(child: pw.SizedBox()));

  final sanitizedFirstLinkUrl = sanitizePdfLinkUrl(
    texts["firstLinkURL"] ?? texts["text2Link"],
    approvedHosts: approvedHosts,
  );
  final sanitizedSecondLinkUrl = sanitizePdfLinkUrl(
    texts["secondLinkURL"] ?? texts["text5Link"],
    approvedHosts: approvedHosts,
  );

  pw.Widget buildLinkWidget(String text, String sanitizedLink) {
    final textWidget = pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 24,
        font: ttf,
        color: sanitizedLink.isNotEmpty ? PdfColors.blue : null,
      ),
      textAlign: textAlign,
    );
    if (sanitizedLink.isNotEmpty) {
      return pw.UrlLink(
        destination: sanitizedLink,
        child: textWidget,
      );
    }
    return textWidget;
  }

  // Add the footer content to the PDF
  widgets.add(
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Directionality(
          textDirection: pdfTextDirection,
          child: pw.Text(
            texts["text1"] ?? '',
            style: pw.TextStyle(fontSize: 20, font: ttf),
            textAlign: textAlign,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Directionality(
          textDirection: pdfTextDirection,
          child: buildLinkWidget(texts["text2"] ?? '', sanitizedFirstLinkUrl),
        ),
        pw.SizedBox(height: 10),
        pw.Directionality(
          textDirection: pdfTextDirection,
          child: pw.Text(
            texts["text3"] ?? '',
            style: pw.TextStyle(fontSize: 20, font: ttf),
            textAlign: textAlign,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Directionality(
          textDirection: pdfTextDirection,
          child: pw.Text(
            texts["text4"] ?? '',
            style: pw.TextStyle(fontSize: 20, font: ttf),
            textAlign: textAlign,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Directionality(
          textDirection: pdfTextDirection,
          child: buildLinkWidget(texts["text5"] ?? '', sanitizedSecondLinkUrl),
        ),
        pw.SizedBox(height: 10),
        pw.Directionality(
          textDirection: pdfTextDirection,
          child: pw.Text(
            texts["text6"] ?? '',
            style: pw.TextStyle(fontSize: 20, font: ttf),
            textAlign: textAlign,
          ),
        ),
      ],
    ),
  );

  // Add the generated widgets to the PDF
  pdf.addPage(
    pw.MultiPage(
      header: (context) {
        return pw.Row(
          children: [pw.SizedBox(height: 100, width: 100, child: image)],
        );
      },
      pageFormat: PdfPageFormat.a4,
      build: (context) => widgets, // Build the PDF with the generated widgets
    ),
  );
  return {"file": pdf, "format": "pdf"};
}

Future<File> saveTempPDF(pw.Document pdf, String format) async {
  Uint8List fileData = await pdf.save();
  final tempDir = await getTemporaryDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final tempFile = File('${tempDir.path}/התוכנית שלי$timestamp.$format');
  await tempFile.writeAsBytes(fileData);
  return tempFile;
}
