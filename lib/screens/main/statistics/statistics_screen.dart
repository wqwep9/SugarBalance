import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/statistics_formatters.dart';
import '../../../models/diary_entry.dart';
import '../../../models/glucose_statistics.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/diary_repository.dart';
import '../../../services/statistics_service.dart';
import '../../../widgets/statistics/glucose_line_chart_card.dart';
import '../../../widgets/statistics/statistics_summary_cards.dart';

/// Статистика по данным дневника: графики глюкозы и сводки за период.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatisticsPeriod _period = StatisticsPeriod.days7;
  bool _loading = true;
  GlucoseStatistics? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user?.id == null) {
        setState(() {
          _stats = null;
          _error = 'Войдите в аккаунт для просмотра статистики';
          _loading = false;
        });
        return;
      }

      final stats = StatisticsService.build(
        entries: await _fetchEntries(user!.id!),
        period: _period,
        user: user,
      );

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить статистику';
        _loading = false;
      });
    }
  }

  Future<List<DiaryEntry>> _fetchEntries(int userId) async {
    final repo = context.read<DiaryRepository>();
    final end = DateTime.now();
    final start = DateTime(end.year, end.month, end.day)
        .subtract(Duration(days: _period.days - 1));
    return repo.listByUserBetween(
      userId: userId,
      fromMillis: start.millisecondsSinceEpoch,
      toMillis: DateTime(end.year, end.month, end.day, 23, 59, 59, 999)
          .millisecondsSinceEpoch,
    );
  }

  void _onPeriodChanged(StatisticsPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.screenBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Статистика'),
        backgroundColor: bg,
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _PeriodTabs(
                  selected: _period,
                  onSelected: _onPeriodChanged,
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.formNavy,
                            ),
                      ),
                    ),
                  ),
                )
              else if (_stats != null)
                SliverToBoxAdapter(child: _StatisticsBody(stats: _stats!)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({
    required this.selected,
    required this.onSelected,
  });

  final StatisticsPeriod selected;
  final ValueChanged<StatisticsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Row(
        children: StatisticsPeriod.values.map((p) {
          final isSel = p == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(p),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      p.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSel ? FontWeight.w600 : FontWeight.w400,
                        color: isSel
                            ? AppColors.formNavy
                            : AppColors.formNavy.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSel
                          ? const Color.fromARGB(255, 220, 80, 70)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({required this.stats});

  final GlucoseStatistics stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final singleDay = stats.periodDays == 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              StatisticsFormatters.dateRangeRu(stats.from, stats.to),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.formNavy.withValues(alpha: 0.75),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlucoseLineChartCard(stats: stats, singleDay: singleDay),
          const SizedBox(height: 16),
          StatisticsSummaryCards(stats: stats),
          const SizedBox(height: 20),
          _DetailStatRow(
            icon: Icons.restaurant,
            iconColor: const Color.fromARGB(255, 255, 160, 80),
            title: 'Количество ХЕ',
            subtitle: stats.avgXePerDay == null
                ? 'Нет записей о еде за период.'
                : 'По результатам записей вы потребляете в среднем '
                    '${StatisticsFormatters.glucose(stats.avgXePerDay!)} ХЕ в день.',
          ),
          _DetailStatRow(
            icon: Icons.vaccines_outlined,
            iconColor: AppColors.accentBlue,
            title: 'Количество общего инсулина',
            subtitle: stats.avgTotalInsulinPerDay == null
                ? 'Нет данных об инсулине за период.'
                : 'Среднесуточное количество общего инсулина '
                    '(продлённый+короткий): '
                    '${StatisticsFormatters.glucose(stats.avgTotalInsulinPerDay!)} Ед.',
          ),
          _DetailStatRow(
            icon: Icons.vaccines_outlined,
            iconColor: AppColors.accentBlue,
            title: 'Болюсный инсулин',
            subtitle: stats.avgBolusInsulinPerDay == null
                ? 'Нет данных о коротком инсулине.'
                : 'Среднесуточное количество болюсного инсулина (короткий): '
                    '${StatisticsFormatters.glucose(stats.avgBolusInsulinPerDay!)} Ед.',
          ),
          _DetailStatRow(
            icon: Icons.vaccines_outlined,
            iconColor: AppColors.accentBlue,
            title: 'Базальный инсулин',
            subtitle: stats.avgBasalInsulinPerDay == null
                ? 'Нет данных о продлённом инсулине.'
                : 'Среднесуточное количество базального инсулина (продлённый): '
                    '${StatisticsFormatters.glucose(stats.avgBasalInsulinPerDay!)} Ед.',
          ),
        ],
      ),
    );
  }
}

class _DetailStatRow extends StatelessWidget {
  const _DetailStatRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.formNavy, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.formNavy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.formNavy.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
