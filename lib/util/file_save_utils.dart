/// Utility functions for file saving operations across platforms.
final class FileSaveUtils {
  FileSaveUtils._();

  /// Normalizes platform-specific save results ([String] or [Uri]) to a valid destination string.
  ///
  /// Returns `null` if [result] is `null`, an empty [String], an unsupported type
  /// (such as numbers, booleans, or arbitrary objects), or a [Uri] with an empty path.
  ///
  /// If [result] is a non-empty [String], returns the string path.
  /// If [result] is a [Uri] with the `file` scheme or no scheme, returns [Uri.path].
  /// If [result] is a non-file [Uri] (such as Android `content://...` URIs),
  /// returns the full URI string via [Uri.toString] to preserve scheme and authority.
  static String? normalizeSavedFilePath(dynamic result) {
    if (result == null) {
      return null;
    }
    if (result is String) {
      final trimmed = result.trim();
      return trimmed.isEmpty ? null : result;
    }
    if (result is Uri) {
      if (result.scheme.isNotEmpty && !result.isScheme('file')) {
        final uriString = result.toString();
        return uriString.trim().isEmpty ? null : uriString;
      }
      final path = result.path;
      return path.trim().isEmpty ? null : path;
    }
    return null;
  }
}
