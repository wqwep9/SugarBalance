import 'package:flutter/foundation.dart';

import '../ml/constants.dart';
import '../ml/glucose_model.dart';
import '../models/diary_entry.dart';
import '../models/prediction_result.dart';
import 'database_service.dart';
import 'glucose_context_aggregator.dart';
import 'glucose_feature_mapper.dart';

/// Оффлайн-прогноз глюкозы на 30–60 мин по записям дневника.
class GlucosePredictionService {
  GlucosePredictionService._();
  static final GlucosePredictionService instance = GlucosePredictionService._();

  final DatabaseService _dbService = DatabaseService.instance;

  /// Прогноз по списку записей дневника (агрегация за 4 ч).
  static Future<GlucosePredictionResponse> predictFromEntries(
    List<DiaryEntry> entries, {
    DateTime? now,
    bool persist = true,
  }) async {
    final ctx = GlucoseContextAggregator.aggregate(entries, now: now);
    if (ctx == null) {
      return const GlucosePredictionResponse(
        result: PredictionResult(
          prediction: null,
          confidence: 0.0,
          status: PredictionStatus.warning,
          message: 'Нет данных для прогноза. Добавьте измерение сахара в дневнике.',
        ),
      );
    }

    try {
      final features = GlucoseFeatureMapper.prepareFeaturesFromContext(ctx);
      var result = await compute(_runModelSafely, {
        'features': features,
        'is_stale_glucose': ctx.isGlucoseStale,
      });

      if (ctx.isGlucoseStale) {
        const staleMsg =
            'Сахар измерен более 4 ч назад. Прогноз ориентировочный.';
        final combined = result.message == null
            ? staleMsg
            : '$staleMsg ${result.message}';
        result = PredictionResult(
          prediction: result.prediction,
          confidence: result.confidence,
          status: result.status == PredictionStatus.ok
              ? PredictionStatus.warning
              : result.status,
          message: combined,
        );
      }

      final summary = GlucoseContextAggregator.summary(ctx);

      if (persist && result.prediction != null) {
        await instance.savePrediction(
          entryId: ctx.referenceEntryId,
          result: result,
        );
      }

      return GlucosePredictionResponse(
        result: result,
        glucoseEntryId: ctx.referenceEntryId,
        contextSummary: summary,
      );
    } catch (_) {
      return const GlucosePredictionResponse(
        result: PredictionResult(
          prediction: null,
          confidence: 0.0,
          status: PredictionStatus.error,
          message: 'Ошибка вычисления прогноза',
        ),
      );
    }
  }

  /// Прогноз для одной записи (без агрегации).
  static Future<PredictionResult> predictForEntry({
    required double glucoseMmol,
    required double? bolusInsulin,
    required double? foodXe,
    required DateTime entryTime,
    double? longInsulin,
  }) async {
    try {
      final features = GlucoseFeatureMapper.prepareFeatures(
        glucoseMmol: glucoseMmol,
        bolusInsulin: bolusInsulin,
        foodXe: foodXe,
        entryTime: entryTime,
        longInsulin: longInsulin,
      );

      return await compute(_runModelSafely, {
        'features': features,
        'is_stale_glucose': false,
      });
    } catch (_) {
      return const PredictionResult(
        prediction: null,
        confidence: 0.0,
        status: PredictionStatus.error,
        message: 'Ошибка вычисления прогноза',
      );
    }
  }

  /// Синоним для требований ТЗ.
  static Future<PredictionResult> predict({
    required double glucoseMmol,
    required double? bolusInsulin,
    required double? foodXe,
    required DateTime entryTime,
    double? longInsulin,
  }) =>
      predictForEntry(
        glucoseMmol: glucoseMmol,
        bolusInsulin: bolusInsulin,
        foodXe: foodXe,
        entryTime: entryTime,
        longInsulin: longInsulin,
      );

  /// Выполняется в изоляте — только примитивные типы.
  static PredictionResult _runModelSafely(Map<String, dynamic> params) {
    final features = List<double>.from(params['features'] as List);

    if (features[0] < ModelConstants.minGlucose ||
        features[0] > ModelConstants.maxGlucose) {
      return const PredictionResult(
        prediction: null,
        confidence: 0.0,
        status: PredictionStatus.warning,
        message: 'Некорректный уровень глюкозы',
      );
    }

    final scaled = [
      (features[0] - ModelConstants.mean[0]) / ModelConstants.std[0],
      (features[1] - ModelConstants.mean[1]) / ModelConstants.std[1],
      (features[2] - ModelConstants.mean[2]) / ModelConstants.std[2],
    ];

    var prediction = score(scaled);
    prediction = prediction.clamp(3.0, 22.0);

    final meanAbsDist = scaled.fold(0.0, (sum, v) => sum + v.abs()) / 3;
    var confidence = (1.0 - meanAbsDist / 2.0).clamp(0.0, 1.0);

    final isStale = params['is_stale_glucose'] == true;
    if (isStale) {
      confidence = (confidence * 0.85).clamp(0.0, 1.0);
    }

    PredictionStatus status;
    String? message;
    if (confidence < ModelConstants.confidenceThreshold) {
      status = PredictionStatus.warning;
      message =
          'Предварительный прогноз с низкой уверенностью. Измерьте глюкозу вручную и следуйте рекомендациям врача.';
    } else {
      status = PredictionStatus.ok;
    }

    return PredictionResult(
      prediction: double.parse(prediction.toStringAsFixed(1)),
      confidence: double.parse(confidence.toStringAsFixed(2)),
      status: status,
      message: message,
    );
  }

  /// Сохранение прогноза в запись дневника с глюкозой.
  Future<void> savePrediction({
    required int entryId,
    required PredictionResult result,
  }) async {
    if (result.prediction == null) return;

    final db = await _dbService.database;
    await db.update(
      'diary_entries',
      {
        'predicted_glucose_60min': result.prediction,
        'prediction_confidence': result.confidence,
        'prediction_status': result.status.name,
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// История прогнозов для графиков.
  Future<List<Map<String, dynamic>>> getPredictionHistory({
    required int userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _dbService.database;
    return db.rawQuery(
      '''
      SELECT 
        created_at, sugar_mmol_l, predicted_glucose_60min,
        prediction_confidence, prediction_status
      FROM diary_entries
      WHERE user_id = ? 
        AND created_at >= ? 
        AND created_at <= ?
        AND predicted_glucose_60min IS NOT NULL
      ORDER BY created_at ASC
    ''',
      [userId, from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
  }
}
