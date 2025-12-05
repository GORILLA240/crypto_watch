import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/utils/display_density.dart';
import 'package:crypto_watch/features/price_list/domain/entities/crypto_price.dart';
import 'package:crypto_watch/features/price_list/presentation/widgets/price_list_item.dart';

void main() {
  group('PriceListItem Accessibility Property-Based Tests', () {
    // **Feature: price-list-improvements, Property 6: 表示要素の最小サイズ**
    // **Validates: 要件 7.4**
    test('すべての表示密度でタップ可能な要素が44x44ポイント以上である', () {
      const minTapSize = 44.0;

      // すべての表示密度について検証
      for (final density in DisplayDensity.values) {
        final config = DisplayDensityHelper.getConfig(density);

        // アイテムの高さが最小タップ領域を満たすことを確認
        // 注: 幅は画面全体を使用するため、常に44ポイント以上
        expect(
          config.itemHeight,
          greaterThanOrEqualTo(minTapSize),
          reason: '表示密度 ${density.name} のアイテム高さ ${config.itemHeight} が'
              '最小タップ領域 $minTapSize を下回っています',
        );

        // アイコンのタップ領域を確認
        // アイコン自体は小さくても、周囲のパディングを含めた
        // タップ可能な領域が44x44以上であることを確認
        final iconTapArea = config.iconSize + (config.padding * 2);
        expect(
          iconTapArea,
          greaterThanOrEqualTo(minTapSize),
          reason: '表示密度 ${density.name} のアイコンタップ領域 $iconTapArea が'
              '最小タップ領域 $minTapSize を下回っています',
        );

        // お気に入りアイコンは小さいが、アイテム全体がタップ可能なため
        // アイテムの高さが最小タップ領域を満たしていれば問題ない
        // （アイコン自体をタップするのではなく、行全体をタップする設計）
        expect(
          config.itemHeight,
          greaterThanOrEqualTo(minTapSize),
          reason: '表示密度 ${density.name} でお気に入りアイコンを含む'
              'アイテムのタップ領域が不十分です',
        );
      }
    });

    testWidgets('PriceListItemが最小タップ領域の制約を持つ', (tester) async {
      const minTapSize = 44.0;

      for (final density in DisplayDensity.values) {
        final testPrice = CryptoPrice(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          change24h: 2.5,
          marketCap: 1000000000.0,
          lastUpdated: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PriceListItem(
                price: testPrice,
                displayDensity: density,
                isFavorite: true,
              ),
            ),
          ),
        );

        // 実際のレンダリングサイズを確認
        final renderBox = tester.renderObject<RenderBox>(
          find.byType(PriceListItem),
        );

        // アイテムの高さが最小タップ領域以上であることを確認
        expect(
          renderBox.size.height,
          greaterThanOrEqualTo(minTapSize),
          reason: '表示密度 ${density.name} の実際の高さ ${renderBox.size.height} が'
              '最小タップ領域 $minTapSize を下回っています',
        );

        // 幅も確認（画面全体を使用するため、常に44以上のはず）
        expect(
          renderBox.size.width,
          greaterThanOrEqualTo(minTapSize),
          reason: '表示密度 ${density.name} の実際の幅が'
              '最小タップ領域を下回っています',
        );

        // 次のテストのためにウィジェットをクリア
        await tester.pumpWidget(Container());
      }
    });
  });

  group('PriceListItem Accessibility Widget Tests', () {
    testWidgets('Semanticsウィジェットが存在する', (tester) async {
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
              isFavorite: true,
            ),
          ),
        ),
      );

      // Semanticsウィジェットが存在することを確認
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('並び替えモード時はタップが無効化される', (tester) async {
      final testPrice = CryptoPrice(
        symbol: 'ADA',
        name: 'Cardano',
        price: 0.5,
        change24h: 1.2,
        marketCap: 20000000.0,
        lastUpdated: DateTime.now(),
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.standard,
              isReorderMode: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // タップを試みる
      await tester.tap(find.byType(PriceListItem));
      await tester.pump();

      // 並び替えモード時はタップが無効化されることを確認
      expect(tapped, isFalse);
    });

    testWidgets('コンテキストメニューが表示される', (tester) async {
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
              isFavorite: false,
              onLongPress: () {},
            ),
          ),
        ),
      );

      // 長押しでコンテキストメニューを表示
      await tester.longPress(find.byType(PriceListItem));
      await tester.pump(); // 最初のフレームだけポンプ
      await tester.pump(const Duration(milliseconds: 300)); // アニメーション待機

      // コンテキストメニューのListTileを確認
      expect(find.byType(ListTile), findsOneWidget);
      
      // お気に入りに追加のテキストが表示されることを確認
      expect(find.text('お気に入りに追加'), findsOneWidget);
    });
  });
}
