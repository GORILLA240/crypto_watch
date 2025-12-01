import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/favorite_model.dart';

/// お気に入りのローカルデータソース抽象クラス
abstract class FavoritesLocalDataSource {
  /// お気に入りリストを取得
  Future<List<FavoriteModel>> getFavorites();

  /// お気に入りを追加
  Future<void> addFavorite(FavoriteModel favorite);

  /// お気に入りを削除
  Future<void> removeFavorite(String symbol);

  /// お気に入りリストを並び替えて保存
  Future<void> reorderFavorites(List<FavoriteModel> favorites);

  /// お気に入りが存在するかチェック
  Future<bool> isFavorite(String symbol);
}

/// お気に入りのローカルデータソース実装
class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  final LocalStorage localStorage;

  FavoritesLocalDataSourceImpl({required this.localStorage});

  @override
  Future<List<FavoriteModel>> getFavorites() async {
    try {
      final jsonString = await localStorage.getString(AppConstants.favoritesKey);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      final favorites = jsonList
          .map((item) => FavoriteModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // 順序でソート
      favorites.sort((a, b) => a.order.compareTo(b.order));
      return favorites;
    } catch (e) {
      throw StorageException(
        message: 'お気に入りの読み込みに失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<void> addFavorite(FavoriteModel favorite) async {
    try {
      final favorites = await getFavorites();

      // 既に存在する場合は何もしない
      if (favorites.any((f) => f.symbol == favorite.symbol)) {
        return;
      }

      favorites.add(favorite);
      await _saveFavorites(favorites);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'お気に入りの追加に失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<void> removeFavorite(String symbol) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((f) => f.symbol == symbol);

      // 順序を再調整
      for (var i = 0; i < favorites.length; i++) {
        favorites[i] = favorites[i].copyWith(order: i);
      }

      await _saveFavorites(favorites);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'お気に入りの削除に失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<void> reorderFavorites(List<FavoriteModel> favorites) async {
    try {
      // 順序を更新
      final reordered = <FavoriteModel>[];
      for (var i = 0; i < favorites.length; i++) {
        reordered.add(favorites[i].copyWith(order: i));
      }

      await _saveFavorites(reordered);
    } catch (e) {
      throw StorageException(
        message: 'お気に入りの並び替えに失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> isFavorite(String symbol) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((f) => f.symbol == symbol);
    } catch (e) {
      return false;
    }
  }

  /// お気に入りリストを保存
  Future<void> _saveFavorites(List<FavoriteModel> favorites) async {
    final jsonList = favorites.map((f) => f.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await localStorage.setString(AppConstants.favoritesKey, jsonString);
  }
}
