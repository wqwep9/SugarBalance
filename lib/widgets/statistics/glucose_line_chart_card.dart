import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/statistics_formatters.dart';
import '../../models/glucose_statistics.dart';

/// График глюкозы с горизонтальной прокруткой; ось Y 0–18 фиксирована справа.
class GlucoseLineChartCard extends StatelessWidget {
  const GlucoseLineChartCard({
    super.key,
    required this.stats,
    required this.singleDay,
  });

  final GlucoseStatistics stats;
  final bool singleDay;

  static const double _chartHeight = 220;
  static const double _yAxisWidth = 38;

  /// Ширина прокручиваемой области графика.
  double _scrollableWidth(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).width - 32 - _yAxisWidth;
    if (stats.chartPoints.isEmpty) return viewport;

    final byHours = stats.maxChartHours * (singleDay ? 52.0 : 32.0);
    final byPoints = stats.chartPoints.length * 28.0;
    return math.max(viewport, math.max(byHours, byPoints));
  }

  @override
  Widget build(BuildContext context) {
    final scrollable = _scrollableWidth(context) >
        MediaQuery.sizeOf(context).width - 32 - _yAxisWidth;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromARGB(255, 220, 228, 240),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (scrollable && stats.chartPoints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                'Прокрутите график влево-вправо',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.formNavy.withValues(alpha: 0.65),
                    ),
              ),
            ),
          SizedBox(
            height: _chartHeight,
            child: stats.chartPoints.isEmpty
                ? Center(
                    child: Text(
                      'Нет измерений глюкозы за период',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.formNavy.withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          child: SizedBox(
                            width: _scrollableWidth(context),
                            height: _chartHeight,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 12, 4, 8),
                              child: LineChart(_buildData(showRightAxis: false)),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 8, 28),
                        child: _FixedYAxis(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildData({required bool showRightAxis}) {
    final spots = stats.chartPoints
        .map((p) => FlSpot(p.hoursFromStart, p.valueMmol))
        .toList();

    const intervalY = 2.0;
    final maxX = stats.maxChartHours;

    return LineChartData(
      minX: 0,
      maxX: maxX,
      minY: 0,
      maxY: 18,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: intervalY,
        verticalInterval: singleDay ? 4 : (maxX / 8).clamp(2, 48),
        getDrawingHorizontalLine: (_) => FlLine(
          color: const Color.fromARGB(255, 230, 235, 245),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (_) => FlLine(
          color: const Color.fromARGB(255, 230, 235, 245),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        leftTitles: const AxisTitles(),
        rightTitles: showRightAxis
            ? AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: intervalY,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value > 18) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      StatisticsFormatters.glucose(value),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.inputHint,
                      ),
                    );
                  },
                ),
              )
            : const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: singleDay ? 3 : (maxX / 10).clamp(1, 48),
            getTitlesWidget: (value, meta) {
              final time = stats.from.add(
                Duration(minutes: (value * 60).round()),
              );
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  StatisticsFormatters.chartBottomLabel(
                    time,
                    singleDay: singleDay,
                  ),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.inputHint,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: stats.targetLow,
            color: AppColors.secondary.withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: [6, 4],
          ),
          HorizontalLine(
            y: stats.targetHigh,
            color: const Color.fromARGB(255, 230, 120, 100)
                .withValues(alpha: 0.7),
            strokeWidth: 1,
            dashArray: [6, 4],
          ),
        ],
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touched) {
            return touched.map((bar) {
              final i = bar.spotIndex;
              if (i < 0 || i >= stats.chartPoints.length) return null;
              final p = stats.chartPoints[i];
              return LineTooltipItem(
                '${StatisticsFormatters.chartBottomLabel(p.time, singleDay: singleDay)}\n'
                '${StatisticsFormatters.glucose(p.valueMmol)} ммоль/л',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: AppColors.secondary,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              final v = spot.y;
              Color color;
              if (v < stats.targetLow) {
                color = const Color.fromARGB(255, 90, 160, 220);
              } else if (v > stats.targetHigh) {
                color = const Color.fromARGB(255, 230, 100, 90);
              } else {
                color = AppColors.secondary;
              }
              return FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.secondary.withValues(alpha: 0.15),
                AppColors.secondary.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Фиксированная ось Y (не прокручивается вместе с графиком).
class _FixedYAxis extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const values = [18.0, 16.0, 14.0, 12.0, 10.0, 8.0, 6.0, 4.0, 2.0, 0.0];
    return SizedBox(
      width: GlucoseLineChartCard._yAxisWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values
            .map(
              (v) => Text(
                StatisticsFormatters.glucose(v),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.inputHint,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
