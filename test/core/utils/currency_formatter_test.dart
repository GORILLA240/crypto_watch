import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('should format price with 2 decimal places for values >= 1', () {
      expect(CurrencyFormatter.formatPrice(45000.50), '\$45,000.50');
      expect(CurrencyFormatter.formatPrice(1.99), '\$1.99');
      expect(CurrencyFormatter.formatPrice(1000000), '\$1,000,000.00');
    });

    test('should format price with appropriate decimals for values < 1', () {
      expect(CurrencyFormatter.formatPrice(0.5), '\$0.50');
      expect(CurrencyFormatter.formatPrice(0.001234), '\$0.001234');
      expect(CurrencyFormatter.formatPrice(0.00001), '\$0.00001');
    });

    test('should format change percentage with sign', () {
      expect(CurrencyFormatter.formatChangePercent(2.5), '+2.5%');
      expect(CurrencyFormatter.formatChangePercent(-1.2), '-1.2%');
      expect(CurrencyFormatter.formatChangePercent(0), '0.0%');
    });

    test('should format market cap with abbreviations', () {
      expect(CurrencyFormatter.formatMarketCap(1500000000000), '\$1.50T');
      expect(CurrencyFormatter.formatMarketCap(850000000000), '\$850.00B');
      expect(CurrencyFormatter.formatMarketCap(5000000000), '\$5.00B');
      expect(CurrencyFormatter.formatMarketCap(500000000), '\$500.00M');
      expect(CurrencyFormatter.formatMarketCap(1000000), '\$1.00M');
      expect(CurrencyFormatter.formatMarketCap(500000), '\$500,000');
    });

    test('should handle zero and negative values', () {
      expect(CurrencyFormatter.formatPrice(0), '\$0.00');
      expect(CurrencyFormatter.formatMarketCap(0), '\$0');
    });
  });
}
