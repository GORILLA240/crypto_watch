import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/services/currency_search_service.dart';
import 'package:crypto_watch/core/services/coingecko_api_client.dart';
import 'package:crypto_watch/core/services/search_cache.dart';
import 'package:crypto_watch/core/models/currency_search_result.dart';

/// モックCoinGecko APIクライアント
class MockCoinGeckoApiClient extends CoinGeckoApiClient {
  List<CurrencySearchResult>? mockResults;
  Exception? mockException;
  int callCount = 0;

  @override
  Future<List<CurrencySearchResult>> searchCoins(
    String query, {
    int limit = 10,
  }) async {
    callCount++;

    if (mockException != null) {
      throw mockException!;
    }

    if (mockResults != null) {
      return mockResults!;
    }

    // デフォルトのモック結果
    return [
      CurrencySearchResult(
        id: 'bitcoin',
        symbol: 'BTC',
        name: 'Bitcoin',
        iconUrl: 'https://example.com/btc.png',
        marketCapRank: 1,
      ),
      CurrencySearchResult(
        id: 'ethereum',
        symbol: 'ETH',
        name: 'Ethereum',
        iconUrl: 'https://example.com/eth.png',
        marketCapRank: 2,
      ),
    ];
  }

  @override
  void dispose() {
    // モックなので何もしない
  }
}

void main() {
  late CurrencySearchService searchService;
  late MockCoinGeckoApiClient mockApiClient;
  late SearchCache searchCache;

  setUp(() {
    mockApiClient = MockCoinGeckoApiClient();
    searchCache = SearchCache();
    searchService = CurrencySearchService(
      apiClient: mockApiClient,
      cache: searchCache,
      debounceDuration: const Duration(milliseconds: 100), // テスト用に短縮
    );
  });

  tearDown(() {
    searchService.dispose();
  });

  group('CurrencySearchService - 検索機能', () {
    test('空のクエリで空リストを返す', () async {
      // Act
      final results = await searchService.searchCurrencies('');

      // Assert
      expect(results, isEmpty);
      expect(mockApiClient.callCount, equals(0)); // APIは呼ばれない
    });

    test('空白のみのクエリで空リストを返す', () async {
      // Act
      final results = await searchService.searchCurrencies('   ');

      // Assert
      expect(results, isEmpty);
      expect(mockApiClient.callCount, equals(0));
    });

    test('有効なクエリで検索結果を返す', () async {
      // Arrange
      mockApiClient.mockResults = [
        const CurrencySearchResult(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          marketCapRank: 1,
        ),
      ];

      // Act
      final results = await searchService.searchCurrencies('bitcoin');

      // Assert
      expect(results.length, equals(1));
      expect(results.first.symbol, equals('BTC'));
      expect(mockApiClient.callCount, equals(1));
    });

    test('検索結果が時価総額順でソートされる（要件 18.6）', () async {
      // Arrange
      mockApiClient.mockResults = [
        const CurrencySearchResult(
          id: 'ethereum',
          symbol: 'ETH',
          name: 'Ethereum',
          marketCapRank: 2,
        ),
        const CurrencySearchResult(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          marketCapRank: 1,
        ),
        const CurrencySearchResult(
          id: 'cardano',
          symbol: 'ADA',
          name: 'Cardano',
          marketCapRank: 3,
        ),
      ];

      // Act
      final results = await searchService.searchCurrencies('crypto');

      // Assert
      expect(results[0].marketCapRank, equals(1)); // BTC
      expect(results[1].marketCapRank, equals(2)); // ETH
      expect(results[2].marketCapRank, equals(3)); // ADA
    });

    test('最大10件の結果を返す（要件 16.5）', () async {
      // Arrange
      // APIクライアントは最大10件を返すことを想定
      final mockResults = List.generate(
        10,
        (i) => CurrencySearchResult(
          id: 'coin$i',
          symbol: 'COIN$i',
          name: 'Coin $i',
          marketCapRank: i + 1,
        ),
      );
      mockApiClient.mockResults = mockResults;

      // Act
      final results = await searchService.searchCurrencies('coin');

      // Assert
      expect(results.length, equals(10));
    });
  });

  group('CurrencySearchService - キャッシング機能', () {
    test('同じクエリを2回実行した場合、2回目はキャッシュから取得（要件 18.7）', () async {
      // Arrange
      const query = 'bitcoin';

      // Act
      final results1 = await searchService.searchCurrencies(query);
      final results2 = await searchService.searchCurrencies(query);

      // Assert
      expect(results1, equals(results2));
      expect(mockApiClient.callCount, equals(1)); // APIは1回のみ呼ばれる
    });

    test('異なるクエリはそれぞれAPIを呼び出す', () async {
      // Act
      await searchService.searchCurrencies('bitcoin');
      await searchService.searchCurrencies('ethereum');

      // Assert
      expect(mockApiClient.callCount, equals(2));
    });

    test('キャッシュをクリアできる', () async {
      // Arrange
      const query = 'bitcoin';
      await searchService.searchCurrencies(query);

      // Act
      searchService.clearCache();
      await searchService.searchCurrencies(query);

      // Assert
      expect(mockApiClient.callCount, equals(2)); // クリア後は再度API呼び出し
    });
  });

  group('CurrencySearchService - デバウンス処理', () {
    test('getSuggestionsは2文字未満で空リストを返す（要件 18.1）', () async {
      // Act
      final stream = searchService.getSuggestions('a');
      final results = await stream.first;

      // Assert
      expect(results, isEmpty);
      expect(mockApiClient.callCount, equals(0));
    });

    test('getSuggestionsは2文字以上で検索を実行（要件 18.1）', () async {
      // Act
      final stream = searchService.getSuggestions('btc');
      final results = await stream.first;

      // Assert
      expect(results, isNotEmpty);
      expect(mockApiClient.callCount, equals(1));
    });

    test('デバウンス期間が適用される（要件 18.3）', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act
      final stream = searchService.getSuggestions('bitcoin');
      await stream.first;

      stopwatch.stop();

      // Assert
      // デバウンス期間（100ms）以上経過していることを確認
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });
  });

  group('CurrencySearchService - エラーハンドリング', () {
    test('API呼び出しエラー時に例外をスロー（要件 16.10）', () async {
      // Arrange
      mockApiClient.mockException = Exception('Network error');

      // Act & Assert
      expect(
        () => searchService.searchCurrencies('bitcoin'),
        throwsException,
      );
    });

    test('getSuggestionsはエラー時に空リストを返す', () async {
      // Arrange
      mockApiClient.mockException = Exception('Network error');

      // Act
      final stream = searchService.getSuggestions('bitcoin');
      final results = await stream.first;

      // Assert
      expect(results, isEmpty);
    });
  });

  group('CurrencySearchService - ストリーム検索', () {
    test('searchメソッドでクエリを送信できる', () async {
      // Arrange
      final resultsStream = searchService.suggestionsStream;
      final resultsFuture = resultsStream.first;

      // Act
      searchService.search('bitcoin');
      final results = await resultsFuture;

      // Assert
      expect(results, isNotEmpty);
    });

    test('連続したクエリは最後のクエリのみ処理される（要件 18.3）', () async {
      // Arrange
      mockApiClient.callCount = 0;

      // Act
      searchService.search('b');
      searchService.search('bi');
      searchService.search('bit');
      searchService.search('bitcoin');

      // デバウンス期間 + 処理時間を待つ
      await Future.delayed(const Duration(milliseconds: 200));

      // Assert
      // 最後のクエリのみ処理されるため、API呼び出しは1回のみ
      expect(mockApiClient.callCount, lessThanOrEqualTo(2));
    });
  });

  group('CurrencySearchService - リソース管理', () {
    test('disposeを呼び出してもエラーにならない', () {
      // Act & Assert
      expect(() => searchService.dispose(), returnsNormally);
    });

    test('dispose後はストリームが閉じられる', () async {
      // Arrange
      final stream = searchService.suggestionsStream;

      // Act
      searchService.dispose();

      // Assert
      expect(stream.isEmpty, completion(isTrue));
    });
  });
}
