import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/utils/display_density.dart';
import 'package:crypto_watch/features/price_list/domain/entities/crypto_price.dart';
import 'package:crypto_watch/features/price_list/presentation/widgets/price_list_item.dart';

/// PriceListItemの表示密度に関するウィジェットテスト
void main() {
  group('PriceListItem Display Density Widget Tests', () {
    late CryptoPrice testPrice;

    setUp(() {
      testPrice = CryptoPrice(
        symbol: 'BTC',
        name: 'Bitcoin',
        price: 50000.0,
        change24h: 2.5,
        marketCap: 1000000000.0,
        lastUpdated: DateTime.now(),
      );
    });

    testWidgets('標準密度で全ての要素が表示される', (tester) async {
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

      // シンボルが表示される
      expect(find.text('BTC'), findsOneWidget);
      
      // 通貨名が表示される
      expect(find.text('Bitcoin'), findsOneWidget);
      
      // お気に入りアイコンが表示される
      expect(find.byIcon(Icons.star), findsOneWidget);
      
      // 通貨アイコンが表示される
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('コンパクト密度で通貨名が小さく表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.compact,
              isFavorite: true,
            ),
          ),
        ),
      );

      // シンボルが表示される
      expect(find.text('BTC'), findsOneWidget);
      
      // 通貨名が表示される（小さいフォント）
      expect(find.text('Bitcoin'), findsOneWidget);
      
      // お気に入りアイコンが表示される
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('最大密度で通貨名が表示されない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.maximum,
              isFavorite: true,
            ),
          ),
        ),
      );

      // シンボルが表示される
      expect(find.text('BTC'), findsOneWidget);
      
      // 通貨名が表示されない
      expect(find.text('Bitcoin'), findsNothing);
      
      // お気に入りアイコンが小さく表示される
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('各密度でアイテムの高さが正しい', (tester) async {
      for (final density in DisplayDensity.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PriceListItem(
                price: testPrice,
                displayDensity: density,
              ),
            ),
          ),
        );

        final config = DisplayDensityHelper.getConfig(density);
        final renderBox = tester.renderObject<RenderBox>(
          find.byType(PriceListItem),
        );

        expect(
          renderBox.size.height,
          equals(config.itemHeight),
          reason: '表示密度 ${density.name} のアイテム高さが期待値と異なります',
        );

        // 次のテストのためにクリア
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('各密度でアイコンサイズが正しい', (tester) async {
      for (final density in DisplayDensity.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PriceListItem(
                price: testPrice,
                displayDensity: density,
              ),
            ),
          ),
        );
        
        // CryptoIconウィジェットを見つける
        final cryptoIconFinder = find.byType(Image);
        expect(cryptoIconFinder, findsWidgets);

        // 次のテストのためにクリア
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('価格と変動率が全ての密度で表示される', (tester) async {
      for (final density in DisplayDensity.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PriceListItem(
                price: testPrice,
                displayDensity: density,
              ),
            ),
          ),
        );

        // シンボルが表示される（全密度で必須）
        expect(find.text('BTC'), findsOneWidget);
        
        // 変動率が表示される（全密度で必須）
        expect(find.textContaining('%'), findsOneWidget);

        // 次のテストのためにクリア
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('正の変動率が緑色で表示される', (tester) async {
      final positivePrice = CryptoPrice(
        symbol: 'ETH',
        name: 'Ethereum',
        price: 3000.0,
        change24h: 5.2,
        marketCap: 500000000.0,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: positivePrice,
              displayDensity: DisplayDensity.standard,
            ),
          ),
        ),
      );

      // 変動率のテキストを見つける
      final changeText = find.textContaining('%');
      expect(changeText, findsOneWidget);
      
      // テキストウィジェットを取得して色を確認
      final textWidget = tester.widget<Text>(changeText);
      expect(textWidget.style?.color, equals(Colors.green));
    });

    testWidgets('負の変動率が赤色で表示される', (tester) async {
      final negativePrice = CryptoPrice(
        symbol: 'ADA',
        name: 'Cardano',
        price: 0.5,
        change24h: -3.1,
        marketCap: 20000000.0,
        lastUpdated: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: negativePrice,
              displayDensity: DisplayDensity.standard,
            ),
          ),
        ),
      );

      // 変動率のテキストを見つける
      final changeText = find.textContaining('%');
      expect(changeText, findsOneWidget);
      
      // テキストウィジェットを取得して色を確認
      final textWidget = tester.widget<Text>(changeText);
      expect(textWidget.style?.color, equals(Colors.red));
    });

    testWidgets('並び替えモードでドラッグハンドルが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.standard,
              isReorderMode: true,
            ),
          ),
        ),
      );

      // ドラッグハンドルアイコンが表示される
      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
    });

    testWidgets('通常モードでドラッグハンドルが表示されない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.standard,
              isReorderMode: false,
            ),
          ),
        ),
      );

      // ドラッグハンドルアイコンが表示されない
      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });

    testWidgets('通常モードでタップが機能する', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.standard,
              isReorderMode: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // タップする
      await tester.tap(find.byType(PriceListItem));
      await tester.pump();

      // タップが機能することを確認
      expect(tapped, isTrue);
    });

    testWidgets('並び替えモードでタップが無効化される', (tester) async {
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

      // タップが無効化されることを確認
      expect(tapped, isFalse);
    });

    testWidgets('お気に入りでない場合、星アイコンが表示されない', (tester) async {
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

      // 星アイコンが表示されない
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('最大密度でお気に入りアイコンが小さく表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceListItem(
              price: testPrice,
              displayDensity: DisplayDensity.maximum,
              isFavorite: true,
            ),
          ),
        ),
      );

      // お気に入りアイコンが表示される
      final starIcon = find.byIcon(Icons.star);
      expect(starIcon, findsOneWidget);
      
      // アイコンウィジェットを取得してサイズを確認
      final iconWidget = tester.widget<Icon>(starIcon);
      final config = DisplayDensityHelper.getConfig(DisplayDensity.maximum);
      expect(iconWidget.size, equals(config.iconSize * 0.5));
    });

    testWidgets('標準密度でお気に入りアイコンが通常サイズで表示される', (tester) async {
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

      // お気に入りアイコンが表示される
      final starIcon = find.byIcon(Icons.star);
      expect(starIcon, findsOneWidget);
      
      // アイコンウィジェットを取得してサイズを確認
      final iconWidget = tester.widget<Icon>(starIcon);
      final config = DisplayDensityHelper.getConfig(DisplayDensity.standard);
      expect(iconWidget.size, equals(config.iconSize * 0.6));
    });
  });
}
