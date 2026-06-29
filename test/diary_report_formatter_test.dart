import 'package:flutter_test/flutter_test.dart';

import 'package:diabet_1/core/utils/diary_report_formatter.dart';
import 'package:diabet_1/services/diary_report_export_service.dart';
import 'package:diabet_1/models/diary_entry.dart';
import 'package:diabet_1/models/user_profile.dart';
import 'package:diabet_1/services/diary_report_service.dart';
import 'package:diabet_1/services/statistics_service.dart';

void main() {
  final from = DateTime(2026, 5, 18);
  final to = DateTime(2026, 5, 20, 23, 59, 59);

  final entries = [
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

  test('отчёт включает расширенную статистику глюкозы', () {
    final report = DiaryReportService.build(
      entries: entries,
      from: from,
      to: to,
      user: user,
    );

    expect(report.glucoseStats, isNotNull);
    expect(report.glucoseStats!.measurementCount, 2);

    final text = DiaryReportFormatter.format(report);
    expect(text, contains('Статистика глюкозы'));
    expect(text, contains('В целевом диапазоне'));
    expect(text, contains('ХЕ в день'));
    expect(text, contains('Базальный инсулин'));
  });

  test('formatForExport добавляет заголовок документа', () {
    final report = DiaryReportService.build(
      entries: entries,
      from: from,
      to: to,
      user: user,
    );
    final text = DiaryReportFormatter.formatForExport(report);
    expect(text, startsWith('SugarBalance — отчёт по дневнику'));
    expect(text, contains('Сформирован:'));
  });

  test('имя файла отчёта содержит период', () {
    final report = DiaryReportService.build(
      entries: entries,
      from: from,
      to: to,
      user: user,
    );
    expect(
      DiaryReportExportService.buildFileName(report),
      'SugarBalance_otchet_18-05-2026_20-05-2026.txt',
    );
  });

  test('buildForDateRange совпадает с периодом 3 дня', () {
    final stats = StatisticsService.buildForDateRange(
      entries: entries,
      from: from,
      to: to,
      user: user,
    );
    expect(stats.periodDays, 3);
    expect(stats.measurementCount, 2);
  });
}
