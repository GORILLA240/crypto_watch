import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/crypto_price.dart';
import '../repositories/price_repository.dart';

/// 価格データを取得するユースケース
class GetPrices {
  final PriceRepository repository;

  GetPrices(this.repository);

  /// 指定されたシンボルの価格データを取得
  Future<Either<Failure, List<CryptoPrice>>> call(List<String> symbols) async {
    return await repository.getPrices(symbols);
  }
}
