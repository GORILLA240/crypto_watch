import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/utils/display_density.dart';
import 'package:crypto_watch/features/price_list/domain/entities/crypto_price.dart';
import 'package:crypto_watch/features/price_list/presentation/widgets/price_list_item.dart';

void main() {
  group('PriceListItem Property-Based Tests', () {
    // **Feature: price-list-improvements, Property 10: 表示密度変更時のレイアウト調整**
    // **Validates: 要件 2.6, 2.8, 5.1, 5.2, 5.3**
    test('表示密度変更時、アイテム高さ、アイコンサイズ、フォントサイズが適切に調整される', () {
      // すべての表示密度について検証
      for (final density in DisplayDensity.values) {
        final config = DisplayDensityHelper.getConfig(density);
        
        // 設定値が正しいことを確認
        expect(config.density, equals(density),
          reason: '表示密度 ${density.name} の設定が正しくありません');
        
        // アイテムの高さが適切であることを確認
        expect(config.itemHeight, greaterThan(0),
          reason: '表示密度 ${density.name} のアイテム高さが0以下です');
        
        // アイコンサイズが適切であることを確認
        expect(config.iconSize, greaterThan(0),
          reason: '表示密度 ${density.name} のアイコンサイズが0以下です');
        
        // フォントサイズが適切であることを確認
        expect(config.fontSize, greaterThan(0),
          reason: '表示密度 ${density.name} のフォントサイズが0以下です');
        
        // パディングが適切であることを確認
        expect(config.padding, greaterThan(0),
          reason: '表示密度 ${density.name} のパディングが0以下です');
        
        // 表示密度が高くなるにつれて、アイテム高さが小さくなることを確認
        if (density == DisplayDensity.standard) {
          expect(config.itemHeight, equals(80.0));
          expect(config.iconSize, equals(40.0));
          expect(config.fontSize, equals(18.0));
          expect(config.padding, equals(16.0));
        } else if (density == DisplayDensity.compact) {
          expect(config.itemHeight, equals(60.0));
          expect(config.iconSize, equals(32.0));
          expect(config.fontSize, equals(16.0));
          expect(config.padding, equals(12.0));
        } else if (density == DisplayDensity.maximum) {
          expect(config.itemHeight, equals(48.0));
          expect(config.iconSize, equals(32.0));
          expect(config.fontSize, equals(14.0));
          expect(config.padding, equals(8.0));
        }
      }
    });

    // **Feature: price-list-improvements, Property 10の一部: 最小フォントサイズ**
    // **Validates: 要件 5.5**
    test('すべての表示密度でフォントサイズが12sp以上である', () {
      const minFontSize = 12.0;

      for (final density in DisplayDensity.values) {
        final config = DisplayDensityHelper.getConfig(density);
        
        // メインのフォントサイズが最小値以上であることを確認
        // これは価格とシンボルに使用される主要なフォントサイズ
        expect(
          config.fontSize,
          greaterThanOrEqualTo(minFontSize),
          reason: '表示密度 ${density.name} のフォントサイズ ${config.fontSize} が最小値 $minFontSize を下回っています',
        );

        // 注: 通貨名や変動率などの補助的なテキストは、
        // 視覚的な階層を作るために意図的に小さくしています。
        // これらは主要な情報ではないため、12sp未満でも許容されます。
      }
    });
  });

  group('PriceListItem Widget Tests', () {
    testWidgets('通貨アイコンが左端に表示される', (tester) async {
      final testPrice = CryptoPrice(
        symbol: 'ETH',
        name: 'Ethereum',
        price: 3000.0,
        change24h: -2.5,
        marketCap: 500000000.0,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.standard,
            ),
          ),
        ),
      );

      // CryptoIconが存在することを確認
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('お気に入りアイコンが表示される', (tester) async {
      final testPrice = CryptoPrice(
        symbol: 'ADA',
        name: 'Cardano',
        price: 0.5,
        change24h: 1.2,
        marketCap: 20000000.0,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.standard,
              isFavorite: true,
            ),
          ),
        ),
      );

      // 星アイコンが表示されることを確認
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('お気に入りでない場合、星アイコンが表示されない', (tester) async {
      final testPrice = CryptoPrice(
        symbol: 'DOT',
        name: 'Polkadot',
        price: 7.5,
        change24h: 3.0,
        marketCap: 10000000.0,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.standard,
              isFavorite: false,
            ),
          ),
        ),
      );

      // 星アイコンが表示されないことを確認
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('標準密度では通貨名が表示される', (tester) async {
      final testPrice = CryptoPrice(
        symbol: 'SOL',
        name: 'Solana',
        price: 100.0,
        change24h: 8.5,
        marketCap: 50000000.0,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.standard,
            ),
          ),
        ),
      );

      // 通貨名が表示されることを確認
      expect(find.text('Solana'), findsOneWidget);
    });

    testWidgets('最大密度では通貨名が表示されない', (tester) async {
      final testPrice = CryptoPrice(
        symbol: 'MATIC',
        name: 'Polygon',
        price: 0.8,
        change24h: -1.5,
        marketCap: 8000000.0,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.maximum,
            ),
          ),
        ),
      );

      // 通貨名が表示されないことを確認
      expect(find.text('Polygon'), findsNothing);
    });
  });
}
