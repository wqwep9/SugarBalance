import 'package:sqflite/sqflite.dart';

import '../models/user_profile.dart';
import '../services/password_hasher.dart';

/// Ошибки при работе с пользователями в БД.
class UserRepositoryException implements Exception {
  UserRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Доступ к таблице `users`: регистрация и проверка входа.
class UserRepository {
  UserRepository(this._db);
  final Database _db;

  static const _table = 'users';
  bool _extrasSchemaChecked = false;

  /// Поиск по почте (для входа и проверки уникальности).
  Future<UserProfile?> findByEmail(String email) async {
    final rows = await _db.query(
      _table,
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromRow(rows.first);
  }

  /// Проверка пары почта + пароль.
  Future<UserProfile?> verifyCredentials(
    String email,
    String plainPassword,
  ) async {
    final user = await findByEmail(email);
    if (user == null || user.passwordHash == null) return null;
    final ok = PasswordHasher.verify(email, plainPassword, user.passwordHash!);
    return ok ? user : null;
  }

  /// Сохранение нового пользователя. При дубликате почты — [UserRepositoryException].
  Future<UserProfile> insertUser(UserProfile profile) async {
    final row = Map<String, Object?>.from(profile.toRow())
      ..remove('id')
      ..['created_at'] = DateTime.now().millisecondsSinceEpoch;

    try {
      final id = await _db.insert(_table, row);
      return UserProfile.fromRow({...row, 'id': id});
    } on DatabaseException catch (e) {
      final msg = e.toString();
      if (msg.contains('UNIQUE') || msg.contains('unique')) {
        throw UserRepositoryException(
          'Пользователь с такой почтой уже зарегистрирован',
        );
      }
      throw UserRepositoryException('Не удалось сохранить данные: $msg');
    }
  }

  /// Получить пользователя по id.
  Future<UserProfile?> findById(int id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromRow(rows.first);
  }

  /// Обновить дополнительные поля профиля.
  Future<void> updateProfileExtras({
    required int userId,
    double? carbCoefficient,
    double? basalInsulinAvg,
    double? bolusInsulinAvg,
    double? glucoseTargetLow,
    double? glucoseTargetHigh,
    double? glucoseHypo,
    double? glucoseHyper,
  }) async {
    try {
      await _ensureExtrasSchema();
      await _db.update(
        _table,
        {
          'carb_coefficient': carbCoefficient,
          'basal_insulin_avg': basalInsulinAvg,
          'bolus_insulin_avg': bolusInsulinAvg,
          'glucose_target_low': glucoseTargetLow,
          'glucose_target_high': glucoseTargetHigh,
          'glucose_hypo': glucoseHypo,
          'glucose_hyper': glucoseHyper,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
    } on DatabaseException catch (e) {
      // На hot-reload/старой базе могло не быть новых колонок — пробуем один раз починить.
      final msg = e.toString();
      if (!_extrasSchemaChecked && msg.contains('no such column')) {
        await _ensureExtrasSchema(force: true);
        try {
          await _db.update(
            _table,
            {
              'carb_coefficient': carbCoefficient,
              'basal_insulin_avg': basalInsulinAvg,
              'bolus_insulin_avg': bolusInsulinAvg,
              'glucose_target_low': glucoseTargetLow,
              'glucose_target_high': glucoseTargetHigh,
              'glucose_hypo': glucoseHypo,
              'glucose_hyper': glucoseHyper,
            },
            where: 'id = ?',
            whereArgs: [userId],
          );
          return;
        } on DatabaseException catch (e2) {
          throw UserRepositoryException('Не удалось сохранить профиль: $e2');
        }
      }

      throw UserRepositoryException('Не удалось сохранить профиль: $e');
    }
  }

  /// Проверяет наличие колонок доп. профиля и добавляет их при необходимости.
  /// Это защищает от ситуации, когда миграции не применились из-за hot-reload.
  Future<void> _ensureExtrasSchema({bool force = false}) async {
    if (_extrasSchemaChecked && !force) return;

    final columns = await _db.rawQuery('PRAGMA table_info($_table)');
    final names = columns.map((row) => row['name']).whereType<String>().toSet();

    Future<void> addIfMissing(String name, String sql) async {
      if (names.contains(name)) return;
      try {
        await _db.execute(sql);
      } on DatabaseException {
        // Параллельная попытка/повтор — игнор.
      }
    }

    await addIfMissing(
      'carb_coefficient',
      'ALTER TABLE $_table ADD COLUMN carb_coefficient REAL',
    );
    await addIfMissing(
      'basal_insulin_avg',
      'ALTER TABLE $_table ADD COLUMN basal_insulin_avg REAL',
    );
    await addIfMissing(
      'bolus_insulin_avg',
      'ALTER TABLE $_table ADD COLUMN bolus_insulin_avg REAL',
    );
    await addIfMissing(
      'glucose_target_low',
      'ALTER TABLE $_table ADD COLUMN glucose_target_low REAL',
    );
    await addIfMissing(
      'glucose_target_high',
      'ALTER TABLE $_table ADD COLUMN glucose_target_high REAL',
    );
    await addIfMissing(
      'glucose_hypo',
      'ALTER TABLE $_table ADD COLUMN glucose_hypo REAL',
    );
    await addIfMissing(
      'glucose_hyper',
      'ALTER TABLE $_table ADD COLUMN glucose_hyper REAL',
    );

    _extrasSchemaChecked = true;
  }
}
