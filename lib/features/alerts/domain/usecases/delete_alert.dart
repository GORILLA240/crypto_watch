import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/alerts_repository.dart';

/// アラートを削除するユースケース
class DeleteAlert {
  final AlertsRepository repository;

  DeleteAlert(this.repository);

  Future<Either<Failure, void>> call(String alertId) async {
    return await repository.deleteAlert(alertId);
  }
}
