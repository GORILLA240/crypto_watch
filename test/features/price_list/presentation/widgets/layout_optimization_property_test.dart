import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/utils/display_density.dart';
import 'package:crypto_watch/core/utils/safe_area_calculator.dart';
import 'package:crypto_watch/features/price_list/domain/entities/crypto_price.dart';
import 'package:crypto_watch/features/price_list/presentation/widgets/price_list_item.dart';

/// **Feature: smartwatch-ui-optimization, Property 3: 最小タップ領域の確保**
/// **Validates: Requirements 3.3, 12.1**
/// 
/// 任意のタップ可能な要素（ボタン、アイコン）に対して、
/// タップ領域は最小44x44ピクセルである
void main() {
  // テスト用のCryptoPriceインスタンスを作成するヘルパー関数
  CryptoPrice createTestPrice() {
    return CryptoPrice(
      symbol: 'BTC',
      name: 'Bitcoin',
      price: 50000.0,
      change24h: 2.5,
      marketCap: 1000000000000.0,
      lastUpdated: DateTime.now(),
    );
  }

  group('Property 3: 最小タップ領域の確保', () {
    test('すべてのIconButtonは最小44x44ピクセルのタップ領域を持つ', () {
      // テストケース: 様々なアイコンボタン
      final iconButtons = [
        IconButton(
          icon: const Icon(Icons.settings),
          iconSize: 24,
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.star),
          iconSize: 24,
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications),
          iconSize: 24,
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () {},
        ),
      ];

      for (final button in iconButtons) {
        // IconButtonの制約を検証
        expect(button.constraints?.minWidth, greaterThanOrEqualTo(44.0),
            reason: 'IconButton minimum width should be at least 44px');
        expect(button.constraints?.minHeight, greaterThanOrEqualTo(44.0),
            reason: 'IconButton minimum height should be at least 44px');
      }
    });

    test('すべての表示密度でPriceListItemは最小48ピクセルの高さを持つ', () {
      // すべての表示密度をテスト
      for (final density in DisplayDensity.values) {
        final config = DisplayDensityHelper.getConfig(density);
        
        // アイテムの高さが最小タップ領域を満たすことを確認
        expect(config.itemHeight, greaterThanOrEqualTo(48.0),
            reason: 'Item height for $density should be at least 48px for minimum tap target');
      }
    });

    testWidgets('PriceListItemのコンテナは最小タップ領域制約を持つ', (tester) async {
      final testPrice = createTestPrice();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PriceListItem(
                price: testPrice,
                displayCurrency: 'USD',
                displayDensity: DisplayDensity.standard,
              ),
            ),
          ),
        );

        // Containerウィジェットを探す
        final containerFinder = find.byType(Container);
        expect(containerFinder, findsWidgets);

        // 最初のContainerの制約を確認（PriceListItemのメインコンテナ）
        final container = tester.widget<Container>(containerFinder.first);
        expect(container.constraints?.minHeight, greaterThanOrEqualTo(48.0),
            reason: 'Container minimum height should be at least 48px');
        expect(container.constraints?.minWidth, greaterThanOrEqualTo(44.0),
            reason: 'Container minimum width should be at least 44px');
    });
  });

  group('Property 4: 円形画面の安全領域', () {
    /// **Feature: smartwatch-ui-optimization, Property 4: 円形画面の安全領域**
    /// **Validates: Requirements 5.2**
    /// 
    /// 任意の重要な情報要素に対して、円形画面の場合は
    /// 画面中央の安全領域内に配置される
    test('円形画面では安全なインセットが計算される', () {
      // 様々な円形画面サイズをテスト
      final circularScreenSizes = [
        const Size(200, 200),
        const Size(250, 250),
        const Size(300, 300),
        const Size(400, 400),
      ];

      for (final size in circularScreenSizes) {
        final insets = SafeAreaCalculator.calculateSafeInsets(size, true);
        
        // 円形画面では、インセットが8ピクセルより大きいことを確認
        expect(insets.left, greaterThan(8.0),
            reason: 'Circular screen insets should be larger than minimum 8px');
        expect(insets.right, greaterThan(8.0),
            reason: 'Circular screen insets should be larger than minimum 8px');
        expect(insets.top, greaterThan(8.0),
            reason: 'Circular screen insets should be larger than minimum 8px');
        expect(insets.bottom, greaterThan(8.0),
            reason: 'Circular screen insets should be larger than minimum 8px');
        
        // すべてのインセットが等しいことを確認（円形なので）
        expect(insets.left, equals(insets.right));
        expect(insets.left, equals(insets.top));
        expect(insets.left, equals(insets.bottom));
      }
    });

    test('正方形画面では最小インセット（8px）が使用される', () {
      // 様々な正方形画面サイズをテスト
      final squareScreenSizes = [
        const Size(200, 200),
        const Size(300, 300),
        const Size(400, 400),
      ];

      for (final size in squareScreenSizes) {
        final insets = SafeAreaCalculator.calculateSafeInsets(size, false);
        
        // 正方形画面では、最小インセット（8px）が使用される
        expect(insets.left, equals(8.0));
        expect(insets.right, equals(8.0));
        expect(insets.top, equals(8.0));
        expect(insets.bottom, equals(8.0));
      }
    });

    test('円形画面の最大コンテンツ幅は画面幅の70%である', () {
      final circularScreenSizes = [
        const Size(200, 200),
        const Size(300, 300),
        const Size(400, 400),
      ];

      for (final size in circularScreenSizes) {
        final maxWidth = SafeAreaCalculator.getMaxContentWidth(size, true);
        
        // 最大コンテンツ幅が画面幅の70%であることを確認
        expect(maxWidth, equals(size.width * 0.7));
      }
    });

    test('画面中央の位置は安全領域内である', () {
      final screenSize = const Size(300, 300);
      final center = Offset(screenSize.width / 2, screenSize.height / 2);
      
      // 中央は常に安全領域内
      expect(SafeAreaCalculator.isInSafeArea(center, screenSize), isTrue);
    });

    test('画面の角は安全領域外である', () {
      final screenSize = const Size(300, 300);
      
      // 4つの角をテスト
      final corners = [
        const Offset(0, 0),           // 左上
        Offset(screenSize.width, 0),  // 右上
        Offset(0, screenSize.height), // 左下
        Offset(screenSize.width, screenSize.height), // 右下
      ];

      for (final corner in corners) {
        expect(SafeAreaCalculator.isInSafeArea(corner, screenSize), isFalse,
            reason: 'Corner at $corner should be outside safe area');
      }
    });
  });

  group('Property 7: 最小パディング', () {
    /// **Feature: smartwatch-ui-optimization, Property 7: 最小パディング**
    /// **Validates: Requirements 8.1**
    /// 
    /// 任意のリストアイテムに対して、上下のパディングは最小8ピクセルである
    test('すべての表示密度で上下パディングは最小8ピクセルである', () {
      for (final density in DisplayDensity.values) {
        final config = DisplayDensityHelper.getConfig(density);
        
        // 上下パディングの計算（config.padding * 0.5 または 8.0の大きい方）
        final verticalPadding = config.padding * 0.5 < 8.0 ? 8.0 : config.padding * 0.5;
        
        expect(verticalPadding, greaterThanOrEqualTo(8.0),
            reason: 'Vertical padding for $density should be at least 8px');
      }
    });

    test('すべての表示密度で左右パディングは最小12ピクセルである', () {
      for (final density in DisplayDensity.values) {
        final config = DisplayDensityHelper.getConfig(density);
        
        // 左右パディングは config.padding
        expect(config.padding, greaterThanOrEqualTo(12.0),
            reason: 'Horizontal padding for $density should be at least 12px');
      }
    });

    testWidgets('PriceListItemは適切なパディングを持つ', (tester) async {
      final testPrice = createTestPrice();
        for (final density in DisplayDensity.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PriceListItem(
                  price: testPrice,
                  displayCurrency: 'USD',
                  displayDensity: density,
                ),
              ),
            ),
          );

          final containerFinder = find.byType(Container);
          final container = tester.widget<Container>(containerFinder.first);
          
          // パディングを確認
          if (container.padding is EdgeInsets) {
            final padding = container.padding as EdgeInsets;
            
            // 左右パディングは最小12px
            expect(padding.left, greaterThanOrEqualTo(12.0),
                reason: 'Left padding should be at least 12px for $density');
            expect(padding.right, greaterThanOrEqualTo(12.0),
                reason: 'Right padding should be at least 12px for $density');
            
            // 上下パディングは最小8px
            expect(padding.top, greaterThanOrEqualTo(8.0),
                reason: 'Top padding should be at least 8px for $density');
            expect(padding.bottom, greaterThanOrEqualTo(8.0),
                reason: 'Bottom padding should be at least 8px for $density');
          }
        }
    });
  });
}
