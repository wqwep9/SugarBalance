import 'package:flutter/material.dart';

/// Брендовая палитра SugarBalance (по макету Figma).
///
/// Формат: [Color.fromARGB] — A (0–255), затем R, G, B как в подсказке Figma «RGB».
abstract final class AppColors {
  AppColors._();

  static const Color primary = Color.fromARGB(255, 46, 125, 154);
  static const Color primaryDark = Color.fromARGB(255, 27, 90, 112);
  static const Color secondary = Color.fromARGB(255, 77, 182, 172);

  static const Color background = Color.fromARGB(255, 248, 249, 250);

  /// Фон основных вкладок (Главная, Дневник, Статистика, Профиль).
  static const Color screenBackground = Color.fromARGB(255, 226, 236, 251);
  static const Color surface = Color.fromARGB(255, 255, 255, 255);

  static const Color textPrimary = Color.fromARGB(255, 12, 0, 74);

  /// Тёмно-синий: welcome, заголовки auth, обводка полей (макет Figma).
  static const Color formNavy = Color.fromARGB(255, 13, 27, 62);

  /// Подсказки в полях ввода (приглушённый синевато-серый).
  static const Color inputHint = Color.fromARGB(255, 130, 145, 170);

  /// Голубой акцент: «До еды / После еды», кнопка «Добавить измерение».
  static const Color accentBlue = Color.fromARGB(255, 134, 180, 243);
}
