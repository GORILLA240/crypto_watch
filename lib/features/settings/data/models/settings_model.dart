import '../../domain/entities/app_settings.dart';

/// アプリ設定モデル
class SettingsModel extends AppSettings {
  const SettingsModel({
    required super.displayCurrency,
    required super.autoRefreshEnabled,
    required super.refreshIntervalSeconds,
    required super.notificationsEnabled,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    try {
      return SettingsModel(
        displayCurrency: Currency.fromCode(
          json['display_currency'] as String? ?? 'JPY',
        ),
        autoRefreshEnabled: json['auto_refresh_enabled'] as bool? ?? true,
        refreshIntervalSeconds: json['refresh_interval_seconds'] as int? ?? 30,
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      );
    } catch (e) {
      throw FormatException('Failed to parse SettingsModel from JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'display_currency': displayCurrency.code,
      'auto_refresh_enabled': autoRefreshEnabled,
      'refresh_interval_seconds': refreshIntervalSeconds,
      'notifications_enabled': notificationsEnabled,
    };
  }

  factory SettingsModel.fromEntity(AppSettings entity) {
    return SettingsModel(
      displayCurrency: entity.displayCurrency,
      autoRefreshEnabled: entity.autoRefreshEnabled,
      refreshIntervalSeconds: entity.refreshIntervalSeconds,
      notificationsEnabled: entity.notificationsEnabled,
    );
  }

  AppSettings toEntity() {
    return AppSettings(
      displayCurrency: displayCurrency,
      autoRefreshEnabled: autoRefreshEnabled,
      refreshIntervalSeconds: refreshIntervalSeconds,
      notificationsEnabled: notificationsEnabled,
    );
  }

  factory SettingsModel.defaultSettings() {
    return const SettingsModel(
      displayCurrency: Currency.jpy,
      autoRefreshEnabled: true,
      refreshIntervalSeconds: 30,
      notificationsEnabled: true,
    );
  }

  @override
  SettingsModel copyWith({
    Currency? displayCurrency,
    bool? autoRefreshEnabled,
    int? refreshIntervalSeconds,
    bool? notificationsEnabled,
  }) {
    return SettingsModel(
      displayCurrency: displayCurrency ?? this.displayCurrency,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      refreshIntervalSeconds: refreshIntervalSeconds ?? this.refreshIntervalSeconds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
