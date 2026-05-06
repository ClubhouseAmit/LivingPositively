import 'package:flutter/material.dart';
import 'package:mazilon/util/styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/Phone/emergencyDialogBox.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/EmergencyNumbers.dart';
import 'package:mazilon/l10n/app_localizations.dart';

// Extracts and returns the list of child widgets from a Row widget
List<Widget> extractChildrenFromRow(Row row) {
  return row.children;
}

List<Map<String, dynamic>> _hebrewIsraelEmergencyOrder(
    List<Map<String, dynamic>> numbers) {
  final orderedNumbers = List<Map<String, dynamic>>.of(numbers);
  final index105 =
      orderedNumbers.indexWhere((number) => number['number'] == '105');
  final saharIndex =
      orderedNumbers.indexWhere((number) => number['number'] == '0559571399');

  if (index105 != -1 && saharIndex != -1) {
    final number105 = orderedNumbers[index105];
    orderedNumbers[index105] = orderedNumbers[saharIndex];
    orderedNumbers[saharIndex] = number105;
  }

  return orderedNumbers;
}

// A stateless widget that displays a grid of emergency phone items
class EmergencyPhonesGrid extends StatelessWidget {
  const EmergencyPhonesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final userInfo = Provider.of<UserInformation>(context, listen: true);
    String countryCode = userInfo.location.trim();
    if (countryCode.isEmpty) {
      countryCode = Localizations.localeOf(context).countryCode ??
          defaultPickerCountry.countryCodes.first;
    }

    final Country? country = findCountryByCode(countryCode);
    if (country == null) {
      debugPrint(
          'No emergency mapping for countryCode="$countryCode". Using default "${defaultEmergencyCountry.id}".');
    }
    final activeCountry = country ?? defaultEmergencyCountry;
    final localNumbers = activeCountry.emergencyNumbers;
    final appLocale = AppLocalizations.of(context);
    final displayedNumbers =
        appLocale?.localeName == 'he' && activeCountry.id == 'israel'
            ? _hebrewIsraelEmergencyOrder(localNumbers)
            : localNumbers;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final crossAxisCount = constraints.maxWidth < 300 ? 1 : 2;
          final itemWidth =
              (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                  crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (int index = 0; index < displayedNumbers.length; index++)
                SizedBox(
                  width: itemWidth,
                  child: EmergencyPhoneItem(
                    i: index,
                    number: displayedNumbers[index],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// A custom widget representing an emergency phone item in the grid
class EmergencyPhoneItem extends StatelessWidget {
  final int i; // Index of the emergency phone item

  final dynamic number;
  const EmergencyPhoneItem({required this.i, required this.number, super.key});

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context);
    final isRtl = appLocale?.textDirection == "rtl";
    final descriptionText = isRtl
        ? (number["descriptionHe"] ?? number["description"] ?? '')
        : (number["description"] ?? '');
    return InkWell(
      onTap: () async {
        // Display a dialog when the item is tapped
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return EmergencyDialogBox(
              number: number["number"],
              whatsappNumber: number["whatsappNumber"] ?? number["number"],
              link: number["link"],
              textNumber: number["textNumber"] ?? "",
              textMessage: number["textMessage"] ?? "",
              linkType: number["linkType"] ?? "website",
              hasWhatsApp: number["whatsapp"],
              hasLink: number["link"] != "",
              canCall: number["canCall"],
            );
          },
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 170),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: primaryPurple, width: 1),
          color: Colors.white,
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: myAutoSizedText(
                        number["name"],
                        TextStyle(
                            color: primaryPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp),
                        TextAlign.center,
                        18,
                        2),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: myAutoSizedText(
                        descriptionText.replaceAll(
                            '/', '\n'), // Replace '/' with newline
                        TextStyle(
                            fontWeight: FontWeight.normal,
                            color: primaryPurple,
                            fontSize: 14.sp),
                        TextAlign.center,
                        14),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(-20, -20), // Adjust the position of the icon
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryPurple, width: 1),
                    color: primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    number['icon'],
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
