import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/diary_report_formatter.dart';
import '../core/utils/formatters.dart';
import '../models/diary_report.dart';

/// Сохранение отчёта в файл и отправка через системное меню.
abstract final class DiaryReportExportService {
  DiaryReportExportService._();

  /// Имя файла отчёта для сохранения.
  static String buildFileName(DiaryReport report) {
    final from = _safeDate(Formatters.ddMMyyyy(report.from));
    final to = _safeDate(Formatters.ddMMyyyy(report.to));
    return 'SugarBalance_otchet_${from}_$to.txt';
  }

  static String _safeDate(String ddMMyyyy) => ddMMyyyy.replaceAll('.', '-');

  /// Записывает отчёт во временный файл.
  static Future<File> writeReportFile(DiaryReport report) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, buildFileName(report)));
    await file.writeAsString(
      DiaryReportFormatter.formatForExport(report),
      encoding: utf8,
    );
    return file;
  }

  /// Открывает системное меню «Поделиться / Сохранить» с файлом отчёта.
  static Future<void> shareReport(DiaryReport report) async {
    final file = await writeReportFile(report);
    final name = p.basename(file.path);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/plain', name: name)],
        subject: 'SugarBalance — отчёт',
        text: 'Статистика SugarBalance за выбранный период',
      ),
    );
  }
}
