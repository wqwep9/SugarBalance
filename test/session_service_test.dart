import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diabet_1/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionService', () {
    late SessionService session;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      session = SessionService();
    });

    test('сохраняет и читает id пользователя', () async {
      await session.saveUserId(42);
      expect(await session.readUserId(), 42);
    });

    test('clear удаляет сессию', () async {
      await session.saveUserId(7);
      await session.clear();
      expect(await session.readUserId(), isNull);
    });
  });
}
