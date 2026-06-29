import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/diary_report_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/diary_report.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/diary_provider.dart';
import '../../../repositories/diary_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/diary_report_export_service.dart';
import '../../../services/diary_report_service.dart';

/// Профиль: данные регистрации + доп. настройки + запрос статистики за период.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DateTimeRange? _range;
  bool _busy = false;

  Future<void> _editNumberField({
    required String title,
    required double? initial,
    required String hint,
    required ValueChanged<double?> onSaved,
  }) async {
    final controller = TextEditingController(
      text: initial == null ? '' : initial.toString(),
    );
    final result = await showDialog<double?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final raw = controller.text.trim().replaceAll(',', '.');
                if (raw.isEmpty) {
                  Navigator.of(context).pop(double.nan); // сигнал "очистить"
                  return;
                }
                final value = double.tryParse(raw);
                Navigator.of(context).pop(value);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;
    if (result.isNaN) {
      onSaved(null);
      return;
    }
    if (result <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите положительное число')),
      );
      return;
    }
    onSaved(result);
  }

  Future<void> _saveExtras({
    required int userId,
    required double? carbCoefficient,
    required double? basalInsulinAvg,
    required double? bolusInsulinAvg,
    required double? glucoseTargetLow,
    required double? glucoseTargetHigh,
    required double? glucoseHypo,
    required double? glucoseHyper,
  }) async {
    setState(() => _busy = true);
    try {
      final repo = context.read<UserRepository>();
      await repo.updateProfileExtras(
        userId: userId,
        carbCoefficient: carbCoefficient,
        basalInsulinAvg: basalInsulinAvg,
        bolusInsulinAvg: bolusInsulinAvg,
        glucoseTargetLow: glucoseTargetLow,
        glucoseTargetHigh: glucoseTargetHigh,
        glucoseHypo: glucoseHypo,
        glucoseHyper: glucoseHyper,
      );
      final fresh = await repo.findById(userId);
      if (!mounted) return;
      if (fresh != null) {
        context.read<AuthProvider>().setCurrentUser(fresh);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Профиль обновлён')));
    } on UserRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editGlucoseTargetRange({
    required double? lowInitial,
    required double? highInitial,
    required ValueChanged<({double? low, double? high})> onSaved,
  }) async {
    final lowController = TextEditingController(
      text: lowInitial == null ? '' : lowInitial.toString(),
    );
    final highController = TextEditingController(
      text: highInitial == null ? '' : highInitial.toString(),
    );

    final result = await showDialog<({double? low, double? high})?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Целевой диапазон'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: lowController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: 'Нижняя граница',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: highController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: 'Верхняя граница',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final lowRaw = lowController.text.trim().replaceAll(',', '.');
                final highRaw = highController.text.trim().replaceAll(',', '.');
                if (lowRaw.isEmpty && highRaw.isEmpty) {
                  Navigator.of(context).pop((low: null, high: null));
                  return;
                }
                final low = lowRaw.isEmpty ? null : double.tryParse(lowRaw);
                final high = highRaw.isEmpty ? null : double.tryParse(highRaw);
                Navigator.of(context).pop((low: low, high: high));
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;
    final low = result.low;
    final high = result.high;

    if ((lowController.text.trim().isNotEmpty && low == null) ||
        (highController.text.trim().isNotEmpty && high == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректные числа диапазона')),
      );
      return;
    }
    if (low != null && high != null && low >= high) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нижняя граница должна быть меньше верхней'),
        ),
      );
      return;
    }

    onSaved((low: low, high: high));
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initial =
        _range ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 6),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
    );
    if (!mounted || picked == null) return;
    setState(() => _range = picked);
  }

  Future<void> _requestReport(int userId) async {
    final range = _range;
    if (range == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите период')));
      return;
    }

    setState(() => _busy = true);
    try {
      final repo = context.read<DiaryRepository>();
      final from = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final to = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      final entries = await repo.listByUserBetween(
        userId: userId,
        fromMillis: from.millisecondsSinceEpoch,
        toMillis: to.millisecondsSinceEpoch,
      );
      final report = DiaryReportService.build(
        entries: entries,
        from: from,
        to: to,
        user: context.read<AuthProvider>().currentUser,
      );
      if (!mounted) return;
      await _showReport(report);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось получить отчёт')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveReport(DiaryReport report) async {
    try {
      await DiaryReportExportService.shareReport(report);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Выберите «Сохранить в файлы» или другое приложение',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить отчёт')),
      );
    }
  }

  Future<void> _showReport(DiaryReport report) async {
    final text = DiaryReportFormatter.format(report);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Отчёт'),
          content: SingleChildScrollView(child: Text(text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Закрыть'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                unawaited(_saveReport(report));
              },
              icon: const Icon(Icons.save_alt_outlined, size: 20),
              label: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final bg = const Color.fromARGB(255, 226, 236, 251);

    if (user == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(title: const Text('Профиль'), backgroundColor: bg),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go(AppRouter.welcome),
            child: const Text('Войти'),
          ),
        ),
      );
    }

    final genderLabel = user.gender == 0 ? 'М' : 'Ж';
    final diabetesLabel = user.diabetesType == 1 ? 'I' : 'II';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: bg,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _InfoRow(label: user.username, valueChip: genderLabel, onTap: null),
            _InfoRow(label: user.email, onTap: null),
            _InfoRow(label: Formatters.ddMMyyyy(user.birthDate), onTap: null),
            _InfoRow(
              label: 'Тип диабета',
              valueChip: diabetesLabel,
              onTap: null,
            ),
            const SizedBox(height: 10),
            _EditableRow(
              label: 'Углеводный коэффициент',
              valueText: user.carbCoefficient == null
                  ? '—'
                  : Formatters.number2(user.carbCoefficient!),
              onTap: _busy
                  ? null
                  : () => unawaited(
                      _editNumberField(
                        title: 'Углеводный коэффициент',
                        initial: user.carbCoefficient,
                        hint: 'Например: 1.5',
                        onSaved: (v) => unawaited(
                          _saveExtras(
                            userId: user.id!,
                            carbCoefficient: v,
                            basalInsulinAvg: user.basalInsulinAvg,
                            bolusInsulinAvg: user.bolusInsulinAvg,
                            glucoseTargetLow: user.glucoseTargetLow,
                            glucoseTargetHigh: user.glucoseTargetHigh,
                            glucoseHypo: user.glucoseHypo,
                            glucoseHyper: user.glucoseHyper,
                          ),
                        ),
                      ),
                    ),
            ),
            _GlucoseSection(
              targetLow: user.glucoseTargetLow,
              targetHigh: user.glucoseTargetHigh,
              hypo: user.glucoseHypo ?? user.hypoglycemia,
              hyper: user.glucoseHyper,
              onEditTarget: _busy
                  ? null
                  : () => unawaited(
                      _editGlucoseTargetRange(
                        lowInitial: user.glucoseTargetLow,
                        highInitial: user.glucoseTargetHigh,
                        onSaved: (range) => unawaited(
                          _saveExtras(
                            userId: user.id!,
                            carbCoefficient: user.carbCoefficient,
                            basalInsulinAvg: user.basalInsulinAvg,
                            bolusInsulinAvg: user.bolusInsulinAvg,
                            glucoseTargetLow: range.low,
                            glucoseTargetHigh: range.high,
                            glucoseHypo: user.glucoseHypo ?? user.hypoglycemia,
                            glucoseHyper: user.glucoseHyper,
                          ),
                        ),
                      ),
                    ),
              onEditHypo: _busy
                  ? null
                  : () => unawaited(
                      _editNumberField(
                        title: 'Гипогликемия',
                        initial: user.glucoseHypo ?? user.hypoglycemia,
                        hint: 'Например: 3.9',
                        onSaved: (v) => unawaited(
                          _saveExtras(
                            userId: user.id!,
                            carbCoefficient: user.carbCoefficient,
                            basalInsulinAvg: user.basalInsulinAvg,
                            bolusInsulinAvg: user.bolusInsulinAvg,
                            glucoseTargetLow: user.glucoseTargetLow,
                            glucoseTargetHigh: user.glucoseTargetHigh,
                            glucoseHypo: v,
                            glucoseHyper: user.glucoseHyper,
                          ),
                        ),
                      ),
                    ),
              onEditHyper: _busy
                  ? null
                  : () => unawaited(
                      _editNumberField(
                        title: 'Гипергликемия',
                        initial: user.glucoseHyper,
                        hint: 'Например: 9.0',
                        onSaved: (v) => unawaited(
                          _saveExtras(
                            userId: user.id!,
                            carbCoefficient: user.carbCoefficient,
                            basalInsulinAvg: user.basalInsulinAvg,
                            bolusInsulinAvg: user.bolusInsulinAvg,
                            glucoseTargetLow: user.glucoseTargetLow,
                            glucoseTargetHigh: user.glucoseTargetHigh,
                            glucoseHypo: user.glucoseHypo ?? user.hypoglycemia,
                            glucoseHyper: v,
                          ),
                        ),
                      ),
                    ),
            ),
            _EditableRow(
              label: 'Базальный инсулин',
              subtitle: '(среднесуточное количество)',
              valueText: user.basalInsulinAvg == null
                  ? '—'
                  : '${Formatters.number1(user.basalInsulinAvg!)} ед.',
              onTap: _busy
                  ? null
                  : () => unawaited(
                      _editNumberField(
                        title: 'Базальный инсулин (среднесуточно)',
                        initial: user.basalInsulinAvg,
                        hint: 'Например: 14',
                        onSaved: (v) => unawaited(
                          _saveExtras(
                            userId: user.id!,
                            carbCoefficient: user.carbCoefficient,
                            basalInsulinAvg: v,
                            bolusInsulinAvg: user.bolusInsulinAvg,
                            glucoseTargetLow: user.glucoseTargetLow,
                            glucoseTargetHigh: user.glucoseTargetHigh,
                            glucoseHypo: user.glucoseHypo,
                            glucoseHyper: user.glucoseHyper,
                          ),
                        ),
                      ),
                    ),
            ),
            _EditableRow(
              label: 'Болюсный инсулин',
              subtitle: '(среднесуточное количество)',
              valueText: user.bolusInsulinAvg == null
                  ? '—'
                  : '${Formatters.number1(user.bolusInsulinAvg!)} ед.',
              onTap: _busy
                  ? null
                  : () => unawaited(
                      _editNumberField(
                        title: 'Болюсный инсулин (среднесуточно)',
                        initial: user.bolusInsulinAvg,
                        hint: 'Например: 10',
                        onSaved: (v) => unawaited(
                          _saveExtras(
                            userId: user.id!,
                            carbCoefficient: user.carbCoefficient,
                            basalInsulinAvg: user.basalInsulinAvg,
                            bolusInsulinAvg: v,
                            glucoseTargetLow: user.glucoseTargetLow,
                            glucoseTargetHigh: user.glucoseTargetHigh,
                            glucoseHypo: user.glucoseHypo,
                            glucoseHyper: user.glucoseHyper,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ЗАПРОСИТЬ СТАТИСТИКУ',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.formNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'ПЕРИОД',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.formNavy.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => unawaited(_pickRange()),
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            _range == null
                                ? '__.__.__ — __.__.__'
                                : '${Formatters.ddMMyyyy(_range!.start)} — ${Formatters.ddMMyyyy(_range!.end)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => unawaited(_requestReport(user.id!)),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 143, 182, 240),
                        ),
                      ),
                      child: const Text('Получить'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            InkWell(
              onTap: _busy
                  ? null
                  : () async {
                      await context.read<AuthProvider>().signOut();
                      if (!context.mounted) return;
                      context.read<DiaryProvider>().reset();
                      context.go(AppRouter.welcome);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      color: const Color.fromARGB(255, 244, 67, 54),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Выйти из аккаунта',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.formNavy,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.valueChip, required this.onTap});

  final String label;
  final String? valueChip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 226, 236, 251),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 190, 212, 245)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 162, 235, 197),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.formNavy,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (valueChip != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 147, 197, 255),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black),
              ),
              child: Text(
                valueChip!,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.label,
    required this.valueText,
    this.subtitle,
    required this.onTap,
  });

  final String label;
  final String valueText;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 226, 236, 251),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color.fromARGB(255, 190, 212, 245)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 162, 235, 197),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.formNavy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.formNavy.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              valueText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.formNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlucoseSection extends StatefulWidget {
  const _GlucoseSection({
    required this.targetLow,
    required this.targetHigh,
    required this.hypo,
    required this.hyper,
    required this.onEditTarget,
    required this.onEditHypo,
    required this.onEditHyper,
  });

  final double? targetLow;
  final double? targetHigh;
  final double? hypo;
  final double? hyper;

  final VoidCallback? onEditTarget;
  final VoidCallback? onEditHypo;
  final VoidCallback? onEditHyper;

  @override
  State<_GlucoseSection> createState() => _GlucoseSectionState();
}

class _GlucoseSectionState extends State<_GlucoseSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = const Color.fromARGB(255, 190, 212, 245);

    String fmtRange() {
      final low = widget.targetLow;
      final high = widget.targetHigh;
      if (low == null && high == null) return '—';
      final lowText = low == null ? '—' : Formatters.number1(low);
      final highText = high == null ? '—' : Formatters.number1(high);
      return '$lowText–$highText ммоль/л';
    }

    String fmtHypo() {
      if (widget.hypo == null) return '—';
      return '<${Formatters.number1(widget.hypo!)} ммоль/л';
    }

    String fmtHyper() {
      if (widget.hyper == null) return '—';
      return '>${Formatters.number1(widget.hyper!)} ммоль/л';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 226, 236, 251),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 162, 235, 197),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Глюкоза',
                      style: TextStyle(
                        color: AppColors.formNavy,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.formNavy,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                Divider(height: 1, color: borderColor),
                _GlucoseSubRow(
                  title: 'Целевой диапазон',
                  hint: '(Например: 4.0–8.5 ммоль/л)',
                  value: fmtRange(),
                  onTap: widget.onEditTarget,
                ),
                Divider(height: 1, color: borderColor),
                _GlucoseSubRow(
                  title: 'Гипогликемия',
                  hint: '(Например: <3.9 ммоль/л)',
                  value: fmtHypo(),
                  onTap: widget.onEditHypo,
                ),
                Divider(height: 1, color: borderColor),
                _GlucoseSubRow(
                  title: 'Гипергликемия',
                  hint: '(Например: >9.0 ммоль/л)',
                  value: fmtHyper(),
                  onTap: widget.onEditHyper,
                ),
              ],
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _GlucoseSubRow extends StatelessWidget {
  const _GlucoseSubRow({
    required this.title,
    required this.hint,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String hint;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 24, height: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.formNavy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    hint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.formNavy.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.formNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
