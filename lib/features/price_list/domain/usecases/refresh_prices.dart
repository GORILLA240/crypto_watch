import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/crypto_price.dart';
import '../repositories/price_repository.dart';

/// 価格データをリフレッシュするユースケース
class RefreshPrices {
  final PriceRepository repository;

  RefreshPrices(this.repository);

  /// すべての価格データをリフレッシュ
  Future<Either<Failure, List<CryptoPrice>>> call() async {
    return await repository.refreshPrices();
  }
}
