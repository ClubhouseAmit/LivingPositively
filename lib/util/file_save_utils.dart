/// Utility functions for file saving operations across platforms.
class FileSaveUtils {
  /// Normalizes platform-specific save results ([String], [Uri], or custom object) to a file path string.
  ///
  /// Returns `null` if [result] is `null`. If [result] is already a [String],
  /// returns it directly. If [result] is a [Uri], returns [Uri.path].
  /// Otherwise, converts [result] to a string via [Object.toString].
  static String? normalizeSavedFilePath(dynamic result) {
    if (result == null) {
      return null;
    }
    if (result is String) {
      return result;
    }
    if (result is Uri) {
      return result.path;
    }
    return result.toString();
  }
}
