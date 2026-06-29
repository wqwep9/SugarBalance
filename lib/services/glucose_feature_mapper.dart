import 'dart:math';

import '../models/glucose_context.dart';

/// Преобразование записей из БД в признаки для ML-модели.
class GlucoseFeatureMapper {
  /// Конвертация ХЕ → граммы углеводов (стандарт: 1 ХЕ = 12 г)
  static double xeToGrams(double xe) => xe * 12.0;

  /// Активный короткий (болюсный) инсулин — кинетика ~4.5 ч.
  static double calculateActiveInsulin({
    required double bolusUnits,
    required double hoursSince,
  }) {
    if (hoursSince < 0) return 0.0;
    if (hoursSince > 4.5) return 0.0;
    return bolusUnits * exp(-0.5 * hoursSince);
  }

  /// Активный продлённый (базальный) инсулин — медленное затухание ~24 ч.
  static double calculateActiveLongInsulin({
    required double units,
    required double hoursSince,
  }) {
    if (hoursSince < 0) return 0.0;
    if (hoursSince > 24.0) return 0.0;
    return units * exp(-0.05 * hoursSince);
  }

  /// Активные углеводы (кинетика усвоения ~3.5 ч).
  static double calculateActiveCarbs({
    required double carbsGrams,
    required double hoursSince,
  }) {
    if (hoursSince < 0) return 0.0;
    if (hoursSince > 3.5) return carbsGrams;
    return carbsGrams * (1 - exp(-0.25 * hoursSince));
  }

  /// Признаки из агрегированного контекста (порядок как при обучении).
  static List<double> prepareFeaturesFromContext(GlucoseContext ctx) {
    return [
      ctx.glucoseMmol,
      ctx.totalActiveInsulin,
      ctx.activeCarbsGrams,
    ];
  }

  /// Подготовка признаков из одной записи (обратная совместимость).
  static List<double> prepareFeatures({
    required double glucoseMmol,
    required double? bolusInsulin,
    required double? foodXe,
    required DateTime entryTime,
    double? longInsulin,
    DateTime? now,
  }) {
    final referenceTime = now ?? DateTime.now();
    final hoursSince =
        referenceTime.difference(entryTime).inMinutes / 60.0;

    final insulinActive = calculateActiveInsulin(
      bolusUnits: bolusInsulin ?? 0.0,
      hoursSince: hoursSince,
    ) +
        calculateActiveLongInsulin(
          units: longInsulin ?? 0.0,
          hoursSince: hoursSince,
        );

    final carbsGrams = foodXe != null ? xeToGrams(foodXe) : 0.0;
    final carbsActive = calculateActiveCarbs(
      carbsGrams: carbsGrams,
      hoursSince: hoursSince,
    );

    return [glucoseMmol, insulinActive, carbsActive];
  }
}
