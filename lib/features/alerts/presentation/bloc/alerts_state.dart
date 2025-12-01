import 'package:equatable/equatable.dart';
import '../../domain/entities/price_alert.dart';

/// アラートの状態
abstract class AlertsState extends Equatable {
  const AlertsState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class AlertsInitial extends AlertsState {
  const AlertsInitial();
}

/// アラートなし
class AlertsIdle extends AlertsState {
  const AlertsIdle();
}

/// アラート発火
class AlertsTriggered extends AlertsState {
  final List<PriceAlert> triggeredAlerts;

  const AlertsTriggered({required this.triggeredAlerts});

  @override
  List<Object?> get props => [triggeredAlerts];
}

/// エラー
class AlertsError extends AlertsState {
  final String message;

  const AlertsError({required this.message});

  @override
  List<Object?> get props => [message];
}
