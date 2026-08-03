import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:mazilon/EmergencyNumbers.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Phone/emergencyDialogBox.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

// Extracts and returns the list of child widgets from a Row widget
List<Widget> extractChildrenFromRow(Row row) {
  return row.children;
}

List<Map<String, dynamic>> _hebrewIsraelEmergencyOrder(
  List<Map<String, dynamic>> numbers,
) {
  final orderedNumbers = List<Map<String, dynamic>>.of(numbers);
  final index105 = orderedNumbers.indexWhere(
    (number) => number['number'] == '105',
  );
  final saharIndex = orderedNumbers.indexWhere(
    (number) => number['number'] == '0559571399',
  );

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
    final userInfo = Provider.of<UserInformation>(context);
    var countryCode = userInfo.location.trim();
    if (countryCode.isEmpty) {
      countryCode =
          Localizations.localeOf(context).countryCode ??
          defaultPickerCountry.countryCodes.first;
    }

    final country = findCountryByCode(countryCode);
    if (country == null) {
      debugPrint(
        'No emergency mapping for countryCode="$countryCode". Using default "${defaultEmergencyCountry.id}".',
      );
    }
    final activeCountry = country ?? defaultEmergencyCountry;
    final isFallback = country == null;
    final localNumbers = <Map<String, dynamic>>[
      ...activeCountry.emergencyNumbers,
    ];
    final appLocale = AppLocalizations.of(context);
    final orderedNumbers =
        appLocale?.localeName == 'he' && activeCountry.id == 'israel'
        ? _hebrewIsraelEmergencyOrder(localNumbers)
        : localNumbers;
    final displayedNumbers = <Map<String, dynamic>>[
      ...orderedNumbers,
      if (userInfo.age.trim() == '18-') elemSupportOption,
    ];

    Widget? fallbackBanner;
    if (isFallback) {
      final localizedCountry = activeCountry.id;
      fallbackBanner = Semantics(
        liveRegion: true,
        container: true,
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E5),
            border: Border.all(color: const Color(0xFFE0A82E)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFB76E00),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appLocale?.emergencyCountryFallback(localizedCountry) ??
                      'Showing default emergency numbers ($localizedCountry). They may not connect from your current location.',
                  style: const TextStyle(
                    color: Color(0xFF7A4B00),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final crossAxisCount = constraints.maxWidth < 300 ? 1 : 2;
          final itemWidth =
              (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
              crossAxisCount;

          final grid = Wrap(
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

          if (fallbackBanner == null) {
            return grid;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [fallbackBanner, grid],
          );
        },
      ),
    );
  }
}

// A custom widget representing an emergency phone item in the grid
class EmergencyPhoneItem extends StatelessWidget {
  const EmergencyPhoneItem({required this.i, required this.number, super.key});
  final int i; // Index of the emergency phone item

  final dynamic number;

  @override
  Widget build(BuildContext context) {
    final appLocale = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isRtl = appLocale?.textDirection == 'rtl';
    final descriptionText = isRtl
        ? (number['descriptionHe'] ?? number['description'] ?? '')
        : (number['description'] ?? '');
    return InkWell(
      onTap: () async {
        // Display a dialog when the item is tapped
        showDialog(
          context: context,
          builder: (context) {
            return EmergencyDialogBox(
              number: number['number'],
              whatsappNumber: number['whatsappNumber'] ?? number['number'],
              link: number['link'],
              textNumber: number['textNumber'] ?? '',
              textMessage: number['textMessage'] ?? '',
              linkType: number['linkType'] ?? 'website',
              hasWhatsApp: number['whatsapp'],
              hasLink: number['link'] != '',
              canCall: number['canCall'],
            );
          },
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 170),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.primary),
          color: colorScheme.surfaceContainerHighest,
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
                    child: AutoSizeText(
                      number['name'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: AutoSizeText(
                      descriptionText.replaceAll(
                        '/',
                        '\n',
                      ), // Replace '/' with newline
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.normal,
                            color: colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
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
                    border: Border.all(color: colorScheme.primary),
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    number['icon'],
                    color: colorScheme.onPrimary,
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
