/// Типизированный результат предсказания глюкозы.
/// Используется как модель-DTO между ML-сервисом и UI.
enum PredictionStatus { ok, warning, error }

class PredictionResult {
  final double? prediction;
  final double confidence;
  final PredictionStatus status;
  final String? message;

  /// Успешно ли предсказание (без предупреждения).
  bool get isSuccess => status == PredictionStatus.ok && prediction != null;

  /// Требуется ли ручная проверка (например низкая уверенность).
  bool get needsManualCheck => status == PredictionStatus.warning;

  const PredictionResult({
    this.prediction,
    required this.confidence,
    required this.status,
    this.message,
  });
}

/// Результат прогноза вместе с метаданными агрегации.
class GlucosePredictionResponse {
  const GlucosePredictionResponse({
    required this.result,
    this.glucoseEntryId,
    this.contextSummary,
  });

  final PredictionResult result;
  final int? glucoseEntryId;
  final String? contextSummary;
}
