import 'package:shared_preferences/shared_preferences.dart';

/// Локальное хранение id вошедшего пользователя между запусками приложения.
class SessionService {
  static const _keyUserId = 'session_user_id';

  /// Сохранить id пользователя после входа или регистрации.
  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  /// Прочитать сохранённый id (null — сессии нет).
  Future<int?> readUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  /// Очистить сессию при выходе из аккаунта.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
  }
}
