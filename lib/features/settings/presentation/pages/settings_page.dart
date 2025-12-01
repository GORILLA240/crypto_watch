import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/currency_selector.dart';

/// 設定画面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsBloc>()..add(const LoadSettingsEvent()),
      child: const _SettingsPageContent(),
    );
  }
}

class _SettingsPageContent extends StatelessWidget {
  const _SettingsPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          '設定',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          if (state is SettingsError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          if (state is SettingsLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Currency selector
                  CurrencySelector(
                    selectedCurrency: state.settings.displayCurrency,
                    onCurrencyChanged: (currency) {
                      final updatedSettings = state.settings.copyWith(
                        displayCurrency: currency,
                      );
                      context.read<SettingsBloc>().add(
                            UpdateSettingsEvent(settings: updatedSettings),
                          );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Auto refresh toggle
                  const Text(
                    '自動更新',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      '自動更新を有効にする',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    subtitle: Text(
                      '${state.settings.refreshIntervalSeconds}秒ごとに更新',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    value: state.settings.autoRefreshEnabled,
                    onChanged: (value) {
                      final updatedSettings = state.settings.copyWith(
                        autoRefreshEnabled: value,
                      );
                      context.read<SettingsBloc>().add(
                            UpdateSettingsEvent(settings: updatedSettings),
                          );
                    },
                    activeColor: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  // Notifications toggle
                  const Text(
                    '通知',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      '通知を有効にする',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    subtitle: const Text(
                      'アラート発火時に通知を受け取る',
                      style: TextStyle(color: Colors.grey),
                    ),
                    value: state.settings.notificationsEnabled,
                    onChanged: (value) {
                      final updatedSettings = state.settings.copyWith(
                        notificationsEnabled: value,
                      );
                      context.read<SettingsBloc>().add(
                            UpdateSettingsEvent(settings: updatedSettings),
                          );
                    },
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
