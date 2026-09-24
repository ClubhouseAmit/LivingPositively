import 'package:flutter/material.dart';

class LanguageDropDown extends StatefulWidget {
  final List<Map<String, String>> list = const [
    {'locale': 'en', 'label': 'English'},
    {'locale': 'he', 'label': 'עברית'},
    {'locale': 'ar', 'label': 'العربية'},
  ];

  final Function changeLocale;
  const LanguageDropDown({required this.changeLocale, super.key});

  @override
  State<LanguageDropDown> createState() => _LanguageDropDownState();
}

class _LanguageDropDownState extends State<LanguageDropDown> {
  String? _selectedLocale;

  @override
  Widget build(BuildContext context) {
    final currentLocaleCode = _selectedLocale ??
        Localizations.maybeLocaleOf(context)?.languageCode ??
        widget.list.first['locale']!;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < widget.list.length; i++) ...[
              if (i > 0)
                Text(
                  '|',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                ),
              _buildLanguageItem(context, widget.list[i], currentLocaleCode),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(
    BuildContext context,
    Map<String, String> item,
    String currentLocaleCode,
  ) {
    final isSelected = item['locale'] == currentLocaleCode;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedLocale = item['locale'];
          });
          widget.changeLocale(item['locale']!);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        child: Text(
          item['label'] ?? item['locale']!,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? primaryColor
                : onSurfaceColor.withValues(alpha: 0.7),
            decoration:
                isSelected ? TextDecoration.underline : TextDecoration.none,
            decorationColor: primaryColor,
            decorationThickness: 2,
          ),
        ),
      ),
    );
  }
}

