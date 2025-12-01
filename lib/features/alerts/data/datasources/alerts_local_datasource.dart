import 'dart:convert';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/alert_model.dart';

/// アラートのローカルデータソース抽象クラス
abstract class AlertsLocalDataSource {
  /// すべてのアラートを取得
  Future<List<AlertModel>> getAlerts();

  /// アラートを作成
  Future<void> createAlert(AlertModel alert);

  /// アラートを削除
  Future<void> deleteAlert(String alertId);

  /// アラートを更新
  Future<void> updateAlert(AlertModel alert);

  /// 特定のシンボルのアラートを取得
  Future<List<AlertModel>> getAlertsBySymbol(String symbol);
}

/// アラートのローカルデータソース実装
class AlertsLocalDataSourceImpl implements AlertsLocalDataSource {
  final LocalStorage localStorage;

  AlertsLocalDataSourceImpl({required this.localStorage});

  @override
  Future<List<AlertModel>> getAlerts() async {
    try {
      final jsonString = await localStorage.getString(AppConstants.alertsKey);
      if (jsonString == null) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((item) => AlertModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageException(
        message: 'アラートの読み込みに失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<void> createAlert(AlertModel alert) async {
    try {
      final alerts = await getAlerts();
      alerts.add(alert);
      await _saveAlerts(alerts);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'アラートの作成に失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    try {
      final alerts = await getAlerts();
      alerts.removeWhere((alert) => alert.id == alertId);
      await _saveAlerts(alerts);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'アラートの削除に失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateAlert(AlertModel alert) async {
    try {
      final alerts = await getAlerts();
      final index = alerts.indexWhere((a) => a.id == alert.id);

      if (index == -1) {
        throw StorageException(
          message: 'アラートが見つかりません: ${alert.id}',
        );
      }

      alerts[index] = alert;
      await _saveAlerts(alerts);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'アラートの更新に失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<List<AlertModel>> getAlertsBySymbol(String symbol) async {
    try {
      final alerts = await getAlerts();
      return alerts.where((alert) => alert.symbol == symbol).toList();
    } catch (e) {
      throw StorageException(
        message: 'シンボル $symbol のアラートの取得に失敗しました',
        originalError: e,
      );
    }
  }

  /// アラートリストを保存
  Future<void> _saveAlerts(List<AlertModel> alerts) async {
    final jsonList = alerts.map((alert) => alert.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await localStorage.setString(AppConstants.alertsKey, jsonString);
  }
}
