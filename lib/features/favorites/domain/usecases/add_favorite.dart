import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/favorites_repository.dart';

/// お気に入りを追加するユースケース
class AddFavorite {
  final FavoritesRepository repository;

  AddFavorite(this.repository);

  Future<Either<Failure, void>> call(String symbol) async {
    return await repository.addFavorite(symbol);
  }
}
