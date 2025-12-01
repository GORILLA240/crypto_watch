import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/favorite.dart';
import '../repositories/favorites_repository.dart';

/// お気に入りリストを取得するユースケース
class GetFavorites {
  final FavoritesRepository repository;

  GetFavorites(this.repository);

  Future<Either<Failure, List<Favorite>>> call() async {
    return await repository.getFavorites();
  }
}
