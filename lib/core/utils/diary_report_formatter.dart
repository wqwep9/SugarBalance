import '../../models/diary_report.dart';
import 'formatters.dart';
import 'statistics_formatters.dart';

/// Текст отчёта для диалога в профиле и экспорта в файл.
abstract final class DiaryReportFormatter {
  DiaryReportFormatter._();

  /// Полный текст файла с заголовком и датой формирования.
  static String formatForExport(DiaryReport report) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final buf = StringBuffer()
      ..writeln('SugarBalance — отчёт по дневнику')
      ..writeln('Сформирован: ${Formatters.ddMMyyyy(now)} $hh:$mm')
      ..writeln()
      ..write(format(report));
    return buf.toString();
  }

  static String format(DiaryReport report) {
    final buf = StringBuffer()
      ..writeln(
        'Период: ${Formatters.ddMMyyyy(report.from)} — '
        '${Formatters.ddMMyyyy(report.to)}',
      )
      ..writeln('Записей в дневнике: ${report.entriesCount}')
      ..writeln(
        'Средний сахар: ${report.avgSugar == null ? '—' : Formatters.number1(report.avgSugar!)} ммоль/л',
      )
      ..writeln(
        'Средняя еда (на запись): ${report.avgFoodXe == null ? '—' : Formatters.number1(report.avgFoodXe!)} ХЕ',
      )
      ..writeln(
        'Короткий инсулин (сумма): ${report.sumShortInsulin == null ? '—' : Formatters.number1(report.sumShortInsulin!)} ед.',
      )
      ..writeln(
        'Продлённый инсулин (сумма): ${report.sumLongInsulin == null ? '—' : Formatters.number1(report.sumLongInsulin!)} ед.',
      );

    final stats = report.glucoseStats;
    if (stats == null) return buf.toString();

    buf
      ..writeln()
      ..writeln('— Статистика глюкозы —')
      ..writeln('Измерений глюкозы: ${stats.measurementCount}')
      ..writeln(
        'Средний уровень глюкозы: ${stats.avgGlucose == null ? '—' : '${StatisticsFormatters.glucose(stats.avgGlucose!)} ммоль/л'}',
      )
      ..writeln(
        'Целевой диапазон: ${StatisticsFormatters.glucose(stats.targetLow)}–'
        '${StatisticsFormatters.glucose(stats.targetHigh)} ммоль/л',
      )
      ..writeln(
        'В целевом диапазоне: ${stats.inRangeCount} '
        '(${StatisticsFormatters.percent(stats.inRangePercent)})',
      )
      ..writeln(
        'Выше диапазона: ${stats.aboveRangeCount} '
        '(${StatisticsFormatters.percent(stats.aboveRangePercent)})',
      )
      ..writeln(
        'Ниже диапазона: ${stats.belowRangeCount} '
        '(${StatisticsFormatters.percent(stats.belowRangePercent)})',
      )
      ..writeln()
      ..writeln('— Питание и инсулин (в среднем за день) —')
      ..writeln(
        'ХЕ в день: ${stats.avgXePerDay == null ? '—' : '${StatisticsFormatters.glucose(stats.avgXePerDay!)} ХЕ'}',
      )
      ..writeln(
        'Общий инсулин: ${stats.avgTotalInsulinPerDay == null ? '—' : '${StatisticsFormatters.glucose(stats.avgTotalInsulinPerDay!)} ед.'}',
      )
      ..writeln(
        'Болюсный инсулин: ${stats.avgBolusInsulinPerDay == null ? '—' : '${StatisticsFormatters.glucose(stats.avgBolusInsulinPerDay!)} ед.'}',
      )
      ..writeln(
        'Базальный инсулин: ${stats.avgBasalInsulinPerDay == null ? '—' : '${StatisticsFormatters.glucose(stats.avgBasalInsulinPerDay!)} ед.'}',
      );

    return buf.toString();
  }
}
