import 'package:sqflite/sqflite.dart';

import '../models/diary_entry.dart';

/// Ошибки работы с таблицей дневника.
class DiaryRepositoryException implements Exception {
  DiaryRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Доступ к таблице `diary_entries`.
class DiaryRepository {
  DiaryRepository(this._db);
  final Database _db;

  static const _table = 'diary_entries';

  /// Сохранение новой записи дневника.
  Future<DiaryEntry> insert(DiaryEntry entry) async {
    final row = Map<String, Object?>.from(entry.toRow())..remove('id');
    try {
      final id = await _db.insert(_table, row);
      return DiaryEntry.fromRow({...row, 'id': id});
    } on DatabaseException catch (e) {
      throw DiaryRepositoryException('Не удалось сохранить запись: $e');
    }
  }

  /// Последние записи текущего пользователя.
  Future<List<DiaryEntry>> listByUser(int userId) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      return rows.map(DiaryEntry.fromRow).toList();
    } on DatabaseException catch (e) {
      throw DiaryRepositoryException('Не удалось загрузить записи: $e');
    }
  }

  /// Записи пользователя за период (включительно).
  Future<List<DiaryEntry>> listByUserBetween({
    required int userId,
    required int fromMillis,
    required int toMillis,
  }) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'user_id = ? AND created_at BETWEEN ? AND ?',
        whereArgs: [userId, fromMillis, toMillis],
        orderBy: 'created_at ASC',
      );
      return rows.map(DiaryEntry.fromRow).toList();
    } on DatabaseException catch (e) {
      throw DiaryRepositoryException('Не удалось загрузить записи: $e');
    }
  }

  /// Обновить существующую запись (по id).
  Future<void> update(DiaryEntry entry) async {
    if (entry.id == null) {
      throw DiaryRepositoryException(
        'Не удалось обновить запись: отсутствует id',
      );
    }
    final row = Map<String, Object?>.from(entry.toRow())..remove('id');
    try {
      await _db.update(_table, row, where: 'id = ?', whereArgs: [entry.id]);
    } on DatabaseException catch (e) {
      throw DiaryRepositoryException('Не удалось обновить запись: $e');
    }
  }
}
