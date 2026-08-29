import 'package:url_launcher/url_launcher.dart';

/// Opens Mood Medicine's researched education sources outside the app.
///
/// The feature keeps the platform launcher behind this narrow data boundary so
/// its UI only asks the view model to open a source and can render a generic
/// failure effect without depending on a plugin.
abstract interface class MoodMedicineSourceLinkService {
  /// Opens [source] using the platform's external browser/application.
  Future<bool> openExternal(Uri source);
}

/// Production source-link implementation backed by `url_launcher`.
final class UrlLauncherMoodMedicineSourceLinkService
    implements MoodMedicineSourceLinkService {
  /// Creates the source-link service.
  const UrlLauncherMoodMedicineSourceLinkService();

  @override
  Future<bool> openExternal(Uri source) {
    return launchUrl(
      source,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }
}
