/// Профиль пользователя SugarBalance (локальное хранение в SQLite).
class UserProfile {
  const UserProfile({
    this.id,
    required this.username,
    required this.email,
    this.passwordHash,
    required this.birthDate,
    required this.diabetesType,
    required this.gender,
    this.carbsXe,
    this.hypoglycemia,
    this.carbCoefficient,
    this.basalInsulinAvg,
    this.bolusInsulinAvg,
    this.glucoseTargetLow,
    this.glucoseTargetHigh,
    this.glucoseHypo,
    this.glucoseHyper,
    this.createdAtMillis,
  });

  final int? id;
  final String username;
  final String email;

  /// Хеш пароля; в сессии после входа не используется ([stripSecret]).
  final String? passwordHash;
  final DateTime birthDate;

  /// 1 — тип I, 2 — тип II.
  final int diabetesType;

  /// 0 — муж., 1 — жен.
  final int gender;
  final double? carbsXe;
  final double? hypoglycemia;
  final double? carbCoefficient;
  final double? basalInsulinAvg;
  final double? bolusInsulinAvg;
  final double? glucoseTargetLow;
  final double? glucoseTargetHigh;
  final double? glucoseHypo;
  final double? glucoseHyper;
  final int? createdAtMillis;

  /// Копия без секрета для хранения в памяти приложения.
  UserProfile stripSecret() {
    return UserProfile(
      id: id,
      username: username,
      email: email,
      birthDate: birthDate,
      diabetesType: diabetesType,
      gender: gender,
      carbsXe: carbsXe,
      hypoglycemia: hypoglycemia,
      carbCoefficient: carbCoefficient,
      basalInsulinAvg: basalInsulinAvg,
      bolusInsulinAvg: bolusInsulinAvg,
      glucoseTargetLow: glucoseTargetLow,
      glucoseTargetHigh: glucoseTargetHigh,
      glucoseHypo: glucoseHypo,
      glucoseHyper: glucoseHyper,
      createdAtMillis: createdAtMillis,
    );
  }

  /// Строка для таблицы `users` (вставка / обновление).
  Map<String, Object?> toRow() {
    return {
      if (id != null) 'id': id,
      'username': username.trim(),
      'email': email.trim().toLowerCase(),
      if (passwordHash != null) 'password_hash': passwordHash,
      'birth_date': _birthToIso(birthDate),
      'diabetes_type': diabetesType,
      'gender': gender,
      'carbs_xe': carbsXe,
      'hypoglycemia': hypoglycemia,
      'carb_coefficient': carbCoefficient,
      'basal_insulin_avg': basalInsulinAvg,
      'bolus_insulin_avg': bolusInsulinAvg,
      'glucose_target_low': glucoseTargetLow,
      'glucose_target_high': glucoseTargetHigh,
      'glucose_hypo': glucoseHypo,
      'glucose_hyper': glucoseHyper,
      if (createdAtMillis != null) 'created_at': createdAtMillis,
    };
  }

  /// Чтение из результата запроса SQLite.
  factory UserProfile.fromRow(Map<String, Object?> map) {
    final birth = map['birth_date'] as String;
    return UserProfile(
      id: map['id'] as int?,
      username: map['username'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String?,
      birthDate: DateTime.parse(birth),
      diabetesType: map['diabetes_type'] as int,
      gender: map['gender'] as int,
      carbsXe: (map['carbs_xe'] as num?)?.toDouble(),
      hypoglycemia: (map['hypoglycemia'] as num?)?.toDouble(),
      carbCoefficient: (map['carb_coefficient'] as num?)?.toDouble(),
      basalInsulinAvg: (map['basal_insulin_avg'] as num?)?.toDouble(),
      bolusInsulinAvg: (map['bolus_insulin_avg'] as num?)?.toDouble(),
      glucoseTargetLow: (map['glucose_target_low'] as num?)?.toDouble(),
      glucoseTargetHigh: (map['glucose_target_high'] as num?)?.toDouble(),
      glucoseHypo: (map['glucose_hypo'] as num?)?.toDouble(),
      glucoseHyper: (map['glucose_hyper'] as num?)?.toDouble(),
      createdAtMillis: map['created_at'] as int?,
    );
  }

  static String _birthToIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
