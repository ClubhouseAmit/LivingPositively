import 'dart:collection';

import 'package:mazilon/features/mood_medicine/data/mood_medicine_models.dart';

/// The supported calendar intervals for the Mood Medicine dashboard.
enum MoodMedicineInsightRange { day, week, month, year }

/// One persisted check-in presented as an individual mood-trend point.
final class MoodMedicineTrendCheckIn {
  MoodMedicineTrendCheckIn({
    required this.id,
    required this.localDayKey,
    required this.occurredAtUtc,
    required this.mood,
    required Iterable<String> activityIds,
  }) : activityIds = Set<String>.unmodifiable(activityIds);

  final String id;
  final String localDayKey;
  final DateTime occurredAtUtc;
  final int mood;
  final Set<String> activityIds;
}

/// Bounded presentation data for the mood trend.
final class MoodMedicineTrendSeries {
  MoodMedicineTrendSeries({
    required Iterable<MoodMedicineTrendCheckIn> checkIns,
    this.omittedCount = 0,
  }) : checkIns = List<MoodMedicineTrendCheckIn>.unmodifiable(checkIns);

  final List<MoodMedicineTrendCheckIn> checkIns;
  final int omittedCount;
}

/// Daily data used for associations and exported reports.
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

/// Pure aggregation helpers. Range membership uses stored local day keys,
/// preserving the user's check-in-day meaning when a timezone later changes.
abstract final class MoodMedicineInsights {
  /// Maximum number of check-ins presented for a year-range trend.
  static const int maxYearTrendPoints = 1000;

  /// Returns check-ins in the selected local-day range.
  ///
  /// Entries are ordered by their actual timestamp so repeated check-ins remain
  /// distinct and follow the sequence in which they happened. Year ranges are
  /// bounded to [maxYearTrendPoints] for presentation; persisted history is
  /// never removed.
  static MoodMedicineTrendSeries checkInsForRange(
    Iterable<MoodMedicineEntry> entries, {
    required MoodMedicineInsightRange range,
    required DateTime anchor,
  }) {
    final DateTime localAnchor = anchor.toLocal();
    final DateTime start = _rangeStart(range, localAnchor);
    final DateTime end = _startOfDay(localAnchor);
    final int? limit = range == MoodMedicineInsightRange.year
        ? maxYearTrendPoints
        : null;
    final List<MoodMedicineTrendCheckIn> checkIns =
        <MoodMedicineTrendCheckIn>[];
    var omittedCount = 0;
    for (final MoodMedicineEntry entry in entries) {
      if (!_isDayInRange(entry.localDayKey, start: start, end: end)) {
        continue;
      }
      final MoodMedicineTrendCheckIn checkIn = MoodMedicineTrendCheckIn(
        id: entry.id,
        localDayKey: entry.localDayKey,
        occurredAtUtc: entry.occurredAtUtc,
        mood: entry.mood,
        activityIds: entry.activityIds,
      );
      if (limit == null) {
        checkIns.add(checkIn);
        continue;
      }
      final int insertionIndex = _trendInsertionIndex(checkIns, checkIn);
      checkIns.insert(insertionIndex, checkIn);
      if (checkIns.length > limit) {
        checkIns.removeAt(0);
        omittedCount += 1;
      }
    }
    if (limit == null) {
      checkIns.sort(_compareTrendCheckIns);
    }
    return MoodMedicineTrendSeries(
      checkIns: checkIns,
      omittedCount: omittedCount,
    );
  }

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
          return _isDayInRange(summary.dayKey, start: start, end: end);
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

  static bool _isDayInRange(
    String dayKey, {
    required DateTime start,
    required DateTime end,
  }) {
    final DateTime day = DateTime.parse(dayKey);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  static int _trendInsertionIndex(
    List<MoodMedicineTrendCheckIn> values,
    MoodMedicineTrendCheckIn value,
  ) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final int middle = (low + high) ~/ 2;
      if (_compareTrendCheckIns(values[middle], value) <= 0) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  static int _compareTrendCheckIns(
    MoodMedicineTrendCheckIn a,
    MoodMedicineTrendCheckIn b,
  ) {
    final int byTime = a.occurredAtUtc.compareTo(b.occurredAtUtc);
    if (byTime != 0) {
      return byTime;
    }
    final int byDay = a.localDayKey.compareTo(b.localDayKey);
    return byDay != 0 ? byDay : a.id.compareTo(b.id);
  }

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
