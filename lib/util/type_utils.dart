class TypeUtils {
  /// cast a dynamic value to `List<String>`
  static List<String> castToStringList(dynamic value) {
    return (value as List<dynamic>?)?.cast<String>() ?? <String>[];
  }

  /// cast a dynamic value to String

  static String castToString(dynamic value) {
    return value?.toString() ?? '';
  }
}
