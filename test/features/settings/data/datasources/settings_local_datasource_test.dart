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

    group('Property 2: 表示密度設定の永続化', () {
      test(
        '**Feature: price-list-improvements, Property 2: 表示密度の制約**（永続化部分） - '
        '**Validates: 要件 2.7, 9.2** - '
        '表示密度を保存し、読み込んだ後も同じ値であることを確認',
        () async {
          // Property-based test: すべての表示密度で永続性を検証
          final densities = [
            DisplayDensity.standard,
            DisplayDensity.compact,
            DisplayDensity.maximum,
          ];
          final currencies = [Currency.jpy, Currency.usd, Currency.eur, Currency.btc];

          // 100回のイテレーションで様々な組み合わせをテスト
          for (var testCase = 0; testCase < 100; testCase++) {
            // テストケースごとにストレージをクリア
            await localStorage.clear();

            // ランダムな設定を生成（表示密度を含む）
            final originalSettings = SettingsModel(
              displayCurrency: currencies[testCase % currencies.length],
              autoRefreshEnabled: testCase % 2 == 0,
              refreshIntervalSeconds: 30 + (testCase % 5) * 10,
              notificationsEnabled: testCase % 3 != 0,
              displayDensity: densities[testCase % densities.length],
            );

            // 保存
            await dataSource.saveSettings(originalSettings);

            // 新しいデータソースインスタンスを作成（アプリ再起動をシミュレート）
            final newDataSource = SettingsLocalDataSourceImpl(localStorage: localStorage);

            // 再読み込み
            final loadedSettings = await newDataSource.getSettings();

            // 表示密度が一致することを検証
            expect(
              loadedSettings.displayDensity,
              originalSettings.displayDensity,
              reason: '表示密度が一致すべき: 保存=${originalSettings.displayDensity.name}, '
                  '読み込み=${loadedSettings.displayDensity.name}',
            );

            // 他の設定も一致することを確認（完全性チェック）
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

      test(
        '表示密度のみを変更した場合も永続化される',
        () async {
          // 初期設定を保存
          const initialSettings = SettingsModel(
            displayCurrency: Currency.jpy,
            autoRefreshEnabled: true,
            refreshIntervalSeconds: 30,
            notificationsEnabled: true,
            displayDensity: DisplayDensity.standard,
          );
          await dataSource.saveSettings(initialSettings);

          // 各表示密度に変更して永続性を確認
          final densities = [
            DisplayDensity.compact,
            DisplayDensity.maximum,
            DisplayDensity.standard,
          ];

          for (final density in densities) {
            final updatedSettings = initialSettings.copyWith(
              displayDensity: density,
            );

            // 保存
            await dataSource.saveSettings(updatedSettings);

            // 再読み込み
            final loadedSettings = await dataSource.getSettings();

            // 表示密度が正しく保存・読み込みされることを確認
            expect(
              loadedSettings.displayDensity,
              density,
              reason: '表示密度 ${density.name} が正しく永続化されるべき',
            );

            // 他の設定は変更されていないことを確認
            expect(loadedSettings.displayCurrency, initialSettings.displayCurrency);
            expect(loadedSettings.autoRefreshEnabled, initialSettings.autoRefreshEnabled);
            expect(loadedSettings.refreshIntervalSeconds, initialSettings.refreshIntervalSeconds);
            expect(loadedSettings.notificationsEnabled, initialSettings.notificationsEnabled);
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
