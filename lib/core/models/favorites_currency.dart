import 'package:equatable/equatable.dart';

/// お気に入り通貨モデル
/// デフォルト通貨とカスタム通貨を統合管理するためのモデル
class FavoritesCurrency extends Equatable {
  /// 通貨シンボル（例: BTC, ETH, ADA）
  final String symbol;

  /// デフォルト通貨かどうか
  final bool isDefault;

  /// 追加日時
  final DateTime addedAt;

  /// 表示順序
  final int displayOrder;

  const FavoritesCurrency({
    required this.symbol,
    required this.isDefault,
    required this.addedAt,
    required this.displayOrder,
  });

  /// JSONからFavoritesCurrencyを生成
  factory FavoritesCurrency.fromJson(Map<String, dynamic> json) {
    try {
      return FavoritesCurrency(
        symbol: json['symbol'] as String,
        isDefault: json['is_default'] as bool? ?? false,
        addedAt: _parseDateTime(json['added_at'] ?? json['addedAt']),
        displayOrder: json['display_order'] as int? ?? 0,
      );
    } catch (e) {
      throw FormatException('Failed to parse FavoritesCurrency from JSON: $e');
    }
  }

  /// FavoritesCurrencyをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'is_default': isDefault,
      'added_at': addedAt.toIso8601String(),
      'display_order': displayOrder,
    };
  }

  /// DateTimeのパース処理
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      throw const FormatException('DateTime value cannot be null');
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    if (value is int) {
      // Unix timestamp (seconds) or milliseconds
      if (value < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    throw FormatException('Cannot parse $value to DateTime');
  }

  /// コピーを作成
  FavoritesCurrency copyWith({
    String? symbol,
    bool? isDefault,
    DateTime? addedAt,
    int? displayOrder,
  }) {
    return FavoritesCurrency(
      symbol: symbol ?? this.symbol,
      isDefault: isDefault ?? this.isDefault,
      addedAt: addedAt ?? this.addedAt,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  List<Object?> get props => [symbol, isDefault, addedAt, displayOrder];

  @override
  String toString() {
    return 'FavoritesCurrency(symbol: $symbol, isDefault: $isDefault, '
        'addedAt: $addedAt, displayOrder: $displayOrder)';
  }
}
