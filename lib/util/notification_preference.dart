class NotificationPreference {
  final int hour;
  final int minute;

  const NotificationPreference({required this.hour, required this.minute});

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  factory NotificationPreference.fromJson(Map<String, dynamic> json) =>
      NotificationPreference(hour: json['hour'] as int, minute: json['minute'] as int);
}
