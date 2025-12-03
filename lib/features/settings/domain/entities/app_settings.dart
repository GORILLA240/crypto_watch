import 'package:equatable/equatable.dart';
import '../../../../core/utils/display_density.dart';

/// 通貨の列挙型
enum Currency {
  jpy('JPY'),
  usd('USD'),
  eur('EUR'),
  btc('BTC');

  final String code;
  const Currency(this.code);

  static Currency fromCode(String code) {
    return Currency.values.firstWhere(
      (c) => c.code == code.toUpperCase(),
      orElse: () => Currency.jpy,
    );
  }
}

/// アプリ設定エンティティ
class AppSettings extends Equatable {
  final Currency displayCurrency;
  final bool autoRefreshEnabled;
  final int refreshIntervalSeconds;
  final bool notificationsEnabled;
  final DisplayDensity displayDensity;

  const AppSettings({
    required this.displayCurrency,
    required this.autoRefreshEnabled,
    required this.refreshIntervalSeconds,
    required this.notificationsEnabled,
    required this.displayDensity,
  });

  /// デフォルト設定
  factory AppSettings.defaultSettings() {
    return const AppSettings(
      displayCurrency: Currency.jpy,
      autoRefreshEnabled: true,
      refreshIntervalSeconds: 30,
      notificationsEnabled: true,
      displayDensity: DisplayDensity.standard,
    );
  }

  @override
  List<Object?> get props => [
        displayCurrency,
        autoRefreshEnabled,
        refreshIntervalSeconds,
        notificationsEnabled,
        displayDensity,
      ];

  AppSettings copyWith({
    Currency? displayCurrency,
    bool? autoRefreshEnabled,
    int? refreshIntervalSeconds,
    bool? notificationsEnabled,
    DisplayDensity? displayDensity,
  }) {
    return AppSettings(
      displayCurrency: displayCurrency ?? this.displayCurrency,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      refreshIntervalSeconds: refreshIntervalSeconds ?? this.refreshIntervalSeconds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      displayDensity: displayDensity ?? this.displayDensity,
    );
  }

  @override
  String toString() {
    return 'AppSettings(displayCurrency: ${displayCurrency.code}, '
        'autoRefreshEnabled: $autoRefreshEnabled, '
        'refreshIntervalSeconds: $refreshIntervalSeconds, '
        'notificationsEnabled: $notificationsEnabled, '
        'displayDensity: ${displayDensity.name})';
  }
}
