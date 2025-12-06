import '../models/currency_search_result.dart';

/// キャッシュエントリ
class _CacheEntry {
  final List<CurrencySearchResult> results;
  final DateTime timestamp;

  _CacheEntry(this.results, this.timestamp);
}

/// 検索結果のインメモリキャッシュ
/// TTL（Time To Live）とLRU（Least Recently Used）アルゴリズムを実装
class SearchCache {
  final Map<String, _CacheEntry> _cache = {};
  final Duration _ttl;
  final int _maxSize;

  /// コンストラクタ
  /// [ttl] キャッシュの有効期限（デフォルト: 5分）
  /// [maxSize] 最大キャッシュサイズ（デフォルト: 50）
  SearchCache({
    Duration? ttl,
    int? maxSize,
  })  : _ttl = ttl ?? const Duration(minutes: 5),
        _maxSize = maxSize ?? 50;

  /// キャッシュから検索結果を取得
  /// [query] 検索クエリ
  /// 返り値: キャッシュされた結果、または期限切れ/存在しない場合はnull
  List<CurrencySearchResult>? get(String query) {
    final entry = _cache[query];
    if (entry == null) {
      return null;
    }

    // TTLチェック
    if (DateTime.now().difference(entry.timestamp) > _ttl) {
      _cache.remove(query);
      return null;
    }

    return entry.results;
  }

  /// 検索結果をキャッシュに保存
  /// [query] 検索クエリ
  /// [results] 検索結果
  void put(String query, List<CurrencySearchResult> results) {
    // キャッシュサイズが上限に達している場合、最も古いエントリを削除
    if (_cache.length >= _maxSize) {
      _evictOldest();
    }

    _cache[query] = _CacheEntry(results, DateTime.now());
  }

  /// 最も古いエントリを削除（LRUアルゴリズム）
  void _evictOldest() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    _cache.forEach((key, entry) {
      if (oldestTime == null || entry.timestamp.isBefore(oldestTime!)) {
        oldestKey = key;
        oldestTime = entry.timestamp;
      }
    });

    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }

  /// キャッシュをクリア
  void clear() {
    _cache.clear();
  }

  /// キャッシュサイズを取得
  int get size => _cache.length;

  /// キャッシュが空かどうか
  bool get isEmpty => _cache.isEmpty;

  /// キャッシュが空でないかどうか
  bool get isNotEmpty => _cache.isNotEmpty;
}
