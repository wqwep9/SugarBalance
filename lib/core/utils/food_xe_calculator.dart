/// Перевод углеводов в хлебные единицы (1 ХЕ = 12 г углеводов).
abstract final class FoodXeCalculator {
  FoodXeCalculator._();

  static const double carbsPerXe = 12.0;

  /// Углеводы в порции (г) по данным «на 100 г».
  static double carbsInPortion({
    required double carbsPer100g,
    required double grams,
  }) {
    if (grams <= 0) return 0;
    return carbsPer100g * grams / 100.0;
  }

  /// ХЕ из массы углеводов (г).
  static double xeFromCarbs(double carbsGrams) {
    if (carbsGrams <= 0) return 0;
    return carbsGrams / carbsPerXe;
  }

  /// ХЕ для порции продукта.
  static double xeFromPortion({
    required double carbsPer100g,
    required double grams,
  }) {
    return xeFromCarbs(
      carbsInPortion(carbsPer100g: carbsPer100g, grams: grams),
    );
  }

  /// Сумма ХЕ по списку выбранных продуктов.
  static double totalXe(Iterable<double> xeValues) {
    return xeValues.fold(0.0, (a, b) => a + b);
  }
}
