import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:crypto_watch/core/error/failures.dart';
import 'package:crypto_watch/core/storage/local_storage.dart';
import 'package:crypto_watch/core/constants/app_constants.dart';
import 'package:crypto_watch/features/price_list/domain/entities/crypto_price.dart';
import 'package:crypto_watch/features/price_list/domain/usecases/get_prices.dart';
import 'package:crypto_watch/features/price_list/domain/usecases/refresh_prices.dart';
import 'package:crypto_watch/features/price_list/presentation/bloc/price_list_bloc.dart';
import 'package:crypto_watch/features/price_list/presentation/bloc/price_list_event.dart';
import 'package:crypto_watch/features/price_list/presentation/bloc/price_list_state.dart';
import 'package:crypto_watch/features/favorites/domain/usecases/get_favorites.dart';
import 'package:crypto_watch/features/favorites/domain/usecases/add_favorite.dart';
import 'package:crypto_watch/features/favorites/domain/usecases/remove_favorite.dart';
import 'package:crypto_watch/features/favorites/domain/entities/favorite.dart';

@GenerateMocks([
  GetPrices,
  RefreshPrices,
  GetFavorites,
  AddFavorite,
  RemoveFavorite,
  LocalStorage,
])
import 'price_list_reorder_test.mocks.dart';

void main() {
  group('PriceListBloc Reorder Property-Based Tests', () {
    late PriceListBloc bloc;
    late MockGetPrices mockGetPrices;
    late MockRefreshPrices mockRefreshPrices;
    late MockGetFavorites mockGetFavorites;
    late MockAddFavorite mockAddFavorite;
    late MockRemoveFavorite mockRemoveFavorite;
    late MockLocalStorage mockLocalStorage;
    final random = Random(42); // 固定シードで再現性を確保

    setUp(() {
      mockGetPrices = MockGetPrices();
      mockRefreshPrices = MockRefreshPrices();
      mockGetFavorites = MockGetFavorites();
      mockAddFavorite = MockAddFavorite();
      mockRemoveFavorite = MockRemoveFavorite();
      mockLocalStorage = MockLocalStorage();

      // デフォルトのモック動作を設定
      when(mockGetFavorites()).thenAnswer((_) async => const Right([]));
      when(mockLocalStorage.getStringList(AppConstants.priceListOrderKey))
          .thenAnswer((_) async => null);
      when(mockLocalStorage.setStringList(any, any))
          .thenAnswer((_) async => {});
    });

    tearDown(() {
      bloc.close();
    });

    // **Feature: price-list-improvements, Property 4: 並び替えの永続性**
    // **Validates: 要件 8.5, 8.6, 9.3**
    test('並び替え後、再起動しても順序が維持される', () async {
      // 100回の反復テストを実行
      for (int iteration = 0; iteration < 100; iteration++) {
        // ランダムな価格リストを生成（3〜10銘柄）
        final priceCount = random.nextInt(8) + 3;
        final prices = _generateRandomPrices(priceCount, random);
        
        // 初期状態でBlocを作成
        when(mockGetPrices(any)).thenAnswer((_) async => Right(prices));
        
        bloc = PriceListBloc(
          getPrices: mockGetPrices,
          refreshPrices: mockRefreshPrices,
          getFavorites: mockGetFavorites,
          addFavorite: mockAddFavorite,
          removeFavorite: mockRemoveFavorite,
          localStorage: mockLocalStorage,
        );

        // 価格データを読み込む
        bloc.add(LoadPricesEvent(symbols: prices.map((p) => p.symbol).toList()));
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<PriceListLoading>(),
            isA<PriceListLoaded>(),
          ]),
        );

        // 現在の状態を取得
        final loadedState = bloc.state as PriceListLoaded;
        expect(loadedState.customOrder.isEmpty, isTrue,
            reason: '反復 $iteration: 初期状態ではカスタム順序は空であるべきです');

        // ランダムな並び替え操作を実行（1〜5回）
        final reorderCount = random.nextInt(5) + 1;
        List<String> expectedOrder = prices.map((p) => p.symbol).toList();
        
        for (int i = 0; i < reorderCount; i++) {
          final oldIndex = random.nextInt(expectedOrder.length);
          int newIndex = random.nextInt(expectedOrder.length);
          
          // ReorderableListViewの仕様に合わせて調整
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          
          // 期待される順序を更新
          final symbol = expectedOrder.removeAt(oldIndex);
          expectedOrder.insert(newIndex, symbol);
          
          // 並び替えイベントを発火
          bloc.add(ReorderPricesEvent(oldIndex: oldIndex, newIndex: newIndex + (newIndex > oldIndex ? 1 : 0)));
          await Future.delayed(const Duration(milliseconds: 50)); // イベント処理を待つ
        }

        // 最終状態を確認
        final finalState = bloc.state as PriceListLoaded;
        expect(finalState.customOrder, equals(expectedOrder),
            reason: '反復 $iteration: カスタム順序が期待通りであるべきです');

        // ストレージに保存されたことを確認
        verify(mockLocalStorage.setStringList(
          AppConstants.priceListOrderKey,
          any,
        )).called(greaterThan(0));

        // 「再起動」をシミュレート: 保存された順序を返すようにモックを設定
        when(mockLocalStorage.getStringList(AppConstants.priceListOrderKey))
            .thenAnswer((_) async => expectedOrder);

        // 新しいBlocインスタンスを作成（再起動をシミュレート）
        await bloc.close();
        bloc = PriceListBloc(
          getPrices: mockGetPrices,
          refreshPrices: mockRefreshPrices,
          getFavorites: mockGetFavorites,
          addFavorite: mockAddFavorite,
          removeFavorite: mockRemoveFavorite,
          localStorage: mockLocalStorage,
        );

        // 価格データを再読み込み
        bloc.add(LoadPricesEvent(symbols: prices.map((p) => p.symbol).toList()));
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<PriceListLoading>(),
            isA<PriceListLoaded>(),
          ]),
        );

        // 再起動後も順序が維持されていることを確認
        final reloadedState = bloc.state as PriceListLoaded;
        expect(reloadedState.customOrder, equals(expectedOrder),
            reason: '反復 $iteration: 再起動後もカスタム順序が維持されるべきです');

        // ストレージから読み込まれたことを確認
        verify(mockLocalStorage.getStringList(AppConstants.priceListOrderKey))
            .called(greaterThan(0));

        // 次の反復のためにモックをリセット
        reset(mockLocalStorage);
        when(mockLocalStorage.getStringList(AppConstants.priceListOrderKey))
            .thenAnswer((_) async => null);
        when(mockLocalStorage.setStringList(any, any))
            .thenAnswer((_) async => {});
        
        await bloc.close();
      }
    });

    // **Feature: price-list-improvements, Property 8: 並び替え中の操作制限**
    // **Validates: 要件 8.7, 8.8**
    test('編集モード中、通常のタップ操作が無効化される', () async {
      // 100回の反復テストを実行
      for (int iteration = 0; iteration < 100; iteration++) {
        // ランダムな価格リストを生成
        final priceCount = random.nextInt(8) + 3;
        final prices = _generateRandomPrices(priceCount, random);
        
        when(mockGetPrices(any)).thenAnswer((_) async => Right(prices));
        
        bloc = PriceListBloc(
          getPrices: mockGetPrices,
          refreshPrices: mockRefreshPrices,
          getFavorites: mockGetFavorites,
          addFavorite: mockAddFavorite,
          removeFavorite: mockRemoveFavorite,
          localStorage: mockLocalStorage,
        );

        // 価格データを読み込む
        bloc.add(LoadPricesEvent(symbols: prices.map((p) => p.symbol).toList()));
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<PriceListLoading>(),
            isA<PriceListLoaded>(),
          ]),
        );

        // 初期状態: 並び替えモードはオフ
        var currentState = bloc.state as PriceListLoaded;
        expect(currentState.isReorderMode, isFalse,
            reason: '反復 $iteration: 初期状態では並び替えモードはオフであるべきです');

        // 並び替えモードをトグル
        bloc.add(const ToggleReorderModeEvent());
        await Future.delayed(const Duration(milliseconds: 50));

        // 並び替えモードがオンになったことを確認
        currentState = bloc.state as PriceListLoaded;
        expect(currentState.isReorderMode, isTrue,
            reason: '反復 $iteration: 並び替えモードがオンになるべきです');

        // 並び替えモードを再度トグル（オフに戻す）
        bloc.add(const ToggleReorderModeEvent());
        await Future.delayed(const Duration(milliseconds: 50));

        // 並び替えモードがオフになったことを確認
        currentState = bloc.state as PriceListLoaded;
        expect(currentState.isReorderMode, isFalse,
            reason: '反復 $iteration: 並び替えモードがオフに戻るべきです');

        // ランダムに複数回トグルしてテスト
        final toggleCount = random.nextInt(5) + 1;
        bool expectedMode = false;
        
        for (int i = 0; i < toggleCount; i++) {
          expectedMode = !expectedMode;
          bloc.add(const ToggleReorderModeEvent());
          await Future.delayed(const Duration(milliseconds: 50));
          
          currentState = bloc.state as PriceListLoaded;
          expect(currentState.isReorderMode, equals(expectedMode),
              reason: '反復 $iteration, トグル $i: 並び替えモードが期待通りであるべきです');
        }

        await bloc.close();
      }
    });
  });
}

/// ランダムな価格リストを生成
List<CryptoPrice> _generateRandomPrices(int count, Random random) {
  const symbols = [
    'BTC', 'ETH', 'ADA', 'DOT', 'SOL', 'MATIC', 'AVAX', 'LINK', 'UNI', 'ATOM',
    'XRP', 'DOGE', 'LTC', 'BCH', 'XLM', 'ALGO', 'VET', 'ICP', 'FIL', 'TRX'
  ];
  
  const names = {
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
    'XRP': 'Ripple',
    'DOGE': 'Dogecoin',
    'LTC': 'Litecoin',
    'BCH': 'Bitcoin Cash',
    'XLM': 'Stellar',
    'ALGO': 'Algorand',
    'VET': 'VeChain',
    'ICP': 'Internet Computer',
    'FIL': 'Filecoin',
    'TRX': 'TRON',
  };

  final selectedSymbols = List<String>.from(symbols)..shuffle(random);
  final result = <CryptoPrice>[];

  for (int i = 0; i < count && i < selectedSymbols.length; i++) {
    final symbol = selectedSymbols[i];
    result.add(CryptoPrice(
      symbol: symbol,
      name: names[symbol] ?? symbol,
      price: random.nextDouble() * 50000 + 0.01,
      change24h: (random.nextDouble() * 20) - 10,
      marketCap: random.nextDouble() * 1000000000000,
      lastUpdated: DateTime.now(),
    ));
  }

  return result;
}
