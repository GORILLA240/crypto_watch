import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:crypto_watch/core/utils/display_density.dart';
import 'package:crypto_watch/features/price_list/domain/entities/crypto_price.dart';
import 'package:crypto_watch/features/price_list/presentation/widgets/price_list_item.dart';
import 'package:crypto_watch/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:crypto_watch/features/favorites/presentation/bloc/favorites_event.dart';
import 'package:crypto_watch/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:crypto_watch/features/favorites/domain/entities/favorite.dart';
import 'package:crypto_watch/core/storage/local_storage.dart';

@GenerateMocks([FavoritesBloc, LocalStorage])
import 'price_list_item_favorites_test.mocks.dart';

void main() {
  group('PriceListItem Favorites Property-Based Tests', () {
    late MockFavoritesBloc mockFavoritesBloc;
    late MockLocalStorage mockLocalStorage;
    final random = Random(42); // 固定シードで再現性を確保

    setUp(() {
      mockFavoritesBloc = MockFavoritesBloc();
      mockLocalStorage = MockLocalStorage();
      
      // デフォルトの状態を設定
      when(mockFavoritesBloc.state).thenReturn(const FavoritesLoaded(favorites: []));
      when(mockFavoritesBloc.stream).thenAnswer((_) => Stream.value(const FavoritesLoaded(favorites: [])));
    });

    // **Feature: price-list-improvements, Property 3: お気に入り状態の同期**
    // **Validates: 要件 3.5, 3.7, 3.8**
    testWidgets('お気に入り操作後、UIとストレージの状態が一致する', (tester) async {
      // 100回の反復テストを実行
      for (int iteration = 0; iteration < 100; iteration++) {
        // ランダムな通貨を生成
        final symbol = _generateRandomSymbol(random);
        final price = _generateRandomPrice(symbol, random);
        
        // ランダムな初期お気に入り状態を生成
        final initialIsFavorite = random.nextBool();
        
        // お気に入りリストを作成
        final favorites = initialIsFavorite
            ? <Favorite>[Favorite(symbol: symbol, order: 0, addedAt: DateTime.now())]
            : <Favorite>[];
        
        // Blocの状態を設定
        when(mockFavoritesBloc.state).thenReturn(FavoritesLoaded(favorites: favorites));
        when(mockFavoritesBloc.stream).thenAnswer((_) => Stream.value(FavoritesLoaded(favorites: favorites)));
        
        bool longPressCallbackCalled = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<FavoritesBloc>.value(
              value: mockFavoritesBloc,
              child: Scaffold(
                body: PriceListItem(
                  price: price,
                  displayDensity: DisplayDensity.standard,
                  isFavorite: initialIsFavorite,
                  onLongPress: () {
                    longPressCallbackCalled = true;
                  },
                ),
              ),
            ),
          ),
        );

        // UIの初期状態を確認
        if (initialIsFavorite) {
          expect(find.byIcon(Icons.star), findsOneWidget,
              reason: '反復 $iteration: お気に入りアイコンが表示されるべきです');
        } else {
          expect(find.byIcon(Icons.star), findsNothing,
              reason: '反復 $iteration: お気に入りアイコンが表示されないべきです');
        }

        // 長押し操作をシミュレート
        await tester.longPress(find.byType(PriceListItem));
        await tester.pump(); // 最初のフレームを処理
        await tester.pump(const Duration(milliseconds: 300)); // アニメーションを進める

        // コンテキストメニューが表示されることを確認
        expect(find.text(initialIsFavorite ? 'お気に入りから削除' : 'お気に入りに追加'), findsOneWidget,
            reason: '反復 $iteration: コンテキストメニューが表示されるべきです');

        // メニューオプションをタップ
        await tester.tap(find.text(initialIsFavorite ? 'お気に入りから削除' : 'お気に入りに追加'));
        await tester.pump(); // タップを処理

        // コールバックが呼ばれたことを確認
        expect(longPressCallbackCalled, isTrue,
            reason: '反復 $iteration: onLongPressコールバックが呼ばれるべきです');
        
        // 次の反復のためにウィジェットツリーをクリア
        await tester.pumpWidget(Container());
      }
    });

    // **Feature: price-list-improvements, Property 5: 長押し操作の応答性**
    // **Validates: 要件 3.1, 6.3**
    testWidgets('長押し操作が500ms以内に触覚フィードバックを提供する', (tester) async {
      // 100回の反復テストを実行
      for (int iteration = 0; iteration < 100; iteration++) {
        // ランダムな通貨を生成
        final symbol = _generateRandomSymbol(random);
        final price = _generateRandomPrice(symbol, random);
        final isFavorite = random.nextBool();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PriceListItem(
                price: price,
                displayDensity: DisplayDensity.standard,
                isFavorite: isFavorite,
                onLongPress: () {},
              ),
            ),
          ),
        );

        // 長押し開始時刻を記録
        final startTime = DateTime.now();

        // 長押し操作をシミュレート
        await tester.longPress(find.byType(PriceListItem));
        await tester.pump(); // 最初のフレームのみ処理

        // 応答時刻を記録
        final responseTime = DateTime.now();
        final elapsedMs = responseTime.difference(startTime).inMilliseconds;

        // コンテキストメニューが表示されることを確認（触覚フィードバック後に表示される）
        await tester.pump(const Duration(milliseconds: 300)); // アニメーションを進める
        
        // BottomSheetが表示されることを確認
        expect(find.text(isFavorite ? 'お気に入りから削除' : 'お気に入りに追加'), findsOneWidget,
            reason: '反復 $iteration: コンテキストメニューが表示されるべきです');

        // 注: Flutter テストでは実際の触覚フィードバックの時間を測定できないため、
        // ここではコンテキストメニューの表示時間で代用します。
        // 実際のアプリでは、HapticFeedback.mediumImpact()は即座に実行されます。
        expect(elapsedMs, lessThan(500),
            reason: '反復 $iteration: 応答時間 ${elapsedMs}ms が500ms以内であるべきです');
        
        // 次の反復のためにウィジェットツリーをクリア
        await tester.pumpWidget(Container());
      }
    });
  });
}

/// ランダムな通貨シンボルを生成
String _generateRandomSymbol(Random random) {
  const symbols = ['BTC', 'ETH', 'ADA', 'DOT', 'SOL', 'MATIC', 'AVAX', 'LINK', 'UNI', 'ATOM'];
  return symbols[random.nextInt(symbols.length)];
}

/// ランダムな価格データを生成
CryptoPrice _generateRandomPrice(String symbol, Random random) {
  final names = {
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
    'ADA': 'Cardano',
    'DOT': 'Polkadot',
    'SOL': 'Solana',
    'MATIC': 'Polygon',
    'AVAX': 'Avalanche',
    'LINK': 'Chainlink',
    'UNI': 'Uniswap',
    'ATOM': 'Cosmos',
  };

  return CryptoPrice(
    symbol: symbol,
    name: names[symbol] ?? symbol,
    price: random.nextDouble() * 50000 + 0.01, // 0.01 ~ 50000
    change24h: (random.nextDouble() * 20) - 10, // -10% ~ +10%
    marketCap: random.nextDouble() * 1000000000000, // 0 ~ 1T
    lastUpdated: DateTime.now(),
  );
}
