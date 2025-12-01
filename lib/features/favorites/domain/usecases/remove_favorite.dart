import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/favorites_repository.dart';

/// お気に入りを削除するユースケース
class RemoveFavorite {
  final FavoritesRepository repository;

  RemoveFavorite(this.repository);

  Future<Either<Failure, void>> call(String symbol) async {
    return await repository.removeFavorite(symbol);
  }
}
