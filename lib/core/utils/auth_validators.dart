/// Валидация полей входа и регистрации (возвращает текст ошибки или `null`, если ок).
abstract final class AuthValidators {
  AuthValidators._();

  static final RegExp _emailRx = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? email(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Введите почту';
    if (!_emailRx.hasMatch(s)) return 'Некорректный формат почты';
    return null;
  }

  /// Пароль на экране входа: только непустой.
  static String? passwordLogin(String? value) {
    final s = value ?? '';
    if (s.isEmpty) return 'Введите пароль';
    return null;
  }

  /// Пароль при регистрации: минимальная длина.
  static String? passwordRegister(String? value) {
    final s = value ?? '';
    if (s.isEmpty) return 'Введите пароль';
    if (s.length < 8) return 'Пароль не короче 8 символов';
    return null;
  }

  static String? username(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Введите имя пользователя';
    if (s.length < 3) return 'Имя не короче 3 символов';
    return null;
  }

  static String? birthDateRequired(String? value) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return 'Укажите дату рождения';
    final parsed = parseRuDate(s);
    if (parsed == null) return 'Формат даты: дд.мм.гггг';
    if (parsed.isAfter(DateTime.now())) {
      return 'Дата рождения не может быть в будущем';
    }
    return null;
  }

  /// Разбор строки `дд.мм.гггг` в [DateTime] (только дата).
  static DateTime? parseRuDate(String text) {
    final m = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(text.trim());
    if (m == null) return null;
    final day = int.tryParse(m.group(1)!);
    final month = int.tryParse(m.group(2)!);
    final year = int.tryParse(m.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    try {
      final dt = DateTime(year, month, day);
      if (dt.year != year || dt.month != month || dt.day != day) return null;
      return dt;
    } on ArgumentError {
      return null;
    }
  }

  /// Необязательное поле: пусто допустимо, иначе неотрицательное число.
  static String? optionalNonNegativeNumber(String fieldLabel, String? raw) {
    final s = raw?.trim().replaceAll(',', '.') ?? '';
    if (s.isEmpty) return null;
    final v = double.tryParse(s);
    if (v == null) return '$fieldLabel: укажите число';
    if (v < 0) return '$fieldLabel: значение не может быть отрицательным';
    return null;
  }
}
