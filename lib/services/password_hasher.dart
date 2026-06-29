import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Локальное хеширование пароля (SHA-256 + соль из почты и константы приложения).
/// Для дипломного офлайн-приложения; в продакшене рассмотреть bcrypt/argon2.
abstract final class PasswordHasher {
  PasswordHasher._();

  static String hash(String email, String plainPassword) {
    final normalized = email.trim().toLowerCase();
    final payload = '$plainPassword::$normalized::SugarBalance_v1';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Сравнение введённого пароля с сохранённым хешем.
  static bool verify(String email, String plainPassword, String storedHash) {
    return hash(email, plainPassword) == storedHash;
  }
}
