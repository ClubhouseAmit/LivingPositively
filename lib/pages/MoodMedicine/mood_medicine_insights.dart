import 'dart:collection';

import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';

/// The supported calendar intervals for the Mood Medicine dashboard.
enum MoodMedicineInsightRange { day, week, month, year }

/// Daily data used for a chart point, accessible summary, and associations.
final class MoodMedicineDailySummary {
  MoodMedicineDailySummary({
    required this.dayKey,
    required this.averageMood,
    required Iterable<String> activityIds,
    required this.checkInCount,
  }) : activityIds = Set<String>.unmodifiable(activityIds);

  final String dayKey;
  final double averageMood;
  final Set<String> activityIds;
  final int checkInCount;
}

/// A descriptive comparison of daily mood averages, never a causal claim.
final class MoodMedicineAssociation {
  const MoodMedicineAssociation({
    required this.activityId,
    required this.withActivityDays,
    required this.withoutActivityDays,
    required this.withActivityAverageMood,
    required this.withoutActivityAverageMood,
  });

  final String activityId;
  final int withActivityDays;
  final int withoutActivityDays;
  final double withActivityAverageMood;
  final double withoutActivityAverageMood;

  double get averageMoodDifference =>
      withActivityAverageMood - withoutActivityAverageMood;
}

/// Pure aggregation helpers. They only use stored local day keys, preserving
/// the user's check-in-day meaning even when a device timezone later changes.
abstract final class MoodMedicineInsights {
  static List<MoodMedicineDailySummary> dailySummaries(
    Iterable<MoodMedicineEntry> entries,
  ) {
    final Map<String, _DailyAccumulator> byDay = <String, _DailyAccumulator>{};
    for (final MoodMedicineEntry entry in entries) {
      final _DailyAccumulator accumulator = byDay.putIfAbsent(
        entry.localDayKey,
        _DailyAccumulator.new,
      );
      accumulator.add(entry);
    }

    final List<MoodMedicineDailySummary> summaries = byDay.entries
        .map(
          (MapEntry<String, _DailyAccumulator> item) =>
              item.value.toSummary(item.key),
        )
        .toList(growable: false);
    summaries.sort(
      (MoodMedicineDailySummary a, MoodMedicineDailySummary b) =>
          a.dayKey.compareTo(b.dayKey),
    );
    return List<MoodMedicineDailySummary>.unmodifiable(summaries);
  }

  static List<MoodMedicineDailySummary> summariesForRange(
    Iterable<MoodMedicineEntry> entries, {
    required MoodMedicineInsightRange range,
    required DateTime anchor,
  }) {
    final DateTime localAnchor = anchor.toLocal();
    final DateTime start = _rangeStart(range, localAnchor);
    final DateTime end = _startOfDay(localAnchor);
    return dailySummaries(entries)
        .where((MoodMedicineDailySummary summary) {
          final DateTime day = DateTime.parse(summary.dayKey);
          return !day.isBefore(start) && !day.isAfter(end);
        })
        .toList(growable: false);
  }

  /// Returns only comparisons with at least three activity days and three
  /// non-activity days. Results describe association, not causation.
  static List<MoodMedicineAssociation> associations(
    Iterable<MoodMedicineDailySummary> summaries, {
    Iterable<String>? activityIds,
  }) {
    final List<MoodMedicineDailySummary> days = summaries.toList(
      growable: false,
    );
    final Set<String> candidates = activityIds == null
        ? days.expand((MoodMedicineDailySummary day) => day.activityIds).toSet()
        : activityIds.toSet();
    final List<MoodMedicineAssociation> result = <MoodMedicineAssociation>[];

    for (final String activityId in candidates) {
      final List<MoodMedicineDailySummary> withActivity = days
          .where(
            (MoodMedicineDailySummary day) =>
                day.activityIds.contains(activityId),
          )
          .toList(growable: false);
      final List<MoodMedicineDailySummary> withoutActivity = days
          .where(
            (MoodMedicineDailySummary day) =>
                !day.activityIds.contains(activityId),
          )
          .toList(growable: false);
      if (withActivity.length < 3 || withoutActivity.length < 3) {
        continue;
      }
      result.add(
        MoodMedicineAssociation(
          activityId: activityId,
          withActivityDays: withActivity.length,
          withoutActivityDays: withoutActivity.length,
          withActivityAverageMood: _average(
            withActivity.map((MoodMedicineDailySummary day) => day.averageMood),
          ),
          withoutActivityAverageMood: _average(
            withoutActivity.map(
              (MoodMedicineDailySummary day) => day.averageMood,
            ),
          ),
        ),
      );
    }
    result.sort((MoodMedicineAssociation a, MoodMedicineAssociation b) {
      final int byDifference = b.averageMoodDifference.abs().compareTo(
        a.averageMoodDifference.abs(),
      );
      return byDifference != 0
          ? byDifference
          : a.activityId.compareTo(b.activityId);
    });
    return List<MoodMedicineAssociation>.unmodifiable(result);
  }

  static DateTime _rangeStart(MoodMedicineInsightRange range, DateTime anchor) {
    final DateTime day = _startOfDay(anchor);
    return switch (range) {
      MoodMedicineInsightRange.day => day,
      MoodMedicineInsightRange.week => day.subtract(
        Duration(days: day.weekday - DateTime.monday),
      ),
      MoodMedicineInsightRange.month => DateTime(day.year, day.month),
      MoodMedicineInsightRange.year => DateTime(day.year),
    };
  }

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static double _average(Iterable<double> values) {
    final List<double> list = values.toList(growable: false);
    return list.fold<double>(0, (double total, double value) => total + value) /
        list.length;
  }
}

final class _DailyAccumulator {
  int _moodTotal = 0;
  int _checkInCount = 0;
  final Set<String> _activityIds = <String>{};

  void add(MoodMedicineEntry entry) {
    _moodTotal += entry.mood;
    _checkInCount += 1;
    _activityIds.addAll(entry.activityIds);
  }

  MoodMedicineDailySummary toSummary(String dayKey) => MoodMedicineDailySummary(
    dayKey: dayKey,
    averageMood: _moodTotal / _checkInCount,
    activityIds: UnmodifiableSetView<String>(_activityIds),
    checkInCount: _checkInCount,
  );
}
