/// Форматирование дат/чисел для UI.
abstract final class Formatters {
  Formatters._();

  static String ddMMyyyy(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  static String number1(double v) => v.toStringAsFixed(1);
  static String number2(double v) => v.toStringAsFixed(2);
}
