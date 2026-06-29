/// Продукт из Open Food Facts (результат поиска).
class FoodProductSearchHit {
  const FoodProductSearchHit({
    required this.code,
    required this.name,
    this.carbsPer100g,
  });

  final String code;
  final String name;

  /// Углеводы на 100 г продукта (г); null — данных нет в базе.
  final double? carbsPer100g;

  bool get hasCarbsData => carbsPer100g != null && carbsPer100g! >= 0;
}

/// Выбранный продукт с порцией (для расчёта ХЕ).
class FoodProductSelection {
  const FoodProductSelection({
    required this.name,
    required this.grams,
    required this.carbsPer100g,
    required this.carbsGrams,
    required this.xe,
  });

  final String name;
  final double grams;
  final double carbsPer100g;
  final double carbsGrams;
  final double xe;

  FoodProductSelection copyWith({double? grams, double? carbsGrams, double? xe}) {
    return FoodProductSelection(
      name: name,
      grams: grams ?? this.grams,
      carbsPer100g: carbsPer100g,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      xe: xe ?? this.xe,
    );
  }
}
