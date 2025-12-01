import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/crypto_price_model.dart';

/// 価格データのローカルデータソース抽象クラス
abstract class PriceLocalDataSource {
  /// キャッシュされた価格データを取得
  Future<List<CryptoPriceModel>> getCachedPrices();

  /// 価格データをキャッシュに保存
  Future<void> cachePrices(List<CryptoPriceModel> prices);

  /// キャッシュをクリア
  Future<void> clearCache();

  /// キャッシュが有効かチェック
  Future<bool> isCacheValid();
}

/// 価格データのローカルデータソース実装
class PriceLocalDataSourceImpl implements PriceLocalDataSource {
  final LocalStorage localStorage;
  static const String _cacheKey = 'cached_prices';
  static const String _cacheTimestampKey = 'cached_prices_timestamp';

  PriceLocalDataSourceImpl({required this.localStorage});

  @override
  Future<List<CryptoPriceModel>> getCachedPrices() async {
    try {
      final jsonString = await localStorage.getString(_cacheKey);
      if (jsonString == null) {
        throw CacheException(message: 'キャッシュが見つかりません');
      }

      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((item) => CryptoPriceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(
        message: 'キャッシュの読み込みに失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<void> cachePrices(List<CryptoPriceModel> prices) async {
    try {
      final jsonList = prices.map((price) => price.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await localStorage.setString(_cacheKey, jsonString);
      await localStorage.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw CacheException(
        message: 'キャッシュの保存に失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await localStorage.remove(_cacheKey);
      await localStorage.remove(_cacheTimestampKey);
    } catch (e) {
      throw CacheException(
        message: 'キャッシュのクリアに失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> isCacheValid() async {
    try {
      final timestamp = await localStorage.getInt(_cacheTimestampKey);
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      return difference < AppConstants.cacheValidDuration;
    } catch (e) {
      return false;
    }
  }
}
