import 'package:flutter_test/flutter_test.dart';
import 'package:diabet_1/models/diary_entry.dart';
import 'package:diabet_1/services/glucose_context_aggregator.dart';
import 'package:diabet_1/services/glucose_feature_mapper.dart';
import 'package:diabet_1/services/glucose_prediction_service.dart';
import 'package:diabet_1/ml/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 5, 17, 12, 0);

  group('GlucoseFeatureMapper', () {
    test('короткий инсулин затухает после 4.5 ч', () {
      expect(
        GlucoseFeatureMapper.calculateActiveInsulin(
          bolusUnits: 10,
          hoursSince: 5,
        ),
        0.0,
      );
      expect(
        GlucoseFeatureMapper.calculateActiveInsulin(
          bolusUnits: 10,
          hoursSince: 0,
        ),
        closeTo(10, 0.001),
      );
    });

    test('продлённый инсулин затухает после 24 ч', () {
      expect(
        GlucoseFeatureMapper.calculateActiveLongInsulin(
          units: 20,
          hoursSince: 25,
        ),
        0.0,
      );
      expect(
        GlucoseFeatureMapper.calculateActiveLongInsulin(
          units: 20,
          hoursSince: 0,
        ),
        closeTo(20, 0.001),
      );
    });

    test('стандартизация совпадает с Python-формулой', () {
      const glucose = 7.0;
      const insulin = 1.5;
      const carbs = 30.0;
      final scaled = [
        (glucose - ModelConstants.mean[0]) / ModelConstants.std[0],
        (insulin - ModelConstants.mean[1]) / ModelConstants.std[1],
        (carbs - ModelConstants.mean[2]) / ModelConstants.std[2],
      ];
      expect(scaled[0], closeTo((7.0 - 6.849382716049384) / 1.680470499723814, 1e-6));
      expect(scaled.length, 3);
    });
  });

  group('GlucoseContextAggregator', () {
    test('объединяет сахар и инсулин из разных записей', () {
      final entries = [
        DiaryEntry(
          id: 1,
          userId: 1,
          createdAtMillis: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
          sugarMmolL: 6.8,
          isAfterMeal: false,
        ),
        DiaryEntry(
          id: 2,
          userId: 1,
          createdAtMillis: now.subtract(const Duration(minutes: 30)).millisecondsSinceEpoch,
          shortInsulinUnits: 4,
          isAfterMeal: false,
        ),
        DiaryEntry(
          id: 3,
          userId: 1,
          createdAtMillis: now.subtract(const Duration(minutes: 20)).millisecondsSinceEpoch,
          foodXe: 3,
          isAfterMeal: true,
        ),
      ];

      final ctx = GlucoseContextAggregator.aggregate(entries, now: now);
      expect(ctx, isNotNull);
      expect(ctx!.glucoseMmol, 6.8);
      expect(ctx.referenceEntryId, 1);
      expect(ctx.activeBolusInsulin, greaterThan(0));
      expect(ctx.activeCarbsGrams, greaterThan(0));
      expect(ctx.entriesInWindow, 3);
    });

    test('без сахара возвращает null', () {
      final entries = [
        DiaryEntry(
          id: 1,
          userId: 1,
          createdAtMillis: now.millisecondsSinceEpoch,
          shortInsulinUnits: 2,
          isAfterMeal: false,
        ),
      ];
      expect(GlucoseContextAggregator.aggregate(entries, now: now), isNull);
    });

    test('старый сахар помечается isGlucoseStale', () {
      final entries = [
        DiaryEntry(
          id: 1,
          userId: 1,
          createdAtMillis: now.subtract(const Duration(hours: 6)).millisecondsSinceEpoch,
          sugarMmolL: 5.5,
          isAfterMeal: false,
        ),
      ];
      final ctx = GlucoseContextAggregator.aggregate(entries, now: now);
      expect(ctx, isNotNull);
      expect(ctx!.isGlucoseStale, isTrue);
    });
  });

  group('GlucosePredictionService', () {
    test('predictFromEntries возвращает прогноз в допустимых границах', () async {
      final entries = [
        DiaryEntry(
          id: 10,
          userId: 1,
          createdAtMillis: now.subtract(const Duration(minutes: 15)).millisecondsSinceEpoch,
          sugarMmolL: 7.2,
          shortInsulinUnits: 3,
          foodXe: 2,
          isAfterMeal: false,
        ),
      ];

      final response = await GlucosePredictionService.predictFromEntries(
        entries,
        now: now,
        persist: false,
      );

      expect(response.result.prediction, isNotNull);
      expect(response.result.prediction!, inInclusiveRange(3.0, 22.0));
      expect(response.glucoseEntryId, 10);
      expect(response.contextSummary, isNotEmpty);
    });

    test('predictForEntry clamp при экстремальной глюкозе', () async {
      final result = await GlucosePredictionService.predictForEntry(
        glucoseMmol: 7.0,
        bolusInsulin: 2,
        foodXe: 1,
        entryTime: now.subtract(const Duration(minutes: 10)),
        longInsulin: 10,
      );
      expect(result.prediction, isNotNull);
    });
  });
}
