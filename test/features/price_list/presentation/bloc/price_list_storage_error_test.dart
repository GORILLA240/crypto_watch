import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:crypto_watch/core/error/exceptions.dart';
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

@GenerateMocks([
  GetPrices,
  RefreshPrices,
  GetFavorites,
  AddFavorite,
  RemoveFavorite,
  LocalStorage,
])
import 'price_list_storage_error_test.mocks.dart';

void main() {
  group('PriceListBloc Storage Error Handling Property-Based Tests', () {
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
    });

    tearDown(() {
      bloc.close();
    });

    // **Feature: price-list-improvements, Property 9: ストレージ操作のエラーハンドリング**
    // **Validates: 要件 9.5**
    test('ストレージ操作失敗時、デフォルト値を使用して動作を継続する', () async {
      // 100回の反復テストを実行
      for (int iteration = 0; iteration < 100; iteration++) {
        // ランダムな価格リストを生成（3〜10銘柄）
        final priceCount = random.nextInt(8) + 3;
        final prices = _generateRandomPrices(priceCount, random);
        
        // ストレージ読み込みエラーをシミュレート
        when(mockLocalStorage.getStringList(AppConstants.priceListOrderKey))
            .thenThrow(StorageException(
              message: 'ストレージ読み込みエラー',
              originalError: Exception('Simulated read error'),
            ));
        
        when(mockGetPrices(any)).thenAnswer((_) async => Right(prices));
        
        bloc = PriceListBloc(
          getPrices: mockGetPrices,
          refreshPrices: mockRefreshPrices,
          getFavorites: mockGetFavorites,
          addFavorite: mockAddFavorite,
          removeFavorite: mockRemoveFavorite,
          localStorage: mockLocalStorage,
        );

        // 価格データを読み込む（ストレージエラーがあっても成功するべき）
        bloc.add(LoadPricesEvent(symbols: prices.map((p) => p.symbol).toList()));
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<PriceListLoading>(),
            isA<PriceListLoaded>(),
          ]),
        );

        // エラーがあってもデフォルト値（空のリスト）で動作を継続
        final loadedState = bloc.state as PriceListLoaded;
        expect(loadedState.customOrder, equals([]),
            reason: '反復 $iteration: ストレージ読み込みエラー時はデフォルト値（空のリスト）を使用するべきです');
        expect(loadedState.prices, equals(prices),
            reason: '反復 $iteration: ストレージエラーがあっても価格データは正常に読み込まれるべきです');

        // ストレージ書き込みエラーをシミュレート
        when(mockLocalStorage.setStringList(any, any))
            .thenThrow(StorageException(
              message: 'ストレージ書き込みエラー',
              originalError: Exception('Simulated write error'),
            ));

        // 並び替え操作を実行（ストレージエラーがある場合はロールバックされるべき - 要件 8.9）
        final oldIndex = random.nextInt(prices.length);
        int newIndex = random.nextInt(prices.length);
        
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        
        // 元の順序を保存
        final originalOrder = loadedState.customOrder;
        
        bloc.add(ReorderPricesEvent(
          oldIndex: oldIndex,
          newIndex: newIndex + (newIndex > oldIndex ? 1 : 0),
        ));
        await Future.delayed(const Duration(milliseconds: 100));

        // ストレージ書き込みエラーがある場合、元の順序に戻る（ロールバック - 要件 8.9）
        final reorderedState = bloc.state as PriceListLoaded;
        expect(reorderedState.customOrder, equals(originalOrder),
            reason: '反復 $iteration: ストレージ書き込みエラー時は元の順序に戻るべきです（要件 8.9）');

        // エラーメッセージが設定される
        expect(reorderedState.errorMessage, isNotNull,
            reason: '反復 $iteration: ストレージエラー時はエラーメッセージが設定されるべきです（要件 8.9）');

        // エラー状態にはならない（Loaded状態を維持して動作を継続 - 要件 9.5）
        expect(bloc.state, isA<PriceListLoaded>(),
            reason: '反復 $iteration: ストレージエラーでもLoaded状態を維持するべきです（要件 9.5）');

        // 次の反復のためにクリーンアップ
        await bloc.close();
        reset(mockLocalStorage);
      }
    });

    test('ストレージ読み込みエラー時、複数の操作でデフォルト値を使用する', () async {
      // 100回の反復テストを実行
      for (int iteration = 0; iteration < 100; iteration++) {
        final priceCount = random.nextInt(8) + 3;
        final prices = _generateRandomPrices(priceCount, random);
        
        // ストレージ読み込みエラーをシミュレート
        when(mockLocalStorage.getStringList(AppConstants.priceListOrderKey))
            .thenThrow(StorageException(
              message: 'ストレージ読み込みエラー',
            ));
        
        // ストレージ書き込みは成功するように設定
        when(mockLocalStorage.setStringList(any, any))
            .thenAnswer((_) async => {});
        
        when(mockGetPrices(any)).thenAnswer((_) async => Right(prices));
        
        bloc = PriceListBloc(
          getPrices: mockGetPrices,
          refreshPrices: mockRefreshPrices,
          getFavorites: mockGetFavorites,
          addFavorite: mockAddFavorite,
          removeFavorite: mockRemoveFavorite,
          localStorage: mockLocalStorage,
        );

        // 初回読み込み
        bloc.add(LoadPricesEvent(symbols: prices.map((p) => p.symbol).toList()));
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<PriceListLoading>(),
            isA<PriceListLoaded>(),
          ]),
        );

        var currentState = bloc.state as PriceListLoaded;
        expect(currentState.customOrder, equals([]),
            reason: '反復 $iteration: 初回読み込みでデフォルト値を使用するべきです');

        // ランダムな並び替え操作を複数回実行
        final reorderCount = random.nextInt(5) + 1;
        List<String> expectedOrder = prices.map((p) => p.symbol).toList();
        
        for (int i = 0; i < reorderCount; i++) {
          final oldIndex = random.nextInt(expectedOrder.length);
          int newIndex = random.nextInt(expectedOrder.length);
          
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          
          final symbol = expectedOrder.removeAt(oldIndex);
          expectedOrder.insert(newIndex, symbol);
          
          bloc.add(ReorderPricesEvent(
            oldIndex: oldIndex,
            newIndex: newIndex + (newIndex > oldIndex ? 1 : 0),
          ));
          await Future.delayed(const Duration(milliseconds: 50));
          
          currentState = bloc.state as PriceListLoaded;
          expect(currentState.customOrder, equals(expectedOrder),
              reason: '反復 $iteration, 並び替え $i: 状態が正しく更新されるべきです');
        }

        // すべての操作でエラー状態にならないことを確認
        expect(bloc.state, isA<PriceListLoaded>(),
            reason: '反復 $iteration: 最終的にLoaded状態であるべきです');

        await bloc.close();
        reset(mockLocalStorage);
      }
    });

    test('ストレージ書き込みエラー時、アプリケーションは継続して動作する', () async {
      // 100回の反復テストを実行
      for (int iteration = 0; iteration < 100; iteration++) {
        final priceCount = random.nextInt(8) + 3;
        final prices = _generateRandomPrices(priceCount, random);
        
        // ストレージ読み込みは成功
        when(mockLocalStorage.getStringList(AppConstants.priceListOrderKey))
            .thenAnswer((_) async => null);
        
        // ストレージ書き込みエラーをシミュレート
        when(mockLocalStorage.setStringList(any, any))
            .thenThrow(StorageException(
              message: 'ストレージ書き込みエラー',
            ));
        
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

        // 初期状態を取得
        var currentState = bloc.state as PriceListLoaded;

        // ランダムな並び替え操作を実行
        final reorderCount = random.nextInt(5) + 1;
        
        for (int i = 0; i < reorderCount; i++) {
          // 現在の状態を取得
          currentState = bloc.state as PriceListLoaded;
          final orderBeforeReorder = currentState.customOrder;
          
          final oldIndex = random.nextInt(prices.length);
          int newIndex = random.nextInt(prices.length);
          
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          
          bloc.add(ReorderPricesEvent(
            oldIndex: oldIndex,
            newIndex: newIndex + (newIndex > oldIndex ? 1 : 0),
          ));
          await Future.delayed(const Duration(milliseconds: 100));
          
          // ストレージエラーがある場合、元の順序に戻る（ロールバック - 要件 8.9）
          currentState = bloc.state as PriceListLoaded;
          expect(currentState.customOrder, equals(orderBeforeReorder),
              reason: '反復 $iteration, 並び替え $i: ストレージエラー時は元の順序に戻るべきです（要件 8.9）');
          
          // エラーメッセージが設定される
          expect(currentState.errorMessage, isNotNull,
              reason: '反復 $iteration, 並び替え $i: エラーメッセージが設定されるべきです');
          
          // エラー状態にならない（Loaded状態を維持）
          expect(bloc.state, isA<PriceListLoaded>(),
              reason: '反復 $iteration, 並び替え $i: Loaded状態を維持するべきです');
        }

        // 追加の操作（リフレッシュ）も正常に動作することを確認
        when(mockRefreshPrices()).thenAnswer((_) async => Right(prices));
        
        bloc.add(const RefreshPricesEvent());
        await Future.delayed(const Duration(milliseconds: 100));
        
        // リフレッシュ後も正常な状態を維持
        expect(bloc.state, isA<PriceListLoaded>(),
            reason: '反復 $iteration: リフレッシュ後も正常な状態を維持するべきです');

        await bloc.close();
        reset(mockLocalStorage);
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
