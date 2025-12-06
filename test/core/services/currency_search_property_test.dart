import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/services/currency_search_service.dart';
import 'package:crypto_watch/core/services/coingecko_api_client.dart';
import 'package:crypto_watch/core/models/currency_search_result.dart';

/// モックCoinGecko APIクライアント（プロパティテスト用）
class PropertyTestMockApiClient extends CoinGeckoApiClient {
  final Duration responseDelay;
  int callCount = 0;

  PropertyTestMockApiClient({this.responseDelay = const Duration(milliseconds: 50)});

  @override
  Future<List<CurrencySearchResult>> searchCoins(
    String query, {
    int limit = 10,
  }) async {
    callCount++;
    
    // 応答遅延をシミュレート
    await Future.delayed(responseDelay);

    // ランダムな検索結果を生成
    final random = Random();
    final resultCount = random.nextInt(10) + 1; // 1-10件

    return List.generate(
      resultCount,
      (i) => CurrencySearchResult(
        id: 'coin_${query}_$i',
        symbol: 'SYM$i',
        name: 'Coin $i for $query',
        marketCapRank: i + 1,
      ),
    );
  }

  @override
  void dispose() {
    // モックなので何もしない
  }
}

void main() {
  group('Property 11: サジェスト応答時間', () {
    /// **Feature: smartwatch-ui-optimization, Property 11: サジェスト応答時間**
    /// **Validates: Requirements 18.2**
    /// 
    /// 任意の検索クエリに対して、サジェスト結果は300ms以内に表示される
    test('任意の検索クエリに対して300ms以内に結果を返す（100回テスト）', () async {
      // 100回のランダムなクエリでテスト
      final random = Random();
      final queries = List.generate(
        100,
        (i) => _generateRandomQuery(random),
      );

      for (final query in queries) {
        final mockApiClient = PropertyTestMockApiClient(
          responseDelay: const Duration(milliseconds: 50), // API応答時間
        );
        final searchService = CurrencySearchService(
          apiClient: mockApiClient,
          debounceDuration: const Duration(milliseconds: 100), // デバウンス期間
        );

        final stopwatch = Stopwatch()..start();

        try {
          // getSuggestionsを使用（デバウンス処理を含む）
          final stream = searchService.getSuggestions(query);
          await stream.first;

          stopwatch.stop();

          // 300ms以内に結果が返されることを確認（要件 18.2）
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(300),
            reason: 'Query "$query" took ${stopwatch.elapsedMilliseconds}ms, '
                'should be less than 300ms',
          );
        } finally {
          searchService.dispose();
        }
      }
    });

    test('2文字未満のクエリは即座に空リストを返す', () async {
      final random = Random();
      final shortQueries = List.generate(
        50,
        (i) => _generateRandomQuery(random, minLength: 1, maxLength: 1),
      );

      for (final query in shortQueries) {
        final mockApiClient = PropertyTestMockApiClient();
        final searchService = CurrencySearchService(
          apiClient: mockApiClient,
          debounceDuration: const Duration(milliseconds: 100),
        );

        final stopwatch = Stopwatch()..start();

        try {
          final stream = searchService.getSuggestions(query);
          final results = await stream.first;

          stopwatch.stop();

          // 空リストが返される
          expect(results, isEmpty);
          
          // APIは呼ばれない
          expect(mockApiClient.callCount, equals(0));
          
          // 即座に返される（デバウンス期間より短い）
          expect(stopwatch.elapsedMilliseconds, lessThan(100));
        } finally {
          searchService.dispose();
        }
      }
    });

    test('様々な長さのクエリで応答時間が一定である', () async {
      final random = Random();
      final responseTimes = <int>[];

      // 様々な長さのクエリをテスト（2-20文字）
      for (var length = 2; length <= 20; length++) {
        final query = _generateRandomQuery(random, minLength: length, maxLength: length);
        
        final mockApiClient = PropertyTestMockApiClient(
          responseDelay: const Duration(milliseconds: 50),
        );
        final searchService = CurrencySearchService(
          apiClient: mockApiClient,
          debounceDuration: const Duration(milliseconds: 100),
        );

        final stopwatch = Stopwatch()..start();

        try {
          final stream = searchService.getSuggestions(query);
          await stream.first;

          stopwatch.stop();
          responseTimes.add(stopwatch.elapsedMilliseconds);

          // 300ms以内
          expect(stopwatch.elapsedMilliseconds, lessThan(300));
        } finally {
          searchService.dispose();
        }
      }

      // 応答時間の標準偏差が小さいことを確認（一定性）
      final mean = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      final variance = responseTimes
          .map((t) => pow(t - mean, 2))
          .reduce((a, b) => a + b) / responseTimes.length;
      final stdDev = sqrt(variance);

      // 標準偏差が平均の50%以下であることを確認（応答時間が比較的一定）
      expect(stdDev, lessThan(mean * 0.5),
          reason: 'Response time should be consistent across different query lengths');
    });
  });

  group('Property 12: 検索結果のキャッシング', () {
    /// **Feature: smartwatch-ui-optimization, Property 12: 検索結果のキャッシング**
    /// **Validates: Requirements 18.7**
    /// 
    /// 任意の検索クエリに対して、同じクエリを2回実行した場合、
    /// 2回目はキャッシュから取得される
    test('任意のクエリで2回目はキャッシュから取得される（100回テスト）', () async {
      final random = Random();
      final queries = List.generate(
        100,
        (i) => _generateRandomQuery(random),
      );

      for (final query in queries) {
        final mockApiClient = PropertyTestMockApiClient();
        final searchService = CurrencySearchService(
          apiClient: mockApiClient,
          debounceDuration: const Duration(milliseconds: 50),
        );

        try {
          // 1回目: APIから取得
          final stopwatch1 = Stopwatch()..start();
          final results1 = await searchService.searchCurrencies(query);
          stopwatch1.stop();
          final firstCallTime = stopwatch1.elapsedMilliseconds;

          // 2回目: キャッシュから取得
          final stopwatch2 = Stopwatch()..start();
          final results2 = await searchService.searchCurrencies(query);
          stopwatch2.stop();
          final secondCallTime = stopwatch2.elapsedMilliseconds;

          // 結果が同じ
          expect(results2, equals(results1));

          // APIは1回のみ呼ばれる
          expect(mockApiClient.callCount, equals(1),
              reason: 'API should be called only once for query "$query"');

          // 2回目は1回目より大幅に速い（キャッシュヒット）
          expect(secondCallTime, lessThan(firstCallTime / 2),
              reason: 'Second call should be much faster (cached) for query "$query"');
        } finally {
          searchService.dispose();
        }
      }
    });

    test('異なるクエリはそれぞれキャッシュされる', () async {
      final random = Random();
      final queries = List.generate(
        20,
        (i) => _generateRandomQuery(random),
      );

      final mockApiClient = PropertyTestMockApiClient();
      final searchService = CurrencySearchService(
        apiClient: mockApiClient,
        debounceDuration: const Duration(milliseconds: 50),
      );

      try {
        // すべてのクエリを1回ずつ実行
        for (final query in queries) {
          await searchService.searchCurrencies(query);
        }

        final firstCallCount = mockApiClient.callCount;

        // すべてのクエリを再度実行（キャッシュから取得）
        for (final query in queries) {
          await searchService.searchCurrencies(query);
        }

        // API呼び出し回数が変わらない（すべてキャッシュヒット）
        expect(mockApiClient.callCount, equals(firstCallCount),
            reason: 'All queries should be cached');
      } finally {
        searchService.dispose();
      }
    });

    test('キャッシュクリア後は再度APIを呼び出す', () async {
      final random = Random();
      final queries = List.generate(
        50,
        (i) => _generateRandomQuery(random),
      );

      for (final query in queries) {
        final mockApiClient = PropertyTestMockApiClient();
        final searchService = CurrencySearchService(
          apiClient: mockApiClient,
          debounceDuration: const Duration(milliseconds: 50),
        );

        try {
          // 1回目
          await searchService.searchCurrencies(query);
          expect(mockApiClient.callCount, equals(1));

          // キャッシュクリア
          searchService.clearCache();

          // 2回目（キャッシュクリア後）
          await searchService.searchCurrencies(query);
          expect(mockApiClient.callCount, equals(2),
              reason: 'API should be called again after cache clear for query "$query"');
        } finally {
          searchService.dispose();
        }
      }
    });

    test('大文字小文字を区別してキャッシュする', () async {
      final mockApiClient = PropertyTestMockApiClient();
      final searchService = CurrencySearchService(
        apiClient: mockApiClient,
        debounceDuration: const Duration(milliseconds: 50),
      );

      try {
        // 様々な大文字小文字の組み合わせ
        final queries = ['bitcoin', 'Bitcoin', 'BITCOIN', 'BiTcOiN'];

        for (final query in queries) {
          await searchService.searchCurrencies(query);
        }

        // すべて異なるクエリとして扱われる
        expect(mockApiClient.callCount, equals(queries.length),
            reason: 'Each case variation should be cached separately');
      } finally {
        searchService.dispose();
      }
    });
  });
}

/// ランダムな検索クエリを生成
String _generateRandomQuery(Random random, {int minLength = 2, int maxLength = 10}) {
  // minLengthとmaxLengthが同じ場合の処理
  if (minLength == maxLength) {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    return List.generate(minLength, (i) => chars[random.nextInt(chars.length)]).join();
  }
  
  final length = minLength + random.nextInt(maxLength - minLength + 1);
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  return List.generate(length, (i) => chars[random.nextInt(chars.length)]).join();
}
