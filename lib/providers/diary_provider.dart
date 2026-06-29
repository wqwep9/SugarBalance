import 'package:flutter/foundation.dart';

import '../models/diary_entry.dart';
import 'auth_provider.dart';
import '../repositories/diary_repository.dart';

/// Состояние дневника: список записей и сохранение новых данных.
class DiaryProvider extends ChangeNotifier {
  DiaryProvider(this._repository, this._authProvider);

  final DiaryRepository _repository;
  final AuthProvider _authProvider;

  final List<DiaryEntry> _entries = <DiaryEntry>[];
  bool _loading = false;
  bool _saving = false;
  String? _error;
  bool _initialized = false;

  List<DiaryEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  String? get errorMessage => _error;

  int? get _currentUserId => _authProvider.currentUser?.id;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Сброс кэша дневника при выходе из аккаунта.
  void reset() {
    _entries.clear();
    _initialized = false;
    _error = null;
    notifyListeners();
  }

  /// Первичная загрузка; вызывается один раз при открытии экрана.
  Future<void> loadEntriesIfNeeded() async {
    if (_initialized) return;
    _initialized = true;
    await loadEntries();
  }

  /// Обновляет список записей из SQLite.
  Future<void> loadEntries() async {
    _error = null;
    final userId = _currentUserId;
    if (userId == null) {
      _entries.clear();
      _error = 'Сначала выполните вход';
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final loaded = await _repository.listByUser(userId);
      _entries
        ..clear()
        ..addAll(loaded);
    } on DiaryRepositoryException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Ошибка при чтении дневника';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Валидация и сохранение записи дневника.
  Future<bool> saveEntry({
    required String sugarRaw,
    required String foodRaw,
    required String? foodPhotoPath,
    required String shortInsulinRaw,
    required String longInsulinRaw,
    required String commentRaw,
    required bool isAfterMeal,
  }) async {
    _error = null;
    final userId = _currentUserId;
    if (userId == null) {
      _error = 'Пользователь не авторизован';
      notifyListeners();
      return false;
    }

    final sugar = _parseOptionalNumber(sugarRaw);
    final food = _parseOptionalNumber(foodRaw);
    final shortInsulin = _parseOptionalNumber(shortInsulinRaw);
    final longInsulin = _parseOptionalNumber(longInsulinRaw);
    final comment = commentRaw.trim().isEmpty ? null : commentRaw.trim();

    if (sugarRaw.trim().isNotEmpty && sugar == null) {
      _error = 'Сахар: введите корректное число';
      notifyListeners();
      return false;
    }
    if (foodRaw.trim().isNotEmpty && food == null) {
      _error = 'Еда: введите корректное число ХЕ';
      notifyListeners();
      return false;
    }
    if (shortInsulinRaw.trim().isNotEmpty && shortInsulin == null) {
      _error = 'Короткий инсулин: введите корректное число';
      notifyListeners();
      return false;
    }
    if (longInsulinRaw.trim().isNotEmpty && longInsulin == null) {
      _error = 'Продлённый инсулин: введите корректное число';
      notifyListeners();
      return false;
    }
    if (sugar == null &&
        food == null &&
        (foodPhotoPath == null || foodPhotoPath.isEmpty) &&
        shortInsulin == null &&
        longInsulin == null &&
        comment == null) {
      _error = 'Добавьте хотя бы одно значение';
      notifyListeners();
      return false;
    }

    _saving = true;
    notifyListeners();
    try {
      final newEntry = DiaryEntry(
        userId: userId,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
        sugarMmolL: sugar,
        foodXe: food,
        foodPhotoPath: foodPhotoPath,
        shortInsulinUnits: shortInsulin,
        longInsulinUnits: longInsulin,
        comment: comment,
        isAfterMeal: isAfterMeal,
      );
      final saved = await _repository.insert(newEntry);
      _entries.insert(0, saved);
      return true;
    } on DiaryRepositoryException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Ошибка при сохранении записи';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Редактирование существующей записи дневника.
  Future<bool> updateEntry({
    required int entryId,
    required int createdAtMillis,
    required String sugarRaw,
    required String foodRaw,
    required String? foodPhotoPath,
    required String shortInsulinRaw,
    required String longInsulinRaw,
    required String commentRaw,
    required bool isAfterMeal,
  }) async {
    _error = null;
    final userId = _currentUserId;
    if (userId == null) {
      _error = 'Пользователь не авторизован';
      notifyListeners();
      return false;
    }

    final sugar = _parseOptionalNumber(sugarRaw);
    final food = _parseOptionalNumber(foodRaw);
    final shortInsulin = _parseOptionalNumber(shortInsulinRaw);
    final longInsulin = _parseOptionalNumber(longInsulinRaw);
    final comment = commentRaw.trim().isEmpty ? null : commentRaw.trim();

    if (sugarRaw.trim().isNotEmpty && sugar == null) {
      _error = 'Сахар: введите корректное число';
      notifyListeners();
      return false;
    }
    if (foodRaw.trim().isNotEmpty && food == null) {
      _error = 'Еда: введите корректное число ХЕ';
      notifyListeners();
      return false;
    }
    if (shortInsulinRaw.trim().isNotEmpty && shortInsulin == null) {
      _error = 'Короткий инсулин: введите корректное число';
      notifyListeners();
      return false;
    }
    if (longInsulinRaw.trim().isNotEmpty && longInsulin == null) {
      _error = 'Продлённый инсулин: введите корректное число';
      notifyListeners();
      return false;
    }
    if (sugar == null &&
        food == null &&
        (foodPhotoPath == null || foodPhotoPath.isEmpty) &&
        shortInsulin == null &&
        longInsulin == null &&
        comment == null) {
      _error = 'Добавьте хотя бы одно значение';
      notifyListeners();
      return false;
    }

    _saving = true;
    notifyListeners();
    try {
      final updated = DiaryEntry(
        id: entryId,
        userId: userId,
        createdAtMillis: createdAtMillis,
        sugarMmolL: sugar,
        foodXe: food,
        foodPhotoPath: foodPhotoPath,
        shortInsulinUnits: shortInsulin,
        longInsulinUnits: longInsulin,
        comment: comment,
        isAfterMeal: isAfterMeal,
      );
      await _repository.update(updated);

      final idx = _entries.indexWhere((e) => e.id == entryId);
      if (idx != -1) {
        _entries[idx] = updated;
      }
      return true;
    } on DiaryRepositoryException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Ошибка при обновлении записи';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  double? _parseOptionalNumber(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
}
