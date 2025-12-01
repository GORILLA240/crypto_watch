import '../../domain/entities/crypto_price.dart';

/// 暗号通貨価格のデータモデル
/// JSON シリアライゼーション/デシリアライゼーションを担当
class CryptoPriceModel extends CryptoPrice {
  const CryptoPriceModel({
    required super.symbol,
    required super.name,
    required super.price,
    required super.change24h,
    required super.marketCap,
    required super.lastUpdated,
  });

  /// JSONからモデルを生成
  factory CryptoPriceModel.fromJson(Map<String, dynamic> json) {
    try {
      return CryptoPriceModel(
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        price: _parseDouble(json['price']),
        change24h: _parseDouble(json['change_24h'] ?? json['change24h']),
        marketCap: _parseDouble(json['market_cap'] ?? json['marketCap']),
        lastUpdated: _parseDateTime(json['last_updated'] ?? json['lastUpdated']),
      );
    } catch (e) {
      throw FormatException('Failed to parse CryptoPriceModel from JSON: $e');
    }
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'price': price,
      'change_24h': change24h,
      'market_cap': marketCap,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// エンティティからモデルを生成
  factory CryptoPriceModel.fromEntity(CryptoPrice entity) {
    return CryptoPriceModel(
      symbol: entity.symbol,
      name: entity.name,
      price: entity.price,
      change24h: entity.change24h,
      marketCap: entity.marketCap,
      lastUpdated: entity.lastUpdated,
    );
  }

  /// モデルをエンティティに変換
  CryptoPrice toEntity() {
    return CryptoPrice(
      symbol: symbol,
      name: name,
      price: price,
      change24h: change24h,
      marketCap: marketCap,
      lastUpdated: lastUpdated,
    );
  }

  /// doubleのパース（int、String、doubleに対応）
  static double _parseDouble(dynamic value) {
    if (value == null) {
      throw const FormatException('Value cannot be null');
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.parse(value);
    }
    throw FormatException('Cannot parse $value to double');
  }

  /// DateTimeのパース（ISO8601文字列またはタイムスタンプ）
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      throw const FormatException('DateTime value cannot be null');
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    if (value is int) {
      // タイムスタンプ（秒）の場合
      if (value < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      // タイムスタンプ（ミリ秒）の場合
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    throw FormatException('Cannot parse $value to DateTime');
  }

  @override
  CryptoPriceModel copyWith({
    String? symbol,
    String? name,
    double? price,
    double? change24h,
    double? marketCap,
    DateTime? lastUpdated,
  }) {
    return CryptoPriceModel(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      change24h: change24h ?? this.change24h,
      marketCap: marketCap ?? this.marketCap,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
