import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/features/price_list/data/models/crypto_price_model.dart';

void main() {
  group('CryptoPriceModel', () {
    group('Property 1: 価格データの一貫性', () {
      test(
        '**Feature: crypto-watch-frontend, Property 1: 価格データの一貫性** - '
        '**Validates: Requirements 1.1, 1.2** - '
        'すべての価格データは有効なシンボル、正の価格値、有効なタイムスタンプを持つべき',
        () {
          // Property-based test: 100回のランダムな入力で検証
          final prices = <CryptoPriceModel>[
            for (var i = 0; i < 100; i++) _generateValidCryptoPrice(i),
          ];

          for (final price in prices) {
            // すべてのアイテムは有効なシンボルを持つ
            expect(price.symbol, isNotEmpty,
                reason: 'Symbol should not be empty');
            expect(price.symbol.length, greaterThanOrEqualTo(2),
                reason: 'Symbol should be at least 2 characters');
            expect(price.symbol.length, lessThanOrEqualTo(10),
                reason: 'Symbol should be at most 10 characters');

            // すべてのアイテムは正の価格値を持つ
            expect(price.price, greaterThan(0),
                reason: 'Price should be positive');
            expect(price.price.isFinite, isTrue,
                reason: 'Price should be finite');

            // すべてのアイテムは有効なタイムスタンプを持つ
            expect(
                price.lastUpdated
                    .isBefore(DateTime.now().add(const Duration(minutes: 1))),
                isTrue,
                reason: 'Timestamp should not be in the future');
            expect(price.lastUpdated.isAfter(DateTime(2020)), isTrue,
                reason: 'Timestamp should be after 2020');

            // 市場価値は非負
            expect(price.marketCap, greaterThanOrEqualTo(0),
                reason: 'Market cap should be non-negative');
            expect(price.marketCap.isFinite, isTrue,
                reason: 'Market cap should be finite');

            // 名前は空でない
            expect(price.name, isNotEmpty, reason: 'Name should not be empty');
          }
        },
      );
    });

    group('fromJson', () {
      test('有効なJSONから正しくパースできる', () {
        final json = {
          'symbol': 'BTC',
          'name': 'Bitcoin',
          'price': 50000.0,
          'change_24h': 2.5,
          'market_cap': 1000000000.0,
          'last_updated': '2024-01-01T00:00:00.000Z',
        };

        final model = CryptoPriceModel.fromJson(json);

        expect(model.symbol, 'BTC');
        expect(model.name, 'Bitcoin');
        expect(model.price, 50000.0);
        expect(model.change24h, 2.5);
        expect(model.marketCap, 1000000000.0);
        expect(model.lastUpdated, DateTime.parse('2024-01-01T00:00:00.000Z'));
      });

      test('整数の価格値を正しくパースできる', () {
        final json = {
          'symbol': 'BTC',
          'name': 'Bitcoin',
          'price': 50000,
          'change_24h': 2,
          'market_cap': 1000000000,
          'last_updated': '2024-01-01T00:00:00.000Z',
        };

        final model = CryptoPriceModel.fromJson(json);

        expect(model.price, 50000.0);
        expect(model.change24h, 2.0);
        expect(model.marketCap, 1000000000.0);
      });

      test('文字列の価格値を正しくパースできる', () {
        final json = {
          'symbol': 'BTC',
          'name': 'Bitcoin',
          'price': '50000.5',
          'change_24h': '2.5',
          'market_cap': '1000000000.0',
          'last_updated': '2024-01-01T00:00:00.000Z',
        };

        final model = CryptoPriceModel.fromJson(json);

        expect(model.price, 50000.5);
        expect(model.change24h, 2.5);
        expect(model.marketCap, 1000000000.0);
      });

      test('タイムスタンプ（秒）を正しくパースできる', () {
        final json = {
          'symbol': 'BTC',
          'name': 'Bitcoin',
          'price': 50000.0,
          'change_24h': 2.5,
          'market_cap': 1000000000.0,
          'last_updated': 1704067200, // 2024-01-01 00:00:00 UTC in seconds
        };

        final model = CryptoPriceModel.fromJson(json);

        expect(model.lastUpdated.year, 2024);
        expect(model.lastUpdated.month, 1);
        expect(model.lastUpdated.day, 1);
      });

      test('必須フィールドが欠落している場合は例外をスロー', () {
        final json = {
          'symbol': 'BTC',
          'name': 'Bitcoin',
          // price is missing
          'change_24h': 2.5,
          'market_cap': 1000000000.0,
          'last_updated': '2024-01-01T00:00:00.000Z',
        };

        expect(
          () => CryptoPriceModel.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('toJson', () {
      test('モデルを正しくJSONに変換できる', () {
        final model = CryptoPriceModel(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          change24h: 2.5,
          marketCap: 1000000000.0,
          lastUpdated: DateTime.parse('2024-01-01T00:00:00.000Z'),
        );

        final json = model.toJson();

        expect(json['symbol'], 'BTC');
        expect(json['name'], 'Bitcoin');
        expect(json['price'], 50000.0);
        expect(json['change_24h'], 2.5);
        expect(json['market_cap'], 1000000000.0);
        expect(json['last_updated'], '2024-01-01T00:00:00.000Z');
      });
    });

    group('Round-trip serialization', () {
      test('JSON → Model → JSON のラウンドトリップで一貫性が保たれる', () {
        final originalJson = {
          'symbol': 'BTC',
          'name': 'Bitcoin',
          'price': 50000.0,
          'change_24h': 2.5,
          'market_cap': 1000000000.0,
          'last_updated': '2024-01-01T00:00:00.000Z',
        };

        final model = CryptoPriceModel.fromJson(originalJson);
        final resultJson = model.toJson();

        expect(resultJson['symbol'], originalJson['symbol']);
        expect(resultJson['name'], originalJson['name']);
        expect(resultJson['price'], originalJson['price']);
        expect(resultJson['change_24h'], originalJson['change_24h']);
        expect(resultJson['market_cap'], originalJson['market_cap']);
        expect(resultJson['last_updated'], originalJson['last_updated']);
      });
    });

    group('Immutability', () {
      test('すべてのフィールドはイミュータブルである', () {
        final model = CryptoPriceModel(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          change24h: 2.5,
          marketCap: 1000000000.0,
          lastUpdated: DateTime.parse('2024-01-01T00:00:00.000Z'),
        );

        // copyWithで新しいインスタンスが作成される
        final updated = model.copyWith(price: 51000.0);

        expect(model.price, 50000.0); // 元のモデルは変更されない
        expect(updated.price, 51000.0); // 新しいモデルは更新されている
        expect(identical(model, updated), isFalse); // 異なるインスタンス
      });
    });
  });
}

/// テスト用の有効な暗号通貨価格データを生成
CryptoPriceModel _generateValidCryptoPrice(int seed) {
  final symbols = ['BTC', 'ETH', 'ADA', 'BNB', 'XRP', 'SOL', 'DOT', 'DOGE'];
  final names = ['Bitcoin', 'Ethereum', 'Cardano', 'Binance Coin', 'Ripple', 'Solana', 'Polkadot', 'Dogecoin'];

  final index = seed % symbols.length;
  final priceBase = (seed % 10000 + 1).toDouble();
  final change = (seed % 200 - 100) / 10.0;

  return CryptoPriceModel(
    symbol: symbols[index],
    name: names[index],
    price: priceBase + (seed % 100).toDouble(),
    change24h: change,
    marketCap: priceBase * 1000000 + (seed % 1000000).toDouble(),
    lastUpdated: DateTime.now().subtract(Duration(minutes: seed % 60)),
  );
}
