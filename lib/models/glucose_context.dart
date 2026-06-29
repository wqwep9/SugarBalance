/// Сводный контекст для прогноза: агрегат записей дневника за окно времени.
class GlucoseContext {
  const GlucoseContext({
    required this.glucoseMmol,
    required this.glucoseMeasuredAt,
    required this.referenceEntryId,
    required this.activeBolusInsulin,
    required this.activeBasalInsulin,
    required this.activeCarbsGrams,
    required this.entriesInWindow,
    required this.isGlucoseStale,
  });

  /// Последнее измерение глюкозы (ммоль/л).
  final double glucoseMmol;

  /// Время измерения глюкозы.
  final DateTime glucoseMeasuredAt;

  /// id записи с глюкозой — для сохранения прогноза в БД.
  final int referenceEntryId;

  /// Суммарный активный короткий (болюсный) инсулин за окно.
  final double activeBolusInsulin;

  /// Суммарный активный продлённый (базальный) инсулин за окно.
  final double activeBasalInsulin;

  /// Суммарные активные углеводы (г) за окно.
  final double activeCarbsGrams;

  /// Сколько записей попало в окно агрегации.
  final int entriesInWindow;

  /// Глюкоза старше окна агрегации (инсулин/еда учтены, сахар — из более ранней записи).
  final bool isGlucoseStale;

  /// Общий активный инсулин для признака модели.
  double get totalActiveInsulin => activeBolusInsulin + activeBasalInsulin;
}
