import '../models/diary_entry.dart';
import '../models/glucose_statistics.dart';
import '../models/user_profile.dart';

/// Период отображения статистики.
enum StatisticsPeriod {
  day1(1, '1 день'),
  days7(7, '7 дней'),
  days30(30, '30 дней'),
  days90(90, '90 дней');

  const StatisticsPeriod(this.days, this.label);
  final int days;
  final String label;
}

/// Расчёт статистики по записям дневника и целевому диапазону из профиля.
abstract final class StatisticsService {
  StatisticsService._();

  static const double defaultTargetLow = 4.0;
  static const double defaultTargetHigh = 8.5;

  static GlucoseStatistics build({
    required List<DiaryEntry> entries,
    required StatisticsPeriod period,
    UserProfile? user,
    DateTime? now,
  }) {
    final end = _endOfDay(now ?? DateTime.now());
    final start = DateTime(
      end.year,
      end.month,
      end.day,
    ).subtract(Duration(days: period.days - 1));
    return buildForDateRange(
      entries: entries,
      from: start,
      to: end,
      user: user,
    );
  }

  /// Статистика за произвольный календарный период (отчёт в профиле).
  static GlucoseStatistics buildForDateRange({
    required List<DiaryEntry> entries,
    required DateTime from,
    required DateTime to,
    UserProfile? user,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    final end = _endOfDay(to);
    final periodDays = end.difference(start).inDays + 1;

    final inPeriod = entries.where((e) {
      final t = e.createdAt;
      return !t.isBefore(start) && !t.isAfter(end);
    }).toList();

    final targetLow = user?.glucoseTargetLow ?? defaultTargetLow;
    final targetHigh = user?.glucoseTargetHigh ?? defaultTargetHigh;

    final glucoseEntries = inPeriod
        .where((e) => e.sugarMmolL != null)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final maxHours = end.difference(start).inMinutes / 60.0 + 1;

    final chartPoints = glucoseEntries.map((e) {
      final hours = e.createdAt.difference(start).inMinutes / 60.0;
      return GlucoseChartPoint(
        time: e.createdAt,
        valueMmol: e.sugarMmolL!,
        hoursFromStart: hours,
      );
    }).toList();

    var inRange = 0;
    var below = 0;
    var above = 0;
    double? avgGlucose;

    if (glucoseEntries.isNotEmpty) {
      var sum = 0.0;
      for (final e in glucoseEntries) {
        final v = e.sugarMmolL!;
        sum += v;
        if (v < targetLow) {
          below++;
        } else if (v > targetHigh) {
          above++;
        } else {
          inRange++;
        }
      }
      avgGlucose = sum / glucoseEntries.length;
    }

    return GlucoseStatistics(
      from: start,
      to: end,
      periodDays: periodDays,
      chartPoints: chartPoints,
      maxChartHours: maxHours < 1 ? 24 : maxHours,
      measurementCount: glucoseEntries.length,
      avgGlucose: avgGlucose,
      inRangeCount: inRange,
      belowRangeCount: below,
      aboveRangeCount: above,
      targetLow: targetLow,
      targetHigh: targetHigh,
      avgXePerDay: _avgPerDay(
        inPeriod,
        periodDays,
        (e) => e.foodXe,
      ),
      avgBolusInsulinPerDay: _avgPerDay(
        inPeriod,
        periodDays,
        (e) => e.shortInsulinUnits,
      ),
      avgBasalInsulinPerDay: _avgPerDay(
        inPeriod,
        periodDays,
        (e) => e.longInsulinUnits,
      ),
      avgTotalInsulinPerDay: _avgTotalInsulinPerDay(inPeriod, periodDays),
    );
  }

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static double? _avgPerDay(
    List<DiaryEntry> entries,
    int days,
    double? Function(DiaryEntry) pick,
  ) {
    final values = entries.map(pick).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.fold<double>(0, (a, b) => a + b) / days;
  }

  static double? _avgTotalInsulinPerDay(List<DiaryEntry> entries, int days) {
    var sum = 0.0;
    var has = false;
    for (final e in entries) {
      final s = e.shortInsulinUnits ?? 0;
      final l = e.longInsulinUnits ?? 0;
      if (s > 0 || l > 0) {
        sum += s + l;
        has = true;
      }
    }
    if (!has) return null;
    return sum / days;
  }
}
