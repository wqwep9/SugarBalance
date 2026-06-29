import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/diary_entry.dart';
import '../../../providers/diary_provider.dart';
import '../../../services/glucose_prediction_service.dart';
import '../../../services/statistics_service.dart';

/// Вкладка «Сводка»: текущее значение и оффлайн-прогноз глюкозы на 30–60 минут.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  double? _currentGlucose;
  double? _predictedGlucose;
  double _confidence = 0.0;
  String? _message;
  String? _contextSummary;

  DiaryProvider? _diaryProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _diaryProvider = context.read<DiaryProvider>();
      _diaryProvider!.addListener(_onDiaryChanged);
      unawaited(_loadPrediction());
    });
  }

  @override
  void dispose() {
    _diaryProvider?.removeListener(_onDiaryChanged);
    super.dispose();
  }

  /// Пересчёт прогноза при изменении дневника (новая запись, редактирование).
  void _onDiaryChanged() {
    if (!mounted || _loading) return;
    unawaited(_loadPrediction());
  }

  Future<void> _loadPrediction() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) {
        setState(() {
          _message = 'Сначала выполните вход';
          _contextSummary = null;
          _loading = false;
        });
        return;
      }

      final diary = context.read<DiaryProvider>();
      await diary.loadEntriesIfNeeded();

      final response = await GlucosePredictionService.predictFromEntries(
        diary.entries,
      );

      if (!mounted) return;

      final result = response.result;
      setState(() {
        _currentGlucose = _extractLatestGlucose(diary.entries);
        _predictedGlucose = result.prediction;
        _confidence = result.confidence;
        _message = result.message;
        _contextSummary = response.contextSummary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Не удалось построить прогноз';
        _contextSummary = null;
        _loading = false;
      });
    }
  }

  double? _extractLatestGlucose(List<DiaryEntry> entries) {
    DateTime? bestTime;
    double? glucose;
    for (final e in entries) {
      final g = e.sugarMmolL;
      if (g == null) continue;
      if (bestTime == null || e.createdAt.isAfter(bestTime)) {
        bestTime = e.createdAt;
        glucose = g;
      }
    }
    return glucose;
  }

  Future<void> _showPredictionInfoDialog() async {
    final user = context.read<AuthProvider>().currentUser;
    final targetLow =
        user?.glucoseTargetLow ?? StatisticsService.defaultTargetLow;
    final targetHigh =
        user?.glucoseTargetHigh ?? StatisticsService.defaultTargetHigh;
    final hypo = user?.glucoseHypo ?? user?.hypoglycemia ?? 3.9;
    final hyper = user?.glucoseHyper ?? 10.0;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final sectionTitle = theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.formNavy,
        );
        final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.formNavy.withValues(alpha: 0.85),
          height: 1.45,
        );

        return AlertDialog(
          title: const Text('О прогнозе глюкозы'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Как строится прогноз', style: sectionTitle),
                const SizedBox(height: 6),
                Text(
                  'Прогноз на 1 час рассчитывается офлайн на устройстве по '
                  'модели машинного обучения. Учитываются:\n'
                  '• последнее измерение глюкозы из дневника;\n'
                  '• активный инсулин за последние 4 часа (короткий и продлённый);\n'
                  '• углеводы из записей о еде (1 ХЕ = 12 г).\n\n'
                  'Чем полнее и свежее данные в дневнике, тем ближе прогноз '
                  'к реальной динамике сахара.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 16),
                Text('Важно', style: sectionTitle),
                const SizedBox(height: 6),
                Text(
                  'Прогноз носит ознакомительный характер и не является '
                  'медицинским заключением. Он не заменяет измерение на '
                  'глюкометре и рекомендации лечащего врача. При сомнениях '
                  'всегда ориентируйтесь на фактическое измерение сахара.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 16),
                Text('Что делать при разных уровнях', style: sectionTitle),
                const SizedBox(height: 6),
                _PredictionLevelHint(
                  title: 'Гипогликемия (ниже ${hypo.toStringAsFixed(1)} ммоль/л)',
                  text:
                      'Примите быстрые углеводы (сок, глюкозные таблетки), '
                      'измерьте сахар повторно через 15 минут. При '
                      'слабости, спутанности сознания или отсутствии '
                      'улучшения — срочно обратитесь за медицинской помощью.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 10),
                _PredictionLevelHint(
                  title:
                      'Целевой диапазон (${targetLow.toStringAsFixed(1)}–'
                      '${targetHigh.toStringAsFixed(1)} ммоль/л)',
                  text:
                      'Продолжайте привычный режим: питание, инсулин и '
                      'самоконтроль по плану врача. Добавляйте измерения '
                      'в дневник для более точного прогноза.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 10),
                _PredictionLevelHint(
                  title: 'Повышенный сахар (выше ${targetHigh.toStringAsFixed(1)} ммоль/л)',
                  text:
                      'Проверьте сахар глюкометром, оцените недавнюю еду и '
                      'инсулин. Действуйте по схеме коррекции, согласованной '
                      'с врачом. Пейте воду, избегайте дополнительных '
                      'углеводов без необходимости.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 10),
                _PredictionLevelHint(
                  title: 'Гипергликемия (выше ${hyper.toStringAsFixed(1)} ммоль/л)',
                  text:
                      'Измерьте кетоны при необходимости, выполните коррекцию '
                      'по назначению врача. При стойком высоком сахаре, '
                      'тошноте или рвоте — обратитесь за медицинской помощью.',
                  style: bodyStyle,
                ),
                const SizedBox(height: 12),
                Text(
                  'Пороговые значения взяты из вашего профиля. Их можно '
                  'изменить в разделе «Профиль» → «Глюкоза».',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.formNavy.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Понятно'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color.fromARGB(255, 226, 236, 251);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Главная',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            color: AppColors.formNavy,
          ),
        ),
        backgroundColor: bg,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPrediction,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _ValueCard(
                  title: 'Текущий уровень глюкозы',
                  value: _currentGlucose,
                  suffix: 'ммоль/л',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => context.go(AppRouter.diary),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: AppColors.formNavy.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Добавить измерение'),
                  ),
                ),
                const SizedBox(height: 16),
                _ValueCard(
                  title: 'Прогноз на 1 час',
                  value: _predictedGlucose,
                  suffix: 'ммоль/л',
                  subtitle: _buildPredictionSubtitle(),
                  showChevron: true,
                  onTap: () => unawaited(_showPredictionInfoDialog()),
                  valueColor: _predictedGlucose != null
                      ? const Color.fromARGB(255, 0, 170, 67)
                      : const Color.fromARGB(255, 0, 120, 180),
                ),
                if (_predictedGlucose != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Уверенность: ${(_confidence * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _buildPredictionSubtitle() {
    final parts = <String>[];
    if (_contextSummary != null && _contextSummary!.isNotEmpty) {
      parts.add(_contextSummary!);
    }
    if (_message != null && _message!.isNotEmpty) {
      parts.add(_message!);
    }
    if (parts.isEmpty) return null;
    return parts.join('\n');
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.title,
    required this.value,
    required this.suffix,
    this.subtitle,
    this.valueColor,
    this.showChevron = false,
    this.onTap,
  });

  final String title;
  final double? value;
  final String suffix;
  final String? subtitle;
  final Color? valueColor;
  final bool showChevron;
  final VoidCallback? onTap;

  static const _glucoseGreen = Color.fromARGB(255, 0, 170, 67);

  @override
  Widget build(BuildContext context) {
    final display = value == null ? '—' : value!.toStringAsFixed(1);
    final color = valueColor ?? _glucoseGreen;

    final titleStyle = GoogleFonts.montserrat(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary.withValues(alpha: 0.92),
    );

    final valueStyle = GoogleFonts.montserrat(
      fontSize: 52,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.0,
    );

    final unitStyle = GoogleFonts.montserrat(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: color,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: titleStyle)),
                  if (showChevron)
                    Icon(
                      Icons.chevron_right,
                      size: 28,
                      color: AppColors.textPrimary.withValues(alpha: 0.75),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(display, style: valueStyle),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(suffix, style: unitStyle),
                    ),
                  ],
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  subtitle!,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPrimary.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PredictionLevelHint extends StatelessWidget {
  const _PredictionLevelHint({
    required this.title,
    required this.text,
    required this.style,
  });

  final String title;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: style?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(text, style: style),
      ],
    );
  }
}
