import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/favorite.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_datasource.dart';
import '../models/favorite_model.dart';

/// お気に入りリポジトリの実装
class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesLocalDataSource localDataSource;

  FavoritesRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Favorite>>> getFavorites() async {
    try {
      final favorites = await localDataSource.getFavorites();
      return Right(favorites);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addFavorite(String symbol) async {
    try {
      final favorites = await localDataSource.getFavorites();
      final newOrder = favorites.length;

      final favorite = FavoriteModel(
        symbol: symbol,
        order: newOrder,
        addedAt: DateTime.now(),
      );

      await localDataSource.addFavorite(favorite);
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFavorite(String symbol) async {
    try {
      await localDataSource.removeFavorite(symbol);
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reorderFavorites(
      List<Favorite> favorites) async {
    try {
      final models = favorites
          .map((f) => FavoriteModel(
                symbol: f.symbol,
                order: f.order,
                addedAt: f.addedAt,
              ))
          .toList();

      await localDataSource.reorderFavorites(models);
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
