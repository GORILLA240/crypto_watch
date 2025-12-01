import 'package:equatable/equatable.dart';

/// 価格アラートエンティティ
class PriceAlert extends Equatable {
  final String id;
  final String symbol;
  final double? upperLimit;
  final double? lowerLimit;
  final bool isEnabled;
  final DateTime createdAt;

  const PriceAlert({
    required this.id,
    required this.symbol,
    this.upperLimit,
    this.lowerLimit,
    required this.isEnabled,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        symbol,
        upperLimit,
        lowerLimit,
        isEnabled,
        createdAt,
      ];

  PriceAlert copyWith({
    String? id,
    String? symbol,
    double? upperLimit,
    double? lowerLimit,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      upperLimit: upperLimit ?? this.upperLimit,
      lowerLimit: lowerLimit ?? this.lowerLimit,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// アラートが発火すべきかチェック
  bool shouldTrigger(double currentPrice) {
    if (!isEnabled) return false;

    if (upperLimit != null && currentPrice >= upperLimit!) {
      return true;
    }

    if (lowerLimit != null && currentPrice <= lowerLimit!) {
      return true;
    }

    return false;
  }

  @override
  String toString() {
    return 'PriceAlert(id: $id, symbol: $symbol, upperLimit: $upperLimit, '
        'lowerLimit: $lowerLimit, isEnabled: $isEnabled, createdAt: $createdAt)';
  }
}
