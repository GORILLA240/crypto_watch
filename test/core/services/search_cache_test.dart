import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/services/search_cache.dart';
import 'package:crypto_watch/core/models/currency_search_result.dart';

void main() {
  late SearchCache searchCache;

  setUp(() {
    searchCache = SearchCache();
  });

  group('SearchCache - 基本的なキャッシング', () {
    test('キャッシュに保存した値を取得できる', () {
      // Arrange
      const query = 'bitcoin';
      const results = [
        CurrencySearchResult(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          marketCapRank: 1,
        ),
      ];

      // Act
      searchCache.put(query, results);
      final cachedResults = searchCache.get(query);

      // Assert
      expect(cachedResults, equals(results));
    });

    test('存在しないキーに対してnullを返す', () {
      // Act
      final cachedResults = searchCache.get('nonexistent');

      // Assert
      expect(cachedResults, isNull);
    });

    test('複数のクエリをキャッシュできる', () {
      // Arrange
      const query1 = 'bitcoin';
      const query2 = 'ethereum';
      const results1 = [
        CurrencySearchResult(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          marketCapRank: 1,
        ),
      ];
      const results2 = [
        CurrencySearchResult(
          id: 'ethereum',
          symbol: 'ETH',
          name: 'Ethereum',
          marketCapRank: 2,
        ),
      ];

      // Act
      searchCache.put(query1, results1);
      searchCache.put(query2, results2);

      // Assert
      expect(searchCache.get(query1), equals(results1));
      expect(searchCache.get(query2), equals(results2));
    });
  });

  group('SearchCache - TTL（Time To Live）', () {
    test('TTL期限内のキャッシュは取得できる', () async {
      // Arrange
      const query = 'bitcoin';
      const results = [
        CurrencySearchResult(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          marketCapRank: 1,
        ),
      ];

      // Act
      searchCache.put(query, results);
      await Future.delayed(const Duration(milliseconds: 100)); // TTL内
      final cachedResults = searchCache.get(query);

      // Assert
      expect(cachedResults, equals(results));
    });

    test('TTL期限切れのキャッシュはnullを返す', () async {
      // Arrange
      const query = 'bitcoin';
      const results = [
        CurrencySearchResult(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          marketCapRank: 1,
        ),
      ];

      // カスタムTTLでキャッシュを作成（テスト用に短縮）
      final shortTtlCache = SearchCache(
        ttl: const Duration(milliseconds: 100),
      );

      // Act
      shortTtlCache.put(query, results);
      await Future.delayed(const Duration(milliseconds: 150)); // TTL超過
      final cachedResults = shortTtlCache.get(query);

      // Assert
      expect(cachedResults, isNull);
    });
  });

  group('SearchCache - LRU（Least Recently Used）', () {
    test('最大サイズを超えると古いエントリが削除される', () {
      // Arrange
      final smallCache = SearchCache(maxSize: 3);
      const results = [
        CurrencySearchResult(
          id: 'test',
          symbol: 'TEST',
          name: 'Test',
          marketCapRank: 1,
        ),
      ];

      // Act: 4つのエントリを追加（最大3つ）
      smallCache.put('query1', results);
      smallCache.put('query2', results);
      smallCache.put('query3', results);
      smallCache.put('query4', results); // これで最も古いquery1が削除される

      // Assert
      expect(smallCache.get('query1'), isNull); // 削除された
      expect(smallCache.get('query2'), isNotNull);
      expect(smallCache.get('query3'), isNotNull);
      expect(smallCache.get('query4'), isNotNull);
    });

    test('最も古いエントリが削除される', () {
      // Arrange
      final smallCache = SearchCache(maxSize: 2);
      const results1 = [
        CurrencySearchResult(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          marketCapRank: 1,
        ),
      ];
      const results2 = [
        CurrencySearchResult(
          id: 'ethereum',
          symbol: 'ETH',
          name: 'Ethereum',
          marketCapRank: 2,
        ),
      ];
      const results3 = [
        CurrencySearchResult(
          id: 'cardano',
          symbol: 'ADA',
          name: 'Cardano',
          marketCapRank: 3,
        ),
      ];

      // Act
      smallCache.put('bitcoin', results1); // 最も古い
      smallCache.put('ethereum', results2);
      smallCache.put('cardano', results3); // bitcoinが削除される

      // Assert
      expect(smallCache.get('bitcoin'), isNull);
      expect(smallCache.get('ethereum'), equals(results2));
      expect(smallCache.get('cardano'), equals(results3));
    });
  });

  group('SearchCache - クリア機能', () {
    test('clearですべてのキャッシュが削除される', () {
      // Arrange
      const results = [
        CurrencySearchResult(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          marketCapRank: 1,
        ),
      ];
      searchCache.put('query1', results);
      searchCache.put('query2', results);
      searchCache.put('query3', results);

      // Act
      searchCache.clear();

      // Assert
      expect(searchCache.get('query1'), isNull);
      expect(searchCache.get('query2'), isNull);
      expect(searchCache.get('query3'), isNull);
    });

    test('クリア後に新しいエントリを追加できる', () {
      // Arrange
      const results = [
        CurrencySearchResult(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          marketCapRank: 1,
        ),
      ];
      searchCache.put('old', results);
      searchCache.clear();

      // Act
      searchCache.put('new', results);

      // Assert
      expect(searchCache.get('old'), isNull);
      expect(searchCache.get('new'), equals(results));
    });
  });

  group('SearchCache - エッジケース', () {
    test('空のリストをキャッシュできる', () {
      // Arrange
      const query = 'nonexistent';
      const results = <CurrencySearchResult>[];

      // Act
      searchCache.put(query, results);
      final cachedResults = searchCache.get(query);

      // Assert
      expect(cachedResults, equals(results));
      expect(cachedResults, isEmpty);
    });

    test('同じキーで上書きできる', () {
      // Arrange
      const query = 'bitcoin';
      const results1 = [
        CurrencySearchResult(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          marketCapRank: 1,
        ),
      ];
      const results2 = [
        CurrencySearchResult(
          id: 'bitcoin-cash',
          symbol: 'BCH',
          name: 'Bitcoin Cash',
          marketCapRank: 20,
        ),
      ];

      // Act
      searchCache.put(query, results1);
      searchCache.put(query, results2);
      final cachedResults = searchCache.get(query);

      // Assert
      expect(cachedResults, equals(results2));
    });

    test('大文字小文字を区別する', () {
      // Arrange
      const results = [
        CurrencySearchResult(
          id: 'bitcoin',
          symbol: 'BTC',
          name: 'Bitcoin',
          marketCapRank: 1,
        ),
      ];

      // Act
      searchCache.put('Bitcoin', results);

      // Assert
      expect(searchCache.get('Bitcoin'), equals(results));
      expect(searchCache.get('bitcoin'), isNull); // 異なるキー
    });
  });
}
