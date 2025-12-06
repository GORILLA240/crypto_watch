import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorites_currency.dart';

/// お気に入り通貨管理マネージャー
/// デフォルト通貨とカスタム通貨を統合管理する
class FavoritesManager {
  static const String _storageKey = 'favorites_currencies';

  /// デフォルト通貨20種類
  static const List<String> defaultCurrencies = [
    'BTC', // Bitcoin
    'ETH', // Ethereum
    'ADA', // Cardano
    'BNB', // Binance Coin
    'XRP', // Ripple
    'SOL', // Solana
    'DOT', // Polkadot
    'DOGE', // Dogecoin
    'AVAX', // Avalanche
    'MATIC', // Polygon
    'LINK', // Chainlink
    'UNI', // Uniswap
    'LTC', // Litecoin
    'ATOM', // Cosmos
    'XLM', // Stellar
    'ALGO', // Algorand
    'VET', // VeChain
    'ICP', // Internet Computer
    'FIL', // Filecoin
    'TRX', // TRON
  ];

  final SharedPreferences _prefs;

  FavoritesManager(this._prefs);

  /// お気に入りリストを取得
  /// 初回起動時はデフォルト通貨を返す
  Future<List<FavoritesCurrency>> getFavorites() async {
    try {
      final jsonString = _prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        // 初回起動時: デフォルト通貨を初期化
        return _initializeDefaultCurrencies();
      }

      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      final favorites = jsonList
          .map((item) => FavoritesCurrency.fromJson(item as Map<String, dynamic>))
          .toList();

      // 表示順序でソート
      favorites.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      return favorites;
    } catch (e) {
      // エラー時はデフォルト通貨を返す
      return _initializeDefaultCurrencies();
    }
  }

  /// お気に入りに通貨を追加
  Future<void> addFavorite(String symbol) async {
    try {
      final favorites = await getFavorites();

      // 既に存在する場合は何もしない
      if (favorites.any((f) => f.symbol.toUpperCase() == symbol.toUpperCase())) {
        return;
      }

      // 新しいカスタム通貨を追加
      final newFavorite = FavoritesCurrency(
        symbol: symbol.toUpperCase(),
        isDefault: false,
        addedAt: DateTime.now(),
        displayOrder: favorites.length,
      );

      favorites.add(newFavorite);
      await _saveFavorites(favorites);
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  /// お気に入りから通貨を削除
  Future<void> removeFavorite(String symbol) async {
    try {
      final favorites = await getFavorites();
      final upperSymbol = symbol.toUpperCase();

      // 削除
      favorites.removeWhere((f) => f.symbol.toUpperCase() == upperSymbol);

      // 表示順序を再調整
      final reordered = <FavoritesCurrency>[];
      for (var i = 0; i < favorites.length; i++) {
        reordered.add(favorites[i].copyWith(displayOrder: i));
      }

      await _saveFavorites(reordered);
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  /// 通貨がデフォルト通貨かどうかを判定
  bool isDefaultCurrency(String symbol) {
    return defaultCurrencies.contains(symbol.toUpperCase());
  }

  /// 通貨がカスタム通貨かどうかを判定
  bool isCustomCurrency(String symbol) {
    return !isDefaultCurrency(symbol);
  }

  /// お気に入りリストを並び替えて保存
  Future<void> reorderFavorites(List<FavoritesCurrency> favorites) async {
    try {
      // 表示順序を更新
      final reordered = <FavoritesCurrency>[];
      for (var i = 0; i < favorites.length; i++) {
        reordered.add(favorites[i].copyWith(displayOrder: i));
      }

      await _saveFavorites(reordered);
    } catch (e) {
      throw Exception('Failed to reorder favorites: $e');
    }
  }

  /// デフォルト通貨を初期化
  Future<List<FavoritesCurrency>> _initializeDefaultCurrencies() async {
    final now = DateTime.now();
    final favorites = <FavoritesCurrency>[];

    for (var i = 0; i < defaultCurrencies.length; i++) {
      favorites.add(
        FavoritesCurrency(
          symbol: defaultCurrencies[i],
          isDefault: true,
          addedAt: now,
          displayOrder: i,
        ),
      );
    }

    // 初期化したデフォルト通貨を保存
    await _saveFavorites(favorites);

    return favorites;
  }

  /// お気に入りリストを保存
  Future<void> _saveFavorites(List<FavoritesCurrency> favorites) async {
    try {
      final jsonList = favorites.map((f) => f.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_storageKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save favorites: $e');
    }
  }

  /// ストレージをクリア（テスト用）
  Future<void> clearFavorites() async {
    await _prefs.remove(_storageKey);
  }
}
