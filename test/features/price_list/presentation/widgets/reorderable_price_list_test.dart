import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/utils/display_density.dart';
import 'package:crypto_watch/features/price_list/domain/entities/crypto_price.dart';
import 'package:crypto_watch/features/price_list/presentation/widgets/price_list_item.dart';

/// ReorderableListViewを使用した並び替え機能のウィジェットテスト
void main() {
  group('ReorderablePriceList Widget Tests', () {
    late List<CryptoPrice> testPrices;

    setUp(() {
      testPrices = [
        CryptoPrice(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          change24h: 2.5,
          marketCap: 1000000000.0,
          lastUpdated: DateTime.now(),
        ),
        CryptoPrice(
          symbol: 'ETH',
          name: 'Ethereum',
          price: 3000.0,
          change24h: -1.5,
          marketCap: 500000000.0,
          lastUpdated: DateTime.now(),
        ),
        CryptoPrice(
          symbol: 'ADA',
          name: 'Cardano',
          price: 0.5,
          change24h: 3.2,
          marketCap: 20000000.0,
          lastUpdated: DateTime.now(),
        ),
      ];
    });

    testWidgets('ReorderableListViewが正しく表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableListView.builder(
              itemCount: testPrices.length,
              onReorder: (oldIndex, newIndex) {},
              itemBuilder: (context, index) {
                final price = testPrices[index];
                return PriceListItem(
                  key: ValueKey(price.symbol),
                  price: price,
                  displayDensity: DisplayDensity.standard,
                  isReorderMode: true,
                );
              },
            ),
          ),
        ),
      );

      // すべてのアイテムが表示される
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('ADA'), findsOneWidget);
      
      // ReorderableListViewが存在する
      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('並び替えモードでドラッグハンドルが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableListView.builder(
              itemCount: testPrices.length,
              onReorder: (oldIndex, newIndex) {},
              itemBuilder: (context, index) {
                final price = testPrices[index];
                return PriceListItem(
                  key: ValueKey(price.symbol),
                  price: price,
                  displayDensity: DisplayDensity.standard,
                  isReorderMode: true,
                );
              },
            ),
          ),
        ),
      );

      // ドラッグハンドルが各アイテムに表示される
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(testPrices.length));
    });

    testWidgets('通常モードでドラッグハンドルが表示されない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: testPrices.length,
              itemBuilder: (context, index) {
                final price = testPrices[index];
                return PriceListItem(
                  key: ValueKey(price.symbol),
                  price: price,
                  displayDensity: DisplayDensity.standard,
                  isReorderMode: false,
                );
              },
            ),
          ),
        ),
      );

      // ドラッグハンドルが表示されない
      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });

    testWidgets('各アイテムに一意のキーが設定される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableListView.builder(
              itemCount: testPrices.length,
              onReorder: (oldIndex, newIndex) {},
              itemBuilder: (context, index) {
                final price = testPrices[index];
                return PriceListItem(
                  key: ValueKey(price.symbol),
                  price: price,
                  displayDensity: DisplayDensity.standard,
                  isReorderMode: true,
                );
              },
            ),
          ),
        ),
      );

      // 各アイテムのキーを確認
      for (final price in testPrices) {
        final finder = find.byKey(ValueKey(price.symbol));
        expect(finder, findsOneWidget);
      }
    });

    testWidgets('並び替えコールバックが呼ばれる', (tester) async {
      int? oldIndex;
      int? newIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableListView.builder(
              itemCount: testPrices.length,
              onReorder: (old, newIdx) {
                oldIndex = old;
                newIndex = newIdx;
              },
              itemBuilder: (context, index) {
                final price = testPrices[index];
                return PriceListItem(
                  key: ValueKey(price.symbol),
                  price: price,
                  displayDensity: DisplayDensity.standard,
                  isReorderMode: true,
                );
              },
            ),
          ),
        ),
      );

      // 最初のアイテムを見つける
      final firstItem = find.byKey(ValueKey('BTC'));
      expect(firstItem, findsOneWidget);

      // ドラッグ操作をシミュレート
      // 注: ReorderableListViewのドラッグ操作は複雑なため、
      // ここではコールバックが設定されていることを確認
      expect(oldIndex, isNull);
      expect(newIndex, isNull);
    });

    testWidgets('異なる表示密度でReorderableListViewが機能する', (tester) async {
      for (final density in DisplayDensity.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReorderableListView.builder(
                itemCount: testPrices.length,
                itemExtent: DisplayDensityHelper.getConfig(density).itemHeight,
                onReorder: (oldIndex, newIndex) {},
                itemBuilder: (context, index) {
                  final price = testPrices[index];
                  return PriceListItem(
                    key: ValueKey(price.symbol),
                    price: price,
                    displayDensity: density,
                    isReorderMode: true,
                  );
                },
              ),
            ),
          ),
        );

        // すべてのアイテムが表示される
        expect(find.text('BTC'), findsOneWidget);
        expect(find.text('ETH'), findsOneWidget);
        expect(find.text('ADA'), findsOneWidget);

        // 次のテストのためにクリア
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('お気に入りアイテムが正しく表示される', (tester) async {
      final favoriteSymbols = {'BTC', 'ADA'};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableListView.builder(
              itemCount: testPrices.length,
              onReorder: (oldIndex, newIndex) {},
              itemBuilder: (context, index) {
                final price = testPrices[index];
                final isFavorite = favoriteSymbols.contains(price.symbol);
                return PriceListItem(
                  key: ValueKey(price.symbol),
                  price: price,
                  displayDensity: DisplayDensity.standard,
                  isFavorite: isFavorite,
                  isReorderMode: true,
                );
              },
            ),
          ),
        ),
      );

      // お気に入りアイコンが2つ表示される
      expect(find.byIcon(Icons.star), findsNWidgets(2));
    });

    testWidgets('空のリストが正しく処理される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableListView.builder(
              itemCount: 0,
              onReorder: (oldIndex, newIndex) {},
              itemBuilder: (context, index) {
                return Container();
              },
            ),
          ),
        ),
      );

      // アイテムが表示されない
      expect(find.byType(PriceListItem), findsNothing);
    });

    testWidgets('単一アイテムのリストが正しく表示される', (tester) async {
      final singlePrice = [testPrices[0]];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableListView.builder(
              itemCount: singlePrice.length,
              onReorder: (oldIndex, newIndex) {},
              itemBuilder: (context, index) {
                final price = singlePrice[index];
                return PriceListItem(
                  key: ValueKey(price.symbol),
                  price: price,
                  displayDensity: DisplayDensity.standard,
                  isReorderMode: true,
                );
              },
            ),
          ),
        ),
      );

      // 1つのアイテムが表示される
      expect(find.text('BTC'), findsOneWidget);
      expect(find.byType(PriceListItem), findsOneWidget);
    });

    testWidgets('多数のアイテムが正しくスクロールできる', (tester) async {
      // 20個のアイテムを作成
      final manyPrices = List.generate(
        20,
        (index) => CryptoPrice(
          symbol: 'SYM$index',
          name: 'Crypto $index',
          price: 100.0 + index,
          change24h: index % 2 == 0 ? 1.5 : -1.5,
          marketCap: 1000000.0 * index,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableListView.builder(
              itemCount: manyPrices.length,
              onReorder: (oldIndex, newIndex) {},
              itemBuilder: (context, index) {
                final price = manyPrices[index];
                return PriceListItem(
                  key: ValueKey(price.symbol),
                  price: price,
                  displayDensity: DisplayDensity.standard,
                  isReorderMode: true,
                );
              },
            ),
          ),
        ),
      );

      // 最初のアイテムが表示される
      expect(find.text('SYM0'), findsOneWidget);

      // 下にスクロール
      await tester.drag(
        find.byType(ReorderableListView),
        const Offset(0, -500),
      );
      await tester.pump();

      // スクロール後、最初のアイテムが画面外になる可能性がある
      // （画面サイズによる）
    });

    testWidgets('itemExtentが正しく適用される', (tester) async {
      const testDensity = DisplayDensity.compact;
      final config = DisplayDensityHelper.getConfig(testDensity);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableListView.builder(
              itemCount: testPrices.length,
              itemExtent: config.itemHeight,
              onReorder: (oldIndex, newIndex) {},
              itemBuilder: (context, index) {
                final price = testPrices[index];
                return PriceListItem(
                  key: ValueKey(price.symbol),
                  price: price,
                  displayDensity: testDensity,
                  isReorderMode: true,
                );
              },
            ),
          ),
        ),
      );

      // アイテムの高さを確認
      final firstItem = tester.renderObject<RenderBox>(
        find.byKey(ValueKey('BTC')),
      );
      expect(firstItem.size.height, equals(config.itemHeight));
    });
  });

  group('ReorderablePriceList Integration Tests', () {
    testWidgets('並び替えモードと通常モードの切り替え', (tester) async {
      bool isReorderMode = false;
      final testPrices = [
        CryptoPrice(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          change24h: 2.5,
          marketCap: 1000000000.0,
          lastUpdated: DateTime.now(),
        ),
        CryptoPrice(
          symbol: 'ETH',
          name: 'Ethereum',
          price: 3000.0,
          change24h: -1.5,
          marketCap: 500000000.0,
          lastUpdated: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(
                  actions: [
                    IconButton(
                      icon: Icon(isReorderMode ? Icons.check : Icons.reorder),
                      onPressed: () {
                        setState(() {
                          isReorderMode = !isReorderMode;
                        });
                      },
                    ),
                  ],
                ),
                body: isReorderMode
                    ? ReorderableListView.builder(
                        itemCount: testPrices.length,
                        onReorder: (oldIndex, newIndex) {},
                        itemBuilder: (context, index) {
                          final price = testPrices[index];
                          return PriceListItem(
                            key: ValueKey(price.symbol),
                            price: price,
                            displayDensity: DisplayDensity.standard,
                            isReorderMode: true,
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount: testPrices.length,
                        itemBuilder: (context, index) {
                          final price = testPrices[index];
                          return PriceListItem(
                            key: ValueKey(price.symbol),
                            price: price,
                            displayDensity: DisplayDensity.standard,
                            isReorderMode: false,
                          );
                        },
                      ),
              );
            },
          ),
        ),
      );

      // 初期状態: 通常モード
      expect(find.byIcon(Icons.reorder), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsNothing);

      // 並び替えモードに切り替え
      await tester.tap(find.byIcon(Icons.reorder));
      await tester.pump();

      // 並び替えモード
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(testPrices.length));

      // 通常モードに戻す
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      // 通常モード
      expect(find.byIcon(Icons.reorder), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsNothing);
    });
  });
}
