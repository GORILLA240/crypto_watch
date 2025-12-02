import 'package:flutter/foundation.dart';

/// コンプリケーションサイズ
enum ComplicationSize {
  small,
  medium,
  large,
}

/// コンプリケーションデータ
class ComplicationData {
  final String symbol;
  final double price;
  final double changePercent;
  final DateTime timestamp;

  const ComplicationData({
    required this.symbol,
    required this.price,
    required this.changePercent,
    required this.timestamp,
  });

  /// 小サイズ用のテキスト（価格のみ）
  /// 要件: 14.1
  String get smallText {
    return _formatPrice(price);
  }

  /// 中サイズ用のテキスト（価格と変動率）
  /// 要件: 14.2
  String get mediumText {
    final changeSign = changePercent >= 0 ? '+' : '';
    return '${_formatPrice(price)}\n$changeSign${changePercent.toStringAsFixed(1)}%';
  }

  /// 大サイズ用のテキスト（価格、変動率、ティッカー名）
  /// 要件: 14.3
  String get largeText {
    final changeSign = changePercent >= 0 ? '+' : '';
    return '$symbol\n${_formatPrice(price)}\n$changeSign${changePercent.toStringAsFixed(2)}%';
  }

  /// 価格をフォーマット
  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '¥${(price / 1000000).toStringAsFixed(2)}M';
    } else if (price >= 1000) {
      return '¥${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return '¥${price.toStringAsFixed(0)}';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'price': price,
      'changePercent': changePercent,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ComplicationData.fromJson(Map<String, dynamic> json) {
    return ComplicationData(
      symbol: json['symbol'] as String,
      price: (json['price'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// コンプリケーションサービス
/// 
/// スマートウォッチの文字盤上での価格表示を管理
/// 要件: 14.1, 14.2, 14.3, 14.4, 14.5
class ComplicationService {
  static final ComplicationService _instance =
      ComplicationService._internal();
  factory ComplicationService() => _instance;
  ComplicationService._internal();

  bool _isInitialized = false;
  ComplicationData? _currentData;

  /// コンプリケーションサービスの初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TODO: 実際のウェアラブル統合（WearOS、watchOS）
      // 現在はプレースホルダー実装
      
      if (kDebugMode) {
        debugPrint('⌚ Complication service initialized');
      }
      
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize complication service: $e');
      }
    }
  }

  /// コンプリケーションデータを更新
  /// 
  /// 要件: 14.5
  Future<void> updateComplication(ComplicationData data) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        debugPrint('⚠️ Complication service not initialized');
      }
      return;
    }

    try {
      _currentData = data;

      // TODO: 実際のコンプリケーション更新実装
      // WearOS: Complications API
      // watchOS: ClockKit
      
      if (kDebugMode) {
        debugPrint('⌚ Updated complication:');
        debugPrint('   Small: ${data.smallText}');
        debugPrint('   Medium: ${data.mediumText}');
        debugPrint('   Large: ${data.largeText}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update complication: $e');
      }
    }
  }

  /// 複数のコンプリケーションを更新
  Future<void> updateComplications(List<ComplicationData> dataList) async {
    for (final data in dataList) {
      await updateComplication(data);
    }
  }

  /// 特定サイズのコンプリケーションテキストを取得
  String? getComplicationText(ComplicationSize size) {
    if (_currentData == null) return null;

    switch (size) {
      case ComplicationSize.small:
        return _currentData!.smallText;
      case ComplicationSize.medium:
        return _currentData!.mediumText;
      case ComplicationSize.large:
        return _currentData!.largeText;
    }
  }

  /// コンプリケーションタップ時のハンドラーを設定
  /// 
  /// 要件: 14.4
  void setupComplicationTapHandler(
    Function(String symbol) onComplicationTap,
  ) {
    // TODO: 実際のタップハンドラー実装
    // コンプリケーションタップ時にアプリを起動し、該当銘柄の詳細を表示
    
    if (kDebugMode) {
      debugPrint('⌚ Complication tap handler configured');
    }
  }

  /// 現在のコンプリケーションデータを取得
  ComplicationData? get currentData => _currentData;

  /// コンプリケーションをクリア
  Future<void> clearComplication() async {
    try {
      _currentData = null;
      
      // TODO: 実際のコンプリケーションクリア実装
      
      if (kDebugMode) {
        debugPrint('⌚ Cleared complication');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear complication: $e');
      }
    }
  }

  /// サービスをクリーンアップ
  void dispose() {
    _isInitialized = false;
    _currentData = null;
  }
}

/// コンプリケーション設定
class ComplicationSettings {
  final bool enabled;
  final String defaultSymbol;
  final ComplicationSize preferredSize;
  final bool autoUpdate;
  final Duration updateInterval;

  const ComplicationSettings({
    this.enabled = true,
    this.defaultSymbol = 'BTC',
    this.preferredSize = ComplicationSize.medium,
    this.autoUpdate = true,
    this.updateInterval = const Duration(minutes: 5),
  });

  ComplicationSettings copyWith({
    bool? enabled,
    String? defaultSymbol,
    ComplicationSize? preferredSize,
    bool? autoUpdate,
    Duration? updateInterval,
  }) {
    return ComplicationSettings(
      enabled: enabled ?? this.enabled,
      defaultSymbol: defaultSymbol ?? this.defaultSymbol,
      preferredSize: preferredSize ?? this.preferredSize,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      updateInterval: updateInterval ?? this.updateInterval,
    );
  }
}
