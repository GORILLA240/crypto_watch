import '../../domain/entities/price_alert.dart';

/// 価格アラートモデル
class AlertModel extends PriceAlert {
  const AlertModel({
    required super.id,
    required super.symbol,
    super.upperLimit,
    super.lowerLimit,
    required super.isEnabled,
    required super.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    try {
      return AlertModel(
        id: json['id'] as String,
        symbol: json['symbol'] as String,
        upperLimit: json['upper_limit'] != null ? _parseDouble(json['upper_limit']) : null,
        lowerLimit: json['lower_limit'] != null ? _parseDouble(json['lower_limit']) : null,
        isEnabled: json['is_enabled'] as bool? ?? true,
        createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      );
    } catch (e) {
      throw FormatException('Failed to parse AlertModel from JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'upper_limit': upperLimit,
      'lower_limit': lowerLimit,
      'is_enabled': isEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AlertModel.fromEntity(PriceAlert entity) {
    return AlertModel(
      id: entity.id,
      symbol: entity.symbol,
      upperLimit: entity.upperLimit,
      lowerLimit: entity.lowerLimit,
      isEnabled: entity.isEnabled,
      createdAt: entity.createdAt,
    );
  }

  PriceAlert toEntity() {
    return PriceAlert(
      id: id,
      symbol: symbol,
      upperLimit: upperLimit,
      lowerLimit: lowerLimit,
      isEnabled: isEnabled,
      createdAt: createdAt,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) throw const FormatException('Value cannot be null');
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    throw FormatException('Cannot parse $value to double');
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) throw const FormatException('DateTime value cannot be null');
    if (value is String) return DateTime.parse(value);
    if (value is int) {
      if (value < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    throw FormatException('Cannot parse $value to DateTime');
  }

  @override
  AlertModel copyWith({
    String? id,
    String? symbol,
    double? upperLimit,
    double? lowerLimit,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return AlertModel(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      upperLimit: upperLimit ?? this.upperLimit,
      lowerLimit: lowerLimit ?? this.lowerLimit,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
