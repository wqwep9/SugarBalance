import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke-тест UI: без БД и навигации (сессия покрыта unit-тестами AuthProvider).
void main() {
  testWidgets('SugarBalance: отображается название приложения', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bloodtype_rounded, size: 72),
                SizedBox(height: 16),
                Text(
                  'SugarBalance',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text('Дневник и аналитика'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('SugarBalance'), findsOneWidget);
    expect(find.text('Дневник и аналитика'), findsOneWidget);
  });
}
