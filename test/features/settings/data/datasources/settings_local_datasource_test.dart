import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:crypto_watch/features/settings/data/models/settings_model.dart';
import 'package:crypto_watch/features/settings/domain/entities/app_settings.dart';
import 'package:crypto_watch/core/storage/local_storage.dart';
import 'package:crypto_watch/core/utils/display_density.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsLocalDataSourceImpl dataSource;
  late LocalStorage localStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();
    localStorage = LocalStorageImpl(sharedPreferences: sharedPreferences);
    dataSource = SettingsLocalDataSourceImpl(localStorage: localStorage);
  });

  group('SettingsLocalDataSource', () {
    group('Property 8: ローカルストレージの永続性', () {
      test(
        '**Feature: crypto-watch-frontend, Property 8: ローカルストレージの永続性** - '
        '**Validates: Requirements 11.4, 15.4** - '
        'アプリ再起動後も同じデータが読み込まれるべき',
        () async {
          // Property-based test: 様々な設定で永続性を検証
          final currencies = [Currency.jpy, Currency.usd, Currency.eur, Currency.btc];

          for (var testCase = 0; testCase < 50; testCase++) {
            // テストケースごとにストレージをクリア
            await localStorage.clear();

            // ランダムな設定を生成
            final originalSettings = SettingsModel(
              displayCurrency: currencies[testCase % currencies.length],
              autoRefreshEnabled: testCase % 2 == 0,
              refreshIntervalSeconds: 30 + (testCase % 5) * 10,
              notificationsEnabled: testCase % 3 != 0,
              displayDensity: DisplayDensity.standard,
            );

            // 保存
            await dataSource.saveSettings(originalSettings);

            // 新しいデータソースインスタンスを作成（アプリ再起動をシミュレート）
            final newDataSource = SettingsLocalDataSourceImpl(localStorage: localStorage);

            // 再読み込み
            final loadedSettings = await newDataSource.getSettings();

            // データが一致することを検証
            expect(loadedSettings.displayCurrency, originalSettings.displayCurrency,
                reason: '表示通貨が一致すべき');
            expect(loadedSettings.autoRefreshEnabled, originalSettings.autoRefreshEnabled,
                reason: '自動更新設定が一致すべき');
            expect(loadedSettings.refreshIntervalSeconds, originalSettings.refreshIntervalSeconds,
                reason: '更新間隔が一致すべき');
            expect(loadedSettings.notificationsEnabled, originalSettings.notificationsEnabled,
                reason: '通知設定が一致すべき');
          }
        },
      );
    });

    group('getSettings', () {
      test('設定が存在しない場合はデフォルト設定を返す', () async {
        final settings = await dataSource.getSettings();

        expect(settings.displayCurrency, Currency.jpy);
        expect(settings.autoRefreshEnabled, isTrue);
        expect(settings.refreshIntervalSeconds, 30);
        expect(settings.notificationsEnabled, isTrue);
        expect(settings.displayDensity, DisplayDensity.standard);
      });

      test('保存された設定を正しく読み込む', () async {
        const testSettings = SettingsModel(
          displayCurrency: Currency.usd,
          autoRefreshEnabled: false,
          refreshIntervalSeconds: 60,
          notificationsEnabled: false,
          displayDensity: DisplayDensity.compact,
        );

        await dataSource.saveSettings(testSettings);
        final loaded = await dataSource.getSettings();

        expect(loaded.displayCurrency, Currency.usd);
        expect(loaded.autoRefreshEnabled, isFalse);
        expect(loaded.refreshIntervalSeconds, 60);
        expect(loaded.notificationsEnabled, isFalse);
        expect(loaded.displayDensity, DisplayDensity.compact);
      });
    });

    group('saveSettings', () {
      test('設定を保存できる', () async {
        const settings = SettingsModel(
          displayCurrency: Currency.eur,
          autoRefreshEnabled: true,
          refreshIntervalSeconds: 45,
          notificationsEnabled: true,
          displayDensity: DisplayDensity.maximum,
        );

        await dataSource.saveSettings(settings);
        final loaded = await dataSource.getSettings();

        expect(loaded.displayCurrency, Currency.eur);
        expect(loaded.refreshIntervalSeconds, 45);
        expect(loaded.displayDensity, DisplayDensity.maximum);
      });

      test('設定を上書きできる', () async {
        const settings1 = SettingsModel(
          displayCurrency: Currency.jpy,
          autoRefreshEnabled: true,
          refreshIntervalSeconds: 30,
          notificationsEnabled: true,
          displayDensity: DisplayDensity.standard,
        );

        const settings2 = SettingsModel(
          displayCurrency: Currency.btc,
          autoRefreshEnabled: false,
          refreshIntervalSeconds: 90,
          notificationsEnabled: false,
          displayDensity: DisplayDensity.compact,
        );

        await dataSource.saveSettings(settings1);
        await dataSource.saveSettings(settings2);
        final loaded = await dataSource.getSettings();

        expect(loaded.displayCurrency, Currency.btc);
        expect(loaded.autoRefreshEnabled, isFalse);
        expect(loaded.refreshIntervalSeconds, 90);
        expect(loaded.notificationsEnabled, isFalse);
        expect(loaded.displayDensity, DisplayDensity.compact);
      });
    });

    group('resetSettings', () {
      test('設定をデフォルトにリセットできる', () async {
        const customSettings = SettingsModel(
          displayCurrency: Currency.usd,
          autoRefreshEnabled: false,
          refreshIntervalSeconds: 120,
          notificationsEnabled: false,
          displayDensity: DisplayDensity.maximum,
        );

        await dataSource.saveSettings(customSettings);
        await dataSource.resetSettings();
        final loaded = await dataSource.getSettings();

        expect(loaded.displayCurrency, Currency.jpy);
        expect(loaded.autoRefreshEnabled, isTrue);
        expect(loaded.refreshIntervalSeconds, 30);
        expect(loaded.notificationsEnabled, isTrue);
        expect(loaded.displayDensity, DisplayDensity.standard);
      });
    });
  });
}
