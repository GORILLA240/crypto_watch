import 'package:equatable/equatable.dart';
import '../../domain/entities/app_settings.dart';

/// 設定のイベント
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// 設定を読み込む
class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

/// 設定を更新
class UpdateSettingsEvent extends SettingsEvent {
  final AppSettings settings;

  const UpdateSettingsEvent({required this.settings});

  @override
  List<Object?> get props => [settings];
}
