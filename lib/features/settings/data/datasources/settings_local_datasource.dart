import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/settings_model.dart';

/// 設定のローカルデータソース抽象クラス
abstract class SettingsLocalDataSource {
  /// 設定を取得
  Future<SettingsModel> getSettings();

  /// 設定を保存
  Future<void> saveSettings(SettingsModel settings);

  /// 設定をリセット（デフォルトに戻す）
  Future<void> resetSettings();
}

/// 設定のローカルデータソース実装
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final LocalStorage localStorage;

  SettingsLocalDataSourceImpl({required this.localStorage});

  @override
  Future<SettingsModel> getSettings() async {
    try {
      final jsonString = await localStorage.getString(AppConstants.settingsKey);
      if (jsonString == null) {
        // 設定が存在しない場合はデフォルト設定を返す
        return SettingsModel.defaultSettings();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return SettingsModel.fromJson(json);
    } catch (e) {
      // エラーが発生した場合もデフォルト設定を返す
      return SettingsModel.defaultSettings();
    }
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    try {
      final json = settings.toJson();
      final jsonString = jsonEncode(json);
      await localStorage.setString(AppConstants.settingsKey, jsonString);
    } catch (e) {
      throw StorageException(
        message: '設定の保存に失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<void> resetSettings() async {
    try {
      final defaultSettings = SettingsModel.defaultSettings();
      await saveSettings(defaultSettings);
    } catch (e) {
      throw StorageException(
        message: '設定のリセットに失敗しました',
        originalError: e,
      );
    }
  }
}
