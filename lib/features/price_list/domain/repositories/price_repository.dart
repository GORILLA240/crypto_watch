import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/crypto_price.dart';

/// 価格データリポジトリの抽象インターフェース
abstract class PriceRepository {
  /// 指定されたシンボルの価格データを取得
  Future<Either<Failure, List<CryptoPrice>>> getPrices(List<String> symbols);

  /// 単一のシンボルの価格データを取得
  Future<Either<Failure, CryptoPrice>> getPriceBySymbol(String symbol);

  /// 価格データをリフレッシュ
  Future<Either<Failure, List<CryptoPrice>>> refreshPrices();
}
