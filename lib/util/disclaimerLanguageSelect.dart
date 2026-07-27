import 'package:flutter/material.dart';

class LanguageDropDown extends StatefulWidget {
  final List<Map<String, String>> list = [
    {'locale': 'en', 'label': 'English'},
    {'locale': 'he', 'label': 'עברית'},
    {'locale': 'ar', 'label': 'العربية'},
  ];

  final Function changeLocale;
  LanguageDropDown({required this.changeLocale, super.key});

  @override
  State<LanguageDropDown> createState() => _LanguageDropDownState();
}

class _LanguageDropDownState extends State<LanguageDropDown> {
  late String? dropdownValue;

  Widget _languageOption(Map<String, String> item, Color foregroundColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.language, size: 20, color: foregroundColor),
        const SizedBox(width: 10),
        Text(
          item['label'] ?? item['locale']!,
          style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    final Locale defaultSystemLocale =
        WidgetsBinding.instance.platformDispatcher.locale;
    final supportedLocale = widget.list
        .where((item) => item['locale'] == defaultSystemLocale.languageCode)
        .toList();
    dropdownValue = supportedLocale.isNotEmpty
        ? supportedLocale.first['locale']
        : widget.list.first['locale'];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20.0),
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: widget.list
                .map(
                  (item) => Text(
                    item['label'] ?? item['locale']!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width > 1000
              ? 600
              : MediaQuery.of(context).size.width * 0.5,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20), // Rounded edges
          ),
          child: DropdownButton<String>(
            value: dropdownValue,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            iconSize: 24,
            isExpanded: true,
            dropdownColor: Theme.of(context).colorScheme.surface,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            underline: SizedBox.shrink(),
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  dropdownValue = value;
                  widget.changeLocale(value); // Update the locale
                });
              }
            },
            selectedItemBuilder: (context) {
              return widget.list
                  .map<Widget>(
                    (item) => _languageOption(
                      item,
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                  .toList();
            },
            items: widget.list.map<DropdownMenuItem<String>>((
              Map<String, String> item,
            ) {
              return DropdownMenuItem<String>(
                value: item['locale']!,
                child: _languageOption(
                  item,
                  Theme.of(context).colorScheme.onSurface,
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 20.0),
      ],
    );
  }
}
