import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/crypto_price.dart';

/// 価格リストアイテムウィジェット
class PriceListItem extends StatelessWidget {
  final CryptoPrice price;
  final VoidCallback? onTap;
  final String displayCurrency;

  const PriceListItem({
    super.key,
    required this.price,
    this.onTap,
    this.displayCurrency = 'JPY',
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = price.change24h >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    // 価格をUSDから指定通貨に換算
    // BTC換算は現時点では未対応（BTC価格の取得が必要）
    final effectiveCurrency = displayCurrency == 'BTC' ? 'USD' : displayCurrency;
    final convertedPrice = CurrencyFormatter.convert(
      price.price,
      fromCurrency: 'USD',
      toCurrency: effectiveCurrency,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // シンボルと名前
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price.symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price.name,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // 価格
            Expanded(
              flex: 2,
              child: Text(
                CurrencyFormatter.format(
                  convertedPrice,
                  currency: effectiveCurrency,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 16),
            // 変動率
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  CurrencyFormatter.formatChangePercent(price.change24h),
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
