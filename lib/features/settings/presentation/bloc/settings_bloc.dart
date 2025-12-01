import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_settings.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// 設定のBloc
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final UpdateSettings updateSettings;

  SettingsBloc({
    required this.getSettings,
    required this.updateSettings,
  }) : super(const SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    final result = await getSettings();

    result.fold(
      (failure) => emit(SettingsError(message: failure.message)),
      (settings) => emit(SettingsLoaded(settings: settings)),
    );
  }

  Future<void> _onUpdateSettings(
    UpdateSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await updateSettings(event.settings);

    await result.fold(
      (failure) async => emit(SettingsError(message: failure.message)),
      (_) async {
        // 設定を再読み込み
        final settingsResult = await getSettings();
        settingsResult.fold(
          (failure) => emit(SettingsError(message: failure.message)),
          (settings) => emit(SettingsLoaded(settings: settings)),
        );
      },
    );
  }
}
