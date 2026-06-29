/// Точка измерения глюкозы для графика.
class GlucoseChartPoint {
  const GlucoseChartPoint({
    required this.time,
    required this.valueMmol,
    required this.hoursFromStart,
  });

  final DateTime time;
  final double valueMmol;

  /// Позиция по оси X (часы от начала периода).
  final double hoursFromStart;
}

/// Сводная статистика глюкозы и дневника за период.
class GlucoseStatistics {
  const GlucoseStatistics({
    required this.from,
    required this.to,
    required this.periodDays,
    required this.chartPoints,
    required this.maxChartHours,
    required this.measurementCount,
    required this.avgGlucose,
    required this.inRangeCount,
    required this.belowRangeCount,
    required this.aboveRangeCount,
    required this.targetLow,
    required this.targetHigh,
    required this.avgXePerDay,
    required this.avgBolusInsulinPerDay,
    required this.avgBasalInsulinPerDay,
    required this.avgTotalInsulinPerDay,
  });

  final DateTime from;
  final DateTime to;
  final int periodDays;
  final List<GlucoseChartPoint> chartPoints;
  final double maxChartHours;
  final int measurementCount;
  final double? avgGlucose;
  final int inRangeCount;
  final int belowRangeCount;
  final int aboveRangeCount;
  final double targetLow;
  final double targetHigh;
  final double? avgXePerDay;
  final double? avgBolusInsulinPerDay;
  final double? avgBasalInsulinPerDay;
  final double? avgTotalInsulinPerDay;

  double get inRangePercent =>
      measurementCount == 0 ? 0 : inRangeCount / measurementCount * 100;

  double get belowRangePercent =>
      measurementCount == 0 ? 0 : belowRangeCount / measurementCount * 100;

  double get aboveRangePercent =>
      measurementCount == 0 ? 0 : aboveRangeCount / measurementCount * 100;

  bool get hasMeasurements => measurementCount > 0;
}
