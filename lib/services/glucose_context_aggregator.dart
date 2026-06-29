import '../models/diary_entry.dart';
import '../models/glucose_context.dart';
import 'glucose_feature_mapper.dart';

/// Сбор признаков из нескольких записей дневника за последние часы.
class GlucoseContextAggregator {
  GlucoseContextAggregator._();

  /// Окно агрегации инсулина и еды (часы).
  static const double windowHours = 4.0;

  /// Строит контекст из списка записей пользователя (любой порядок).
  static GlucoseContext? aggregate(
    List<DiaryEntry> entries, {
    DateTime? now,
  }) {
    if (entries.isEmpty) return null;

    final referenceTime = now ?? DateTime.now();
    final windowStart = referenceTime.subtract(
      Duration(minutes: (windowHours * 60).round()),
    );

    final inWindow = entries.where((e) {
      final t = e.createdAt;
      return !t.isBefore(windowStart) && !t.isAfter(referenceTime);
    }).toList();

    final glucoseEntry = _latestGlucoseEntry(inWindow) ??
        _latestGlucoseEntry(entries);
    if (glucoseEntry?.sugarMmolL == null || glucoseEntry!.id == null) {
      return null;
    }

    var bolusActive = 0.0;
    var basalActive = 0.0;
    var carbsActive = 0.0;

    for (final e in inWindow) {
      final hoursSince =
          referenceTime.difference(e.createdAt).inMinutes / 60.0;

      final short = e.shortInsulinUnits;
      if (short != null && short > 0) {
        bolusActive += GlucoseFeatureMapper.calculateActiveInsulin(
          bolusUnits: short,
          hoursSince: hoursSince,
        );
      }

      final long = e.longInsulinUnits;
      if (long != null && long > 0) {
        basalActive += GlucoseFeatureMapper.calculateActiveLongInsulin(
          units: long,
          hoursSince: hoursSince,
        );
      }

      final food = e.foodXe;
      if (food != null && food > 0) {
        carbsActive += GlucoseFeatureMapper.calculateActiveCarbs(
          carbsGrams: GlucoseFeatureMapper.xeToGrams(food),
          hoursSince: hoursSince,
        );
      }
    }

    final isStale = glucoseEntry.createdAt.isBefore(windowStart);

    return GlucoseContext(
      glucoseMmol: glucoseEntry.sugarMmolL!,
      glucoseMeasuredAt: glucoseEntry.createdAt,
      referenceEntryId: glucoseEntry.id!,
      activeBolusInsulin: bolusActive,
      activeBasalInsulin: basalActive,
      activeCarbsGrams: carbsActive,
      entriesInWindow: inWindow.length,
      isGlucoseStale: isStale,
    );
  }

  static DiaryEntry? _latestGlucoseEntry(List<DiaryEntry> source) {
    DiaryEntry? best;
    for (final e in source) {
      if (e.sugarMmolL == null) continue;
      if (best == null || e.createdAt.isAfter(best.createdAt)) {
        best = e;
      }
    }
    return best;
  }

  /// Краткое описание для UI.
  static String summary(GlucoseContext ctx) {
    final parts = <String>[
      'Записей за ${windowHours.toStringAsFixed(0)} ч: ${ctx.entriesInWindow}',
    ];
    if (ctx.activeBolusInsulin > 0) {
      parts.add(
        'болюс ~${ctx.activeBolusInsulin.toStringAsFixed(1)} Ед',
      );
    }
    if (ctx.activeBasalInsulin > 0) {
      parts.add(
        'базальный ~${ctx.activeBasalInsulin.toStringAsFixed(1)} Ед',
      );
    }
    if (ctx.activeCarbsGrams > 0) {
      parts.add('углеводы ~${ctx.activeCarbsGrams.toStringAsFixed(0)} г');
    }
    return parts.join(' · ');
  }
}
