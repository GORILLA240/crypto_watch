import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/price_alert.dart';
import '../repositories/alerts_repository.dart';

/// アラートをチェックして発火すべきものを返すユースケース
class CheckAlerts {
  final AlertsRepository repository;

  CheckAlerts(this.repository);

  /// 現在の価格に基づいてアラートをチェック
  Future<Either<Failure, List<PriceAlert>>> call(
      Map<String, double> currentPrices) async {
    final alertsResult = await repository.getAlerts();

    return alertsResult.fold(
      (failure) => Left(failure),
      (alerts) {
        final triggeredAlerts = alerts.where((alert) {
          final currentPrice = currentPrices[alert.symbol];
          if (currentPrice == null) return false;
          return alert.shouldTrigger(currentPrice);
        }).toList();

        return Right(triggeredAlerts);
      },
    );
  }
}
