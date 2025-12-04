import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/display_density.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/currency_selector.dart';

/// 設定画面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // グローバルなSettingsBlocを使用
    return const _SettingsPageContent();
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
                    activeTrackColor: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  // Display density selector
                  const Text(
                    '表示密度',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1画面に表示される銘柄の数を調整します',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDisplayDensitySelector(context, state.settings),
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
                    activeTrackColor: Colors.blue,
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

  Widget _buildDisplayDensitySelector(BuildContext context, settings) {
    return Column(
      children: [
        _buildDensityOption(
          context,
          settings,
          DisplayDensity.standard,
          '標準',
          '3〜5銘柄/画面',
        ),
        const SizedBox(height: 8),
        _buildDensityOption(
          context,
          settings,
          DisplayDensity.compact,
          'コンパクト',
          '6〜8銘柄/画面',
        ),
        const SizedBox(height: 8),
        _buildDensityOption(
          context,
          settings,
          DisplayDensity.maximum,
          '最大',
          '9〜12銘柄/画面',
        ),
      ],
    );
  }

  Widget _buildDensityOption(
    BuildContext context,
    settings,
    DisplayDensity density,
    String label,
    String description,
  ) {
    final isSelected = settings.displayDensity == density;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withValues(alpha: 0.2) : Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[800]!,
          width: 2,
        ),
      ),
      child: RadioListTile<DisplayDensity>(
        value: density,
        groupValue: settings.displayDensity,
        onChanged: (value) {
          if (value != null) {
            final updatedSettings = settings.copyWith(
              displayDensity: value,
            );
            context.read<SettingsBloc>().add(
                  UpdateSettingsEvent(settings: updatedSettings),
                );
          }
        },
        activeColor: Colors.blue,
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
