import 'package:flutter/foundation.dart';

import '../core/utils/auth_validators.dart';
import '../models/user_profile.dart';
import '../repositories/user_repository.dart';
import '../services/password_hasher.dart';
import '../services/session_service.dart';

/// Состояние авторизации и операции входа / регистрации с записью в SQLite.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository, this._session);

  final UserRepository _repository;
  final SessionService _session;

  bool _busy = false;
  String? _error;
  UserProfile? _currentUser;

  bool get isBusy => _busy;
  String? get errorMessage => _error;

  /// Текущий пользователь после успешного входа или регистрации (без хеша пароля).
  UserProfile? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  /// Восстановление сессии при старте приложения.
  Future<void> restoreSession() async {
    final userId = await _session.readUserId();
    if (userId == null) return;

    try {
      final user = await _repository.findById(userId);
      if (user != null) {
        _currentUser = user.stripSecret();
      } else {
        await _session.clear();
      }
    } catch (e) {
      debugPrint('AuthProvider.restoreSession: $e');
      await _session.clear();
    }
    notifyListeners();
  }

  /// Выход из аккаунта: очистка памяти и сохранённой сессии.
  Future<void> signOut() async {
    _currentUser = null;
    _error = null;
    await _session.clear();
    notifyListeners();
  }

  /// Обновить доп. поля профиля в памяти (после сохранения в БД).
  void setCurrentUser(UserProfile profile) {
    _currentUser = profile.stripSecret();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _persistSession(UserProfile user) async {
    final id = user.id;
    if (id == null) return;
    await _session.saveUserId(id);
  }

  /// Вход: валидация полей, проверка БД.
  Future<bool> signIn(String email, String password) async {
    _error = null;
    final emailErr = AuthValidators.email(email);
    final passErr = AuthValidators.passwordLogin(password);
    if (emailErr != null || passErr != null) {
      _error = emailErr ?? passErr;
      notifyListeners();
      return false;
    }

    _busy = true;
    notifyListeners();
    try {
      final user = await _repository.verifyCredentials(email, password);
      if (user == null) {
        _error = 'Неверная почта или пароль';
        return false;
      }
      _currentUser = user.stripSecret();
      await _persistSession(user);
      return true;
    } on UserRepositoryException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Ошибка базы данных. Попробуйте ещё раз.';
      debugPrint('AuthProvider.signIn: $e');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Регистрация: валидация, хеш пароля, вставка в SQLite.
  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
    required DateTime birthDate,
    required int diabetesType,
    required int gender,
    double? carbsXe,
    double? hypoglycemia,
  }) async {
    _error = null;
    _busy = true;
    notifyListeners();
    try {
      final hash = PasswordHasher.hash(email, password);
      final profile = UserProfile(
        username: username.trim(),
        email: email.trim(),
        passwordHash: hash,
        birthDate: birthDate,
        diabetesType: diabetesType,
        gender: gender,
        carbsXe: carbsXe,
        hypoglycemia: hypoglycemia,
      );
      final saved = await _repository.insertUser(profile);
      _currentUser = saved.stripSecret();
      await _persistSession(saved);
      return true;
    } on UserRepositoryException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Ошибка базы данных. Попробуйте ещё раз.';
      debugPrint('AuthProvider.signUp: $e');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Валидация всех полей регистрации без обращения к БД.
  String? validateRegistrationFields({
    required String username,
    required String email,
    required String password,
    required String birthText,
    required String carbsRaw,
    required String hypoRaw,
  }) {
    return AuthValidators.username(username) ??
        AuthValidators.email(email) ??
        AuthValidators.passwordRegister(password) ??
        AuthValidators.birthDateRequired(birthText) ??
        AuthValidators.optionalNonNegativeNumber('Углеводы в ХЕ', carbsRaw) ??
        AuthValidators.optionalNonNegativeNumber('Гипогликемия', hypoRaw);
  }
}
