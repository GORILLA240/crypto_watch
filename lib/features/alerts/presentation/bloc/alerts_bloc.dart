import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/check_alerts.dart';
import '../../domain/usecases/create_alert.dart';
import '../../domain/usecases/delete_alert.dart';
import 'alerts_event.dart';
import 'alerts_state.dart';

/// アラートのBloc
class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  final CheckAlerts checkAlerts;
  final CreateAlert createAlert;
  final DeleteAlert deleteAlert;

  AlertsBloc({
    required this.checkAlerts,
    required this.createAlert,
    required this.deleteAlert,
  }) : super(const AlertsInitial()) {
    on<CheckAlertsEvent>(_onCheckAlerts);
    on<CreateAlertEvent>(_onCreateAlert);
    on<DeleteAlertEvent>(_onDeleteAlert);
  }

  Future<void> _onCheckAlerts(
    CheckAlertsEvent event,
    Emitter<AlertsState> emit,
  ) async {
    final result = await checkAlerts(event.currentPrices);

    result.fold(
      (failure) => emit(AlertsError(message: failure.message)),
      (triggeredAlerts) {
        if (triggeredAlerts.isEmpty) {
          emit(const AlertsIdle());
        } else {
          emit(AlertsTriggered(triggeredAlerts: triggeredAlerts));
        }
      },
    );
  }

  Future<void> _onCreateAlert(
    CreateAlertEvent event,
    Emitter<AlertsState> emit,
  ) async {
    final result = await createAlert(event.alert);

    result.fold(
      (failure) => emit(AlertsError(message: failure.message)),
      (_) => emit(const AlertsIdle()),
    );
  }

  Future<void> _onDeleteAlert(
    DeleteAlertEvent event,
    Emitter<AlertsState> emit,
  ) async {
    final result = await deleteAlert(event.alertId);

    result.fold(
      (failure) => emit(AlertsError(message: failure.message)),
      (_) => emit(const AlertsIdle()),
    );
  }
}
