import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';

/// 価格統計ウィジェット
class PriceStats extends StatelessWidget {
  final double high24h;
  final double low24h;
  final double volume24h;
  final String displayCurrency;

  const PriceStats({
    super.key,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    this.displayCurrency = 'JPY',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildStatRow(
            '24時間高値',
            CurrencyFormatter.format(high24h, currency: displayCurrency),
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            '24時間安値',
            CurrencyFormatter.format(low24h, currency: displayCurrency),
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            '24時間出来高',
            CurrencyFormatter.formatVolume(volume24h),
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
