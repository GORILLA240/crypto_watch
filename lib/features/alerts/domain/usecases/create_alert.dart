import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/price_alert.dart';
import '../repositories/alerts_repository.dart';

/// アラートを作成するユースケース
class CreateAlert {
  final AlertsRepository repository;

  CreateAlert(this.repository);

  Future<Either<Failure, void>> call(PriceAlert alert) async {
    return await repository.createAlert(alert);
  }
}
