import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/price_detail.dart';

/// ミニチャートウィジェット
class MiniChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final String period;

  const MiniChart({
    super.key,
    required this.data,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'データがありません',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.price);
    }).toList();

    final minY = data.map((d) => d.price).reduce((a, b) => a < b ? a : b);
    final maxY = data.map((d) => d.price).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    final isPositive = data.last.price >= data.first.price;
    final lineColor = isPositive ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: minY - padding,
              maxY: maxY + padding,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withOpacity(0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.grey[800]!,
                  tooltipRoundedRadius: 8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
