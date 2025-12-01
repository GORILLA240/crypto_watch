import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_settings.dart';

/// 設定リポジトリの抽象インターフェース
abstract class SettingsRepository {
  /// 設定を取得
  Future<Either<Failure, AppSettings>> getSettings();

  /// 設定を更新
  Future<Either<Failure, void>> updateSettings(AppSettings settings);
}
