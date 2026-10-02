import 'dart:js_interop';

/// Whether the browser's resolved hour cycle uses a 24-hour clock.
///
/// Omitting [locale] uses the browser's Intl default, independently of the app's
/// display language. Returns null when Intl cannot report a supported cycle.
bool? browserUses24HourFormat({String? locale}) {
  try {
    // An empty locale list requests Intl's default without passing JS null.
    final JSAny locales = locale?.toJS ?? JSArray<JSString>();
    final formatter = _IntlDateTimeFormat(
      locales,
      _DateTimeFormatOptions(hour: 'numeric'.toJS),
    );
    return switch (formatter.resolvedOptions().hourCycle?.toDart) {
      'h23' || 'h24' => true,
      'h11' || 'h12' => false,
      _ => null,
    };
  } on Object {
    // Missing Intl APIs and invalid locale tags must preserve caller fallbacks.
    return null;
  }
}

@JS('Intl.DateTimeFormat')
extension type _IntlDateTimeFormat._(JSObject _) implements JSObject {
  external _IntlDateTimeFormat(
    JSAny locales,
    _DateTimeFormatOptions options,
  );

  external _DateTimeFormatResolvedOptions resolvedOptions();
}

extension type _DateTimeFormatOptions._(JSObject _) implements JSObject {
  external _DateTimeFormatOptions({JSString hour});
}

extension type _DateTimeFormatResolvedOptions._(JSObject _)
    implements JSObject {
  external JSString? get hourCycle;
}
