import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/favorite.dart';
import '../repositories/favorites_repository.dart';

/// お気に入りを並び替えるユースケース
class ReorderFavorites {
  final FavoritesRepository repository;

  ReorderFavorites(this.repository);

  Future<Either<Failure, void>> call(List<Favorite> favorites) async {
    return await repository.reorderFavorites(favorites);
  }
}
