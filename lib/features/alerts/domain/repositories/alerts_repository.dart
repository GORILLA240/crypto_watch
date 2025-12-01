import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/price_alert.dart';

/// アラートリポジトリの抽象インターフェース
abstract class AlertsRepository {
  /// すべてのアラートを取得
  Future<Either<Failure, List<PriceAlert>>> getAlerts();

  /// アラートを作成
  Future<Either<Failure, void>> createAlert(PriceAlert alert);

  /// アラートを削除
  Future<Either<Failure, void>> deleteAlert(String alertId);

  /// アラートを更新
  Future<Either<Failure, void>> updateAlert(PriceAlert alert);
}
