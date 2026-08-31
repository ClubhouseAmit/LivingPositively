import 'package:url_launcher/url_launcher.dart';

/// Opens Mood Medicine's researched education sources outside the app.
///
/// The feature keeps the platform launcher behind this narrow data boundary so
/// its UI only asks the view model to open a source and can render a generic
/// failure effect without depending on a plugin.
abstract interface class MoodMedicineSourceLinkService {
  /// Opens [source] using the platform's external browser/application.
  ///
  /// Non-HTTPS sources are rejected before the platform launcher is invoked.
  /// Returns `true` when the platform accepts the handoff and `false` when the
  /// source is rejected or no suitable external application is available.
  /// Platform launcher failures are surfaced to the caller as exceptions so
  /// they can be logged without exposing the source URL.
  Future<bool> openExternal(Uri source);
}

/// Production source-link implementation backed by `url_launcher`.
final class UrlLauncherMoodMedicineSourceLinkService
    implements MoodMedicineSourceLinkService {
  /// Creates the source-link service.
  const UrlLauncherMoodMedicineSourceLinkService();

  @override
  Future<bool> openExternal(Uri source) {
    if (source.scheme.toLowerCase() != 'https') {
      return Future<bool>.value(false);
    }
    return launchUrl(
      source,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }
}
