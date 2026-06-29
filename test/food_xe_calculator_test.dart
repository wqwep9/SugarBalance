import 'package:flutter_test/flutter_test.dart';

import 'package:diabet_1/core/utils/food_xe_calculator.dart';

void main() {
  group('FoodXeCalculator', () {
    test('12 г углеводов = 1 ХЕ', () {
      expect(FoodXeCalculator.xeFromCarbs(12), closeTo(1.0, 0.001));
    });

    test('порция 150 г при 20 г/100г углеводов', () {
      final carbs = FoodXeCalculator.carbsInPortion(
        carbsPer100g: 20,
        grams: 150,
      );
      expect(carbs, closeTo(30, 0.001));
      expect(
        FoodXeCalculator.xeFromPortion(carbsPer100g: 20, grams: 150),
        closeTo(2.5, 0.001),
      );
    });

    test('сумма ХЕ нескольких продуктов', () {
      expect(FoodXeCalculator.totalXe([1.0, 2.5, 0.5]), closeTo(4.0, 0.001));
    });
  });
}
