class NotificationPreference {
  final int hour;
  final int minute;

  const NotificationPreference({required this.hour, required this.minute});

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    final hour = _parseInt(json['hour']);
    final minute = _parseInt(json['minute']);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw const FormatException('Invalid notification preference time');
    }
    return NotificationPreference(hour: hour, minute: minute);
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
