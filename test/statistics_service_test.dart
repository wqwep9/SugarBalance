import 'package:flutter_test/flutter_test.dart';

import 'package:diabet_1/models/diary_entry.dart';
import 'package:diabet_1/models/user_profile.dart';
import 'package:diabet_1/services/statistics_service.dart';

void main() {
  final now = DateTime(2026, 5, 20, 14, 0);

  List<DiaryEntry> sampleEntries() => [
        DiaryEntry(
          userId: 1,
          createdAtMillis: DateTime(2026, 5, 18, 8, 0).millisecondsSinceEpoch,
          sugarMmolL: 5.5,
          foodXe: 2,
          shortInsulinUnits: 4,
          isAfterMeal: false,
        ),
        DiaryEntry(
          userId: 1,
          createdAtMillis: DateTime(2026, 5, 19, 12, 30).millisecondsSinceEpoch,
          sugarMmolL: 9.2,
          longInsulinUnits: 10,
          isAfterMeal: true,
        ),
        DiaryEntry(
          userId: 1,
          createdAtMillis: DateTime(2026, 5, 20, 9, 0).millisecondsSinceEpoch,
          sugarMmolL: 3.5,
          isAfterMeal: false,
        ),
      ];

  final user = UserProfile(
    id: 1,
    username: 'u',
    email: 'a@b.c',
    birthDate: DateTime(2000, 1, 1),
    diabetesType: 1,
    gender: 0,
    glucoseTargetLow: 4.0,
    glucoseTargetHigh: 8.0,
  );

  test('подсчёт измерений в целевом, выше и ниже диапазона', () {
    final stats = StatisticsService.build(
      entries: sampleEntries(),
      period: StatisticsPeriod.days7,
      user: user,
      now: now,
    );

    expect(stats.measurementCount, 3);
    expect(stats.inRangeCount, 1);
    expect(stats.aboveRangeCount, 1);
    expect(stats.belowRangeCount, 1);
    expect(stats.avgGlucose, closeTo(6.067, 0.01));
    expect(stats.chartPoints.length, 3);
  });

  test('целевой диапазон по умолчанию без профиля', () {
    final stats = StatisticsService.build(
      entries: sampleEntries(),
      period: StatisticsPeriod.day1,
      now: now,
    );
    expect(stats.targetLow, StatisticsService.defaultTargetLow);
    expect(stats.targetHigh, StatisticsService.defaultTargetHigh);
  });
}
