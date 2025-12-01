import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/price_alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../datasources/alerts_local_datasource.dart';
import '../models/alert_model.dart';

/// アラートリポジトリの実装
class AlertsRepositoryImpl implements AlertsRepository {
  final AlertsLocalDataSource localDataSource;

  AlertsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<PriceAlert>>> getAlerts() async {
    try {
      final alerts = await localDataSource.getAlerts();
      return Right(alerts);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createAlert(PriceAlert alert) async {
    try {
      final model = AlertModel.fromEntity(alert);
      await localDataSource.createAlert(model);
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAlert(String alertId) async {
    try {
      await localDataSource.deleteAlert(alertId);
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateAlert(PriceAlert alert) async {
    try {
      final model = AlertModel.fromEntity(alert);
      await localDataSource.updateAlert(model);
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
