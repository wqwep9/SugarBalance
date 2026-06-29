/// Форматирование подписей на экране статистики.
abstract final class StatisticsFormatters {
  StatisticsFormatters._();

  static const _months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'май',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];

  static String dateRangeRu(DateTime from, DateTime to) {
    if (from.year == to.year && from.month == to.month && from.day == to.day) {
      return '${from.day} ${_months[from.month - 1]} ${from.year}';
    }
    return '${from.day} ${_months[from.month - 1]} — '
        '${to.day} ${_months[to.month - 1]}';
  }

  static String glucose(double v) =>
      v.toStringAsFixed(1).replaceAll('.', ',');

  static String percent(double p) => '${p.round()}%';

  static String chartBottomLabel(DateTime time, {required bool singleDay}) {
    if (singleDay) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    final d = time.day.toString().padLeft(2, '0');
    final m = time.month.toString().padLeft(2, '0');
    return '$d.$m';
  }
}
