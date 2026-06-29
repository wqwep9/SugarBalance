import 'glucose_statistics.dart';

/// Краткий отчёт по дневнику за период.
class DiaryReport {
  const DiaryReport({
    required this.entriesCount,
    this.avgSugar,
    this.avgFoodXe,
    this.sumShortInsulin,
    this.sumLongInsulin,
    required this.from,
    required this.to,
    this.glucoseStats,
  });

  final int entriesCount;
  final double? avgSugar;
  final double? avgFoodXe;
  final double? sumShortInsulin;
  final double? sumLongInsulin;
  final DateTime from;
  final DateTime to;

  /// Расширенная статистика (как на экране «Статистика»).
  final GlucoseStatistics? glucoseStats;
}
