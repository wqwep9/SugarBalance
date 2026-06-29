import '../models/diary_entry.dart';
import '../models/diary_report.dart';
import '../models/user_profile.dart';
import 'statistics_service.dart';

/// Расчёт отчёта по списку записей дневника (без БД).
abstract final class DiaryReportService {
  DiaryReportService._();

  static DiaryReport build({
    required List<DiaryEntry> entries,
    required DateTime from,
    required DateTime to,
    UserProfile? user,
  }) {
    double? avgSugar;
    double? avgFood;
    double? sumShort;
    double? sumLong;

    final sugars = entries.where((e) => e.sugarMmolL != null).toList();
    if (sugars.isNotEmpty) {
      final sum = sugars.fold<double>(0, (a, b) => a + b.sugarMmolL!);
      avgSugar = sum / sugars.length;
    }

    final foods = entries.where((e) => e.foodXe != null).toList();
    if (foods.isNotEmpty) {
      final sum = foods.fold<double>(0, (a, b) => a + b.foodXe!);
      avgFood = sum / foods.length;
    }

    final shortIns = entries.where((e) => e.shortInsulinUnits != null).toList();
    if (shortIns.isNotEmpty) {
      sumShort = shortIns.fold<double>(0, (a, b) => a + b.shortInsulinUnits!);
    }

    final longIns = entries.where((e) => e.longInsulinUnits != null).toList();
    if (longIns.isNotEmpty) {
      sumLong = longIns.fold<double>(0, (a, b) => a + b.longInsulinUnits!);
    }

    return DiaryReport(
      entriesCount: entries.length,
      avgSugar: avgSugar,
      avgFoodXe: avgFood,
      sumShortInsulin: sumShort,
      sumLongInsulin: sumLong,
      from: from,
      to: to,
      glucoseStats: StatisticsService.buildForDateRange(
        entries: entries,
        from: from,
        to: to,
        user: user,
      ),
    );
  }
}
