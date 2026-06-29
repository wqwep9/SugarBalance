import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Инициализация и версионирование локальной БД SQLite.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  /// Открытая база (ленивая инициализация).
  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  /// Полный путь к файлу БД на этом устройстве (для отладки в logcat / Device File Explorer).
  Future<String> get databaseFilePath async {
    final dir = await getDatabasesPath();
    return p.join(dir, 'sugar_balance.db');
  }

  /// Создание файла БД и таблиц приложения.
  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'sugar_balance.db');
    return openDatabase(
      path,
      version: 7, // 👈 Обновлено с 6 на 7
      onCreate: (db, version) async {
        await _createUsersTable(db);
        await _createDiaryEntriesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createDiaryEntriesTable(db);
        }
        if (oldVersion < 3) {
          await _upgradeDiaryEntriesToV3(db);
        }
        if (oldVersion < 4) {
          await _upgradeDiaryEntriesToV4(db);
        }
        if (oldVersion < 5) {
          await _upgradeUsersToV5(db);
        }
        if (oldVersion < 6) {
          await _upgradeUsersToV6(db);
        }
        if (oldVersion < 7) {
          await _upgradeDiaryEntriesToV7(db);
        }
      },
    );
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        birth_date TEXT NOT NULL,
        diabetes_type INTEGER NOT NULL,
        gender INTEGER NOT NULL,
        carbs_xe REAL,
        hypoglycemia REAL,
        carb_coefficient REAL,
        basal_insulin_avg REAL,
        bolus_insulin_avg REAL,
        glucose_target_low REAL,
        glucose_target_high REAL,
        glucose_hypo REAL,
        glucose_hyper REAL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createDiaryEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS diary_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        sugar_mmol_l REAL,
        food_xe REAL,
        food_photo_path TEXT,
        short_insulin_units REAL,
        long_insulin_units REAL,
        comment TEXT,
        is_after_meal INTEGER NOT NULL DEFAULT 0,
        predicted_glucose_60min REAL,
        prediction_confidence REAL,
        prediction_status TEXT DEFAULT 'ok',
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  /// Миграция v3: добавляем поля инсулина.
  Future<void> _upgradeDiaryEntriesToV3(Database db) async {
    Future<void> addColumn(String sql) async {
      try {
        await db.execute(sql);
      } on DatabaseException {
        // Колонка уже существует — игнорируем для идемпотентности.
      }
    }

    await addColumn(
      'ALTER TABLE diary_entries ADD COLUMN short_insulin_units REAL',
    );
    await addColumn(
      'ALTER TABLE diary_entries ADD COLUMN long_insulin_units REAL',
    );
  }

  /// Миграция v4: добавляем путь к фото еды.
  Future<void> _upgradeDiaryEntriesToV4(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE diary_entries ADD COLUMN food_photo_path TEXT',
      );
    } on DatabaseException {
      // Колонка уже существует.
    }
  }

  /// Миграция v5: дополнительные поля профиля в `users`.
  Future<void> _upgradeUsersToV5(Database db) async {
    Future<void> addColumn(String sql) async {
      try {
        await db.execute(sql);
      } on DatabaseException {
        // Колонка уже существует.
      }
    }

    await addColumn('ALTER TABLE users ADD COLUMN carb_coefficient REAL');
    await addColumn('ALTER TABLE users ADD COLUMN basal_insulin_avg REAL');
    await addColumn('ALTER TABLE users ADD COLUMN bolus_insulin_avg REAL');
  }

  /// Миграция v6: настройки глюкозы (целевой диапазон, гипо, гипер).
  Future<void> _upgradeUsersToV6(Database db) async {
    Future<void> addColumn(String sql) async {
      try {
        await db.execute(sql);
      } on DatabaseException {
        // Колонка уже существует.
      }
    }

    await addColumn('ALTER TABLE users ADD COLUMN glucose_target_low REAL');
    await addColumn('ALTER TABLE users ADD COLUMN glucose_target_high REAL');
    await addColumn('ALTER TABLE users ADD COLUMN glucose_hypo REAL');
    await addColumn('ALTER TABLE users ADD COLUMN glucose_hyper REAL');

    // Перенос значения hypoglycemia → glucose_hypo если новое пустое
    try {
      await db.execute(
        'UPDATE users SET glucose_hypo = hypoglycemia WHERE glucose_hypo IS NULL AND hypoglycemia IS NOT NULL',
      );
    } on DatabaseException {
      // ignore
    }
  } // 👈 ЗАКРЫВАЮЩАЯ СКОБКА ДЛЯ _upgradeUsersToV6

  /// Миграция v7: поля для хранения прогноза глюкозы.
  Future<void> _upgradeDiaryEntriesToV7(Database db) async {
    Future<void> addColumn(String sql) async {
      try {
        await db.execute(sql);
      } on DatabaseException {
        // Колонка уже существует — идемпотентность
      }
    }

    await addColumn('ALTER TABLE diary_entries ADD COLUMN predicted_glucose_60min REAL');
    await addColumn('ALTER TABLE diary_entries ADD COLUMN prediction_confidence REAL');
    await addColumn('ALTER TABLE diary_entries ADD COLUMN prediction_status TEXT DEFAULT \'ok\'');
  } // 👈 ЗАКРЫВАЮЩАЯ СКОБКА ДЛЯ _upgradeDiaryEntriesToV7
} // 👈 ЗАКРЫВАЮЩАЯ СКОБКА ДЛЯ КЛАССА