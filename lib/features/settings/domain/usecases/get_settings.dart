import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

/// 設定を取得するユースケース
class GetSettings {
  final SettingsRepository repository;

  GetSettings(this.repository);

  Future<Either<Failure, AppSettings>> call() async {
    return await repository.getSettings();
  }
}
