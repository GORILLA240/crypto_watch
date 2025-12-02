import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 通知サービス
/// 
/// アラート発火時の通知送信と通知タップ時の画面遷移を管理
/// 要件: 16.3, 16.4
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  /// 通知サービスの初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TODO: 実際のプッシュ通知ライブラリ（firebase_messaging等）を統合
      // 現在はプレースホルダー実装
      
      if (kDebugMode) {
        debugPrint('✅ Notification service initialized');
      }
      
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize notification service: $e');
      }
    }
  }

  /// 通知が有効かどうか
  bool get isEnabled => _notificationsEnabled;

  /// 通知の有効/無効を設定
  void setEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    if (kDebugMode) {
      debugPrint('Notifications ${enabled ? "enabled" : "disabled"}');
    }
  }

  /// 通知権限をリクエスト
  Future<bool> requestPermission() async {
    try {
      // TODO: 実際の権限リクエスト実装
      // 現在はプレースホルダー
      
      if (kDebugMode) {
        debugPrint('📱 Requesting notification permission');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to request permission: $e');
      }
      return false;
    }
  }

  /// アラート発火時の通知を送信
  /// 
  /// 要件: 16.3
  Future<void> sendAlertNotification({
    required String symbol,
    required double currentPrice,
    required double? triggerPrice,
    required bool isUpperLimit,
  }) async {
    if (!_isInitialized || !_notificationsEnabled) {
      if (kDebugMode) {
        debugPrint('⚠️ Notifications not enabled or initialized');
      }
      return;
    }

    try {
      final title = 'アラート発火: $symbol';
      final body = isUpperLimit
          ? '価格が上限 ¥${_formatPrice(triggerPrice!)} を超えました\n現在価格: ¥${_formatPrice(currentPrice)}'
          : '価格が下限 ¥${_formatPrice(triggerPrice!)} を下回りました\n現在価格: ¥${_formatPrice(currentPrice)}';

      // TODO: 実際の通知送信実装
      // 現在はデバッグログのみ
      if (kDebugMode) {
        debugPrint('🔔 Notification: $title - $body');
      }

      // ローカル通知として表示（プレースホルダー）
      _showLocalNotification(title, body, symbol);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to send notification: $e');
      }
    }
  }

  /// 価格更新通知を送信
  Future<void> sendPriceUpdateNotification({
    required String symbol,
    required double price,
    required double changePercent,
  }) async {
    if (!_isInitialized || !_notificationsEnabled) return;

    try {
      final title = '$symbol 価格更新';
      final changeSign = changePercent >= 0 ? '+' : '';
      final body = '¥${_formatPrice(price)} ($changeSign${changePercent.toStringAsFixed(2)}%)';

      if (kDebugMode) {
        debugPrint('🔔 Price update: $title - $body');
      }

      _showLocalNotification(title, body, symbol);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to send price update: $e');
      }
    }
  }

  /// ローカル通知を表示（プレースホルダー実装）
  void _showLocalNotification(String title, String body, String symbol) {
    // TODO: 実際のローカル通知実装
    // flutter_local_notifications パッケージを使用
    
    if (kDebugMode) {
      debugPrint('📬 Local notification: $title');
      debugPrint('   Body: $body');
      debugPrint('   Symbol: $symbol');
    }
  }

  /// 通知タップ時のハンドラーを設定
  /// 
  /// 要件: 16.4
  void setupNotificationTapHandler(
    BuildContext context,
    Function(String symbol) onNotificationTap,
  ) {
    // TODO: 実際の通知タップハンドラー実装
    // firebase_messaging の onMessageOpenedApp を使用
    
    if (kDebugMode) {
      debugPrint('📱 Notification tap handler configured');
    }
  }

  /// 通知をキャンセル
  Future<void> cancelNotification(int notificationId) async {
    try {
      // TODO: 実際の通知キャンセル実装
      
      if (kDebugMode) {
        debugPrint('🚫 Cancelled notification: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to cancel notification: $e');
      }
    }
  }

  /// すべての通知をキャンセル
  Future<void> cancelAllNotifications() async {
    try {
      // TODO: 実際の全通知キャンセル実装
      
      if (kDebugMode) {
        debugPrint('🚫 Cancelled all notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to cancel all notifications: $e');
      }
    }
  }

  /// 価格をフォーマット
  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(2)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    } else {
      return price.toStringAsFixed(2);
    }
  }

  /// サービスをクリーンアップ
  void dispose() {
    _isInitialized = false;
  }
}

/// 通知設定
class NotificationSettings {
  final bool enabled;
  final bool alertNotifications;
  final bool priceUpdateNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationSettings({
    this.enabled = true,
    this.alertNotifications = true,
    this.priceUpdateNotifications = false,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? alertNotifications,
    bool? priceUpdateNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      alertNotifications: alertNotifications ?? this.alertNotifications,
      priceUpdateNotifications:
          priceUpdateNotifications ?? this.priceUpdateNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}
