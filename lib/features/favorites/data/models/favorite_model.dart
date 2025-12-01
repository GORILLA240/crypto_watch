import '../../domain/entities/favorite.dart';

/// お気に入り銘柄モデル
class FavoriteModel extends Favorite {
  const FavoriteModel({
    required super.symbol,
    required super.order,
    required super.addedAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    try {
      return FavoriteModel(
        symbol: json['symbol'] as String,
        order: json['order'] as int,
        addedAt: _parseDateTime(json['added_at'] ?? json['addedAt']),
      );
    } catch (e) {
      throw FormatException('Failed to parse FavoriteModel from JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'order': order,
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory FavoriteModel.fromEntity(Favorite entity) {
    return FavoriteModel(
      symbol: entity.symbol,
      order: entity.order,
      addedAt: entity.addedAt,
    );
  }

  Favorite toEntity() {
    return Favorite(
      symbol: symbol,
      order: order,
      addedAt: addedAt,
    );
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
  FavoriteModel copyWith({
    String? symbol,
    int? order,
    DateTime? addedAt,
  }) {
    return FavoriteModel(
      symbol: symbol ?? this.symbol,
      order: order ?? this.order,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
