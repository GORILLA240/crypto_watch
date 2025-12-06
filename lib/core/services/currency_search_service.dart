import 'dart:async';
import '../models/currency_search_result.dart';
import 'coingecko_api_client.dart';
import 'search_cache.dart';

/// 通貨検索サービス
/// リアルタイムサジェスト、デバウンス処理、キャッシングを提供
class CurrencySearchService {
  final CoinGeckoApiClient _apiClient;
  final SearchCache _cache;
  final StreamController<String> _searchController = StreamController<String>();
  final Duration _debounceDuration;

  StreamSubscription<List<CurrencySearchResult>>? _searchSubscription;

  /// コンストラクタ
  /// [apiClient] CoinGecko APIクライアント
  /// [cache] 検索結果キャッシュ
  /// [debounceDuration] デバウンス期間（デフォルト: 300ms）
  CurrencySearchService({
    required CoinGeckoApiClient apiClient,
    SearchCache? cache,
    Duration? debounceDuration,
  })  : _apiClient = apiClient,
        _cache = cache ?? SearchCache(),
        _debounceDuration = debounceDuration ?? const Duration(milliseconds: 300);

  /// 通貨を検索
  /// [query] 検索クエリ
  /// 返り値: 検索結果のリスト
  Future<List<CurrencySearchResult>> searchCurrencies(String query) async {
    // 空のクエリの場合は空リストを返す
    if (query.trim().isEmpty) {
      return [];
    }

    // キャッシュをチェック
    final cachedResults = _cache.get(query);
    if (cachedResults != null) {
      return cachedResults;
    }

    // APIから検索
    final results = await _apiClient.searchCoins(query, limit: 10);

    // 時価総額順でソート（ランクが小さいほど上位）
    results.sort((a, b) => a.marketCapRank.compareTo(b.marketCapRank));

    // キャッシュに保存
    _cache.put(query, results);

    return results;
  }

  /// リアルタイムサジェストのストリームを取得
  /// [query] 検索クエリ
  /// 返り値: 検索結果のストリーム
  Stream<List<CurrencySearchResult>> getSuggestions(String query) async* {
    // 2文字未満の場合は空リストを返す
    if (query.trim().length < 2) {
      yield [];
      return;
    }

    // デバウンス処理を適用
    _searchController.add(query);

    // デバウンス期間待機
    await Future.delayed(_debounceDuration);

    // 最新のクエリを取得
    try {
      final results = await searchCurrencies(query);
      yield results;
    } catch (e) {
      // エラーの場合は空リストを返す
      yield [];
    }
  }

  /// デバウンス付きサジェストストリームを初期化
  /// 返り値: 検索結果のストリーム
  Stream<List<CurrencySearchResult>> get suggestionsStream {
    return _searchController.stream
        .distinct() // 重複するクエリをフィルタ
        .asyncMap((query) async {
      // デバウンス期間待機
      await Future.delayed(_debounceDuration);

      // 2文字未満の場合は空リストを返す
      if (query.trim().length < 2) {
        return <CurrencySearchResult>[];
      }

      try {
        return await searchCurrencies(query);
      } catch (e) {
        // エラーの場合は空リストを返す
        return <CurrencySearchResult>[];
      }
    });
  }

  /// 検索クエリを送信
  /// [query] 検索クエリ
  void search(String query) {
    _searchController.add(query);
  }

  /// キャッシュをクリア
  void clearCache() {
    _cache.clear();
  }

  /// サービスを破棄
  void dispose() {
    _searchSubscription?.cancel();
    _searchController.close();
    _apiClient.dispose();
  }
}
