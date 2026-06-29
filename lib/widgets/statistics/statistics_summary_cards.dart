import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/statistics_formatters.dart';
import '../../models/glucose_statistics.dart';

/// Карточки: средняя глюкоза, число измерений, распределение по диапазону.
class StatisticsSummaryCards extends StatelessWidget {
  const StatisticsSummaryCards({super.key, required this.stats});

  final GlucoseStatistics stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _GradientMetricCard(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 60, 170, 160),
                    Color.fromARGB(255, 90, 200, 185),
                  ],
                ),
                value: stats.avgGlucose == null
                    ? '—'
                    : '${StatisticsFormatters.glucose(stats.avgGlucose!)} ммоль/л',
                caption: 'Средний уровень глюкозы',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradientMetricCard(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 70, 80, 100),
                    Color.fromARGB(255, 100, 110, 130),
                  ],
                ),
                value: '${stats.measurementCount} за период',
                caption: 'Количество измерений',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _RangeCard(
                count: stats.aboveRangeCount,
                percent: stats.aboveRangePercent,
                label: 'Измерений выше\nцелевого диапазона',
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 220, 90, 80),
                    Color.fromARGB(255, 240, 130, 110),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _RangeCard(
                count: stats.inRangeCount,
                percent: stats.inRangePercent,
                label: 'Измерений в\nцелевом диапазоне',
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 50, 160, 140),
                    Color.fromARGB(255, 80, 190, 170),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _RangeCard(
                count: stats.belowRangeCount,
                percent: stats.belowRangePercent,
                label: 'Измерений ниже\nцелевого диапазона',
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 70, 130, 200),
                    Color.fromARGB(255, 110, 170, 230),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Целевой диапазон: ${StatisticsFormatters.glucose(stats.targetLow)}–'
          '${StatisticsFormatters.glucose(stats.targetHigh)} ммоль/л',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.formNavy.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _GradientMetricCard extends StatelessWidget {
  const _GradientMetricCard({
    required this.gradient,
    required this.value,
    required this.caption,
  });

  final Gradient gradient;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeCard extends StatelessWidget {
  const _RangeCard({
    required this.count,
    required this.percent,
    required this.label,
    required this.gradient,
  });

  final int count;
  final double percent;
  final String label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 168,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            '(${StatisticsFormatters.percent(percent)} от измерений)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
