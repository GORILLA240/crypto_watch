import 'package:equatable/equatable.dart';
import '../../domain/entities/app_settings.dart';

/// 設定の状態
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// 読み込み中
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// 読み込み完了
class SettingsLoaded extends SettingsState {
  final AppSettings settings;

  const SettingsLoaded({required this.settings});

  @override
  List<Object?> get props => [settings];
}

/// エラー
class SettingsError extends SettingsState {
  final String message;

  const SettingsError({required this.message});

  @override
  List<Object?> get props => [message];
}
