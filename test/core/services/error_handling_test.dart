import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/services/currency_search_service.dart';
import 'package:crypto_watch/core/services/coingecko_api_client.dart';
import 'package:crypto_watch/core/services/search_cache.dart';
import 'package:crypto_watch/core/models/currency_search_result.dart';
import 'package:crypto_watch/core/error/exceptions.dart';

/// モックCoinGecko APIクライアント（エラーハンドリング用）
class MockErrorCoinGeckoApiClient extends CoinGeckoApiClient {
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

    return [];
  }

  @override
  void dispose() {
    // モックなので何もしない
  }
}

void main() {
  late CurrencySearchService searchService;
  late MockErrorCoinGeckoApiClient mockApiClient;
  late SearchCache searchCache;

  setUp(() {
    mockApiClient = MockErrorCoinGeckoApiClient();
    searchCache = SearchCache();
    searchService = CurrencySearchService(
      apiClient: mockApiClient,
      cache: searchCache,
      debounceDuration: const Duration(milliseconds: 100),
    );
  });

  tearDown(() {
    searchService.dispose();
  });

  group('エラーハンドリング - ネットワークエラー（要件 16.10）', () {
    test('NetworkExceptionが発生した場合、例外を再スローする', () async {
      // Arrange
      mockApiClient.mockException = const NetworkException(
        message: 'ネットワーク接続がありません',
      );

      // Act & Assert
      expect(
        () => searchService.searchCurrencies('bitcoin'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('NetworkExceptionのメッセージが正しい', () async {
      // Arrange
      const expectedMessage = 'ネットワーク接続がありません';
      mockApiClient.mockException = const NetworkException(
        message: expectedMessage,
      );

      // Act & Assert
      try {
        await searchService.searchCurrencies('bitcoin');
        fail('例外がスローされるべき');
      } on NetworkException catch (e) {
        expect(e.message, equals(expectedMessage));
      }
    });

    test('TimeoutExceptionが発生した場合、例外を再スローする', () async {
      // Arrange
      mockApiClient.mockException = const TimeoutException(
        message: 'リクエストがタイムアウトしました',
      );

      // Act & Assert
      expect(
        () => searchService.searchCurrencies('bitcoin'),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('エラーハンドリング - レート制限エラー（要件 16.10）', () {
    test('RateLimitExceptionが発生した場合、例外を再スローする', () async {
      // Arrange
      mockApiClient.mockException = const RateLimitException(
        message: 'リクエスト制限に達しました',
      );

      // Act & Assert
      expect(
        () => searchService.searchCurrencies('bitcoin'),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('RateLimitExceptionのステータスコードが429', () async {
      // Arrange
      mockApiClient.mockException = const RateLimitException();

      // Act & Assert
      try {
        await searchService.searchCurrencies('bitcoin');
        fail('例外がスローされるべき');
      } on RateLimitException catch (e) {
        expect(e.statusCode, equals(429));
      }
    });
  });

  group('エラーハンドリング - サーバーエラー（要件 16.10）', () {
    test('ServerExceptionが発生した場合、例外を再スローする', () async {
      // Arrange
      mockApiClient.mockException = const ServerException(
        message: 'サーバーエラーが発生しました',
        statusCode: 500,
      );

      // Act & Assert
      expect(
        () => searchService.searchCurrencies('bitcoin'),
        throwsA(isA<ServerException>()),
      );
    });

    test('ServerExceptionのステータスコードが正しい', () async {
      // Arrange
      const expectedStatusCode = 503;
      mockApiClient.mockException = const ServerException(
        message: 'サービスが利用できません',
        statusCode: expectedStatusCode,
      );

      // Act & Assert
      try {
        await searchService.searchCurrencies('bitcoin');
        fail('例外がスローされるべき');
      } on ServerException catch (e) {
        expect(e.statusCode, equals(expectedStatusCode));
      }
    });
  });

  group('エラーハンドリング - 検索結果0件（要件 16.9）', () {
    test('検索結果が0件の場合、空リストを返す', () async {
      // Arrange
      mockApiClient.mockException = null; // エラーなし、空リストを返す

      // Act
      final results = await searchService.searchCurrencies('nonexistent');

      // Assert
      expect(results, isEmpty);
      expect(mockApiClient.callCount, equals(1));
    });

    test('空リストはキャッシュされる', () async {
      // Arrange
      const query = 'nonexistent';

      // Act
      final results1 = await searchService.searchCurrencies(query);
      final results2 = await searchService.searchCurrencies(query);

      // Assert
      expect(results1, isEmpty);
      expect(results2, isEmpty);
      expect(mockApiClient.callCount, equals(1)); // キャッシュから取得
    });
  });

  group('エラーハンドリング - getSuggestionsのエラー処理', () {
    test('NetworkException発生時、getSuggestionsは空リストを返す', () async {
      // Arrange
      mockApiClient.mockException = const NetworkException();

      // Act
      final stream = searchService.getSuggestions('bitcoin');
      final results = await stream.first;

      // Assert
      expect(results, isEmpty);
    });

    test('RateLimitException発生時、getSuggestionsは空リストを返す', () async {
      // Arrange
      mockApiClient.mockException = const RateLimitException();

      // Act
      final stream = searchService.getSuggestions('bitcoin');
      final results = await stream.first;

      // Assert
      expect(results, isEmpty);
    });

    test('ServerException発生時、getSuggestionsは空リストを返す', () async {
      // Arrange
      mockApiClient.mockException = const ServerException();

      // Act
      final stream = searchService.getSuggestions('bitcoin');
      final results = await stream.first;

      // Assert
      expect(results, isEmpty);
    });

    test('一般的なException発生時、getSuggestionsは空リストを返す', () async {
      // Arrange
      mockApiClient.mockException = Exception('Unknown error');

      // Act
      final stream = searchService.getSuggestions('bitcoin');
      final results = await stream.first;

      // Assert
      expect(results, isEmpty);
    });
  });

  group('エラーハンドリング - リトライ動作', () {
    test('エラー後に再度検索できる', () async {
      // Arrange
      mockApiClient.mockException = const NetworkException();

      // Act - 最初の検索はエラー
      try {
        await searchService.searchCurrencies('bitcoin');
        fail('例外がスローされるべき');
      } on NetworkException {
        // 期待通り
      }

      // エラーをクリア
      mockApiClient.mockException = null;

      // Act - 再試行
      final results = await searchService.searchCurrencies('bitcoin');

      // Assert
      expect(results, isEmpty); // 空リストが返る（モックの動作）
      expect(mockApiClient.callCount, equals(2)); // 2回呼ばれる
    });

    test('キャッシュクリア後にエラーから回復できる', () async {
      // Arrange
      const query = 'bitcoin';
      mockApiClient.mockException = const NetworkException();

      // Act - エラー発生
      try {
        await searchService.searchCurrencies(query);
        fail('例外がスローされるべき');
      } on NetworkException {
        // 期待通り
      }

      // キャッシュをクリアしてエラーを解消
      searchService.clearCache();
      mockApiClient.mockException = null;

      // Act - 再試行
      final results = await searchService.searchCurrencies(query);

      // Assert
      expect(results, isEmpty);
      expect(mockApiClient.callCount, equals(2));
    });
  });

  group('エラーハンドリング - 複数のエラータイプ', () {
    test('異なるエラータイプを区別できる', () async {
      // NetworkException
      mockApiClient.mockException = const NetworkException();
      expect(
        () => searchService.searchCurrencies('test1'),
        throwsA(isA<NetworkException>()),
      );

      // RateLimitException
      mockApiClient.mockException = const RateLimitException();
      expect(
        () => searchService.searchCurrencies('test2'),
        throwsA(isA<RateLimitException>()),
      );

      // ServerException
      mockApiClient.mockException = const ServerException();
      expect(
        () => searchService.searchCurrencies('test3'),
        throwsA(isA<ServerException>()),
      );
    });

    test('エラーメッセージが適切に設定される', () async {
      final errorMessages = <String, Exception>{
        'ネットワーク接続がありません': const NetworkException(
          message: 'ネットワーク接続がありません',
        ),
        'リクエスト制限に達しました': const RateLimitException(
          message: 'リクエスト制限に達しました',
        ),
        'サーバーエラーが発生しました': const ServerException(
          message: 'サーバーエラーが発生しました',
        ),
      };

      for (final entry in errorMessages.entries) {
        mockApiClient.mockException = entry.value;

        try {
          await searchService.searchCurrencies('test');
          fail('例外がスローされるべき');
        } on AppException catch (e) {
          expect(e.message, equals(entry.key));
        }
      }
    });
  });
}
