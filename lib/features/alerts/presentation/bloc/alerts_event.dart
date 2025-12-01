import 'package:equatable/equatable.dart';
import '../../domain/entities/price_alert.dart';

/// アラートのイベント
abstract class AlertsEvent extends Equatable {
  const AlertsEvent();

  @override
  List<Object?> get props => [];
}

/// アラートをチェック
class CheckAlertsEvent extends AlertsEvent {
  final Map<String, double> currentPrices;

  const CheckAlertsEvent({required this.currentPrices});

  @override
  List<Object?> get props => [currentPrices];
}

/// アラートを作成
class CreateAlertEvent extends AlertsEvent {
  final PriceAlert alert;

  const CreateAlertEvent({required this.alert});

  @override
  List<Object?> get props => [alert];
}

/// アラートを削除
class DeleteAlertEvent extends AlertsEvent {
  final String alertId;

  const DeleteAlertEvent({required this.alertId});

  @override
  List<Object?> get props => [alertId];
}
