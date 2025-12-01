import 'package:flutter/material.dart';
import '../../domain/entities/app_settings.dart';

/// 通貨選択ウィジェット
class CurrencySelector extends StatelessWidget {
  final Currency selectedCurrency;
  final Function(Currency) onCurrencyChanged;

  const CurrencySelector({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '表示通貨',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...Currency.values.map((currency) {
          return RadioListTile<Currency>(
            title: Text(
              _getCurrencyLabel(currency),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            value: currency,
            groupValue: selectedCurrency,
            onChanged: (value) {
              if (value != null) {
                onCurrencyChanged(value);
              }
            },
            activeColor: Colors.blue,
          );
        }),
      ],
    );
  }

  String _getCurrencyLabel(Currency currency) {
    switch (currency) {
      case Currency.jpy:
        return '日本円 (¥)';
      case Currency.usd:
        return '米ドル (\$)';
      case Currency.eur:
        return 'ユーロ (€)';
      case Currency.btc:
        return 'ビットコイン (₿)';
    }
  }
}
