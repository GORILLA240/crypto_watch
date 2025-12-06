import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/optimized_text_widget.dart';
import '../../domain/entities/crypto_price.dart';

/// シングルビュー用の大きな価格表示ウィジェット
class LargePriceDisplay extends StatelessWidget {
  final CryptoPrice price;
  final String displayCurrency;

  const LargePriceDisplay({
    super.key,
    required this.price,
    this.displayCurrency = 'JPY',
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = price.change24h >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // シンボル
          OptimizedTextWidget(
            price.symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // 名前
          OptimizedTextWidget(
            price.name,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 24,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 32),
          // 価格
          OptimizedTextWidget(
            CurrencyFormatter.format(
              price.price,
              currency: displayCurrency,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            autoScale: true,
            minFontSize: 32.0,
          ),
          const SizedBox(height: 16),
          // 変動率
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: OptimizedTextWidget(
              CurrencyFormatter.formatChangePercent(price.change24h),
              style: TextStyle(
                color: changeColor,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 32),
          // 最終更新時刻
          OptimizedTextWidget(
            '最終更新: ${_formatTime(price.lastUpdated)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}秒前';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
