import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/favorite.dart';

/// お気に入りリポジトリの抽象インターフェース
abstract class FavoritesRepository {
  /// お気に入りリストを取得
  Future<Either<Failure, List<Favorite>>> getFavorites();

  /// お気に入りを追加
  Future<Either<Failure, void>> addFavorite(String symbol);

  /// お気に入りを削除
  Future<Either<Failure, void>> removeFavorite(String symbol);

  /// お気に入りを並び替え
  Future<Either<Failure, void>> reorderFavorites(List<Favorite> favorites);
}
