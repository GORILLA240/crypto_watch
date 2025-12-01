import '../../../price_list/data/models/crypto_price_model.dart';
import '../../domain/entities/price_detail.dart';

/// チャートデータポイントモデル
class ChartDataPointModel extends ChartDataPoint {
  const ChartDataPointModel({
    required super.timestamp,
    required super.price,
  });

  factory ChartDataPointModel.fromJson(Map<String, dynamic> json) {
    return ChartDataPointModel(
      timestamp: _parseDateTime(json['timestamp'] ?? json['time']),
      price: _parseDouble(json['price'] ?? json['value']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'price': price,
    };
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
}

/// 価格詳細モデル
class PriceDetailModel extends PriceDetail {
  const PriceDetailModel({
    required super.symbol,
    required super.name,
    required super.price,
    required super.change24h,
    required super.marketCap,
    required super.lastUpdated,
    required super.high24h,
    required super.low24h,
    required super.volume24h,
    required super.chart1h,
    required super.chart24h,
    required super.chart7d,
  });

  factory PriceDetailModel.fromJson(Map<String, dynamic> json) {
    try {
      return PriceDetailModel(
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        price: CryptoPriceModel.fromJson(json).price,
        change24h: CryptoPriceModel.fromJson(json).change24h,
        marketCap: CryptoPriceModel.fromJson(json).marketCap,
        lastUpdated: CryptoPriceModel.fromJson(json).lastUpdated,
        high24h: _parseDouble(json['high_24h'] ?? json['high24h']),
        low24h: _parseDouble(json['low_24h'] ?? json['low24h']),
        volume24h: _parseDouble(json['volume_24h'] ?? json['volume24h']),
        chart1h: _parseChartData(json['chart_1h'] ?? json['chart1h'] ?? []),
        chart24h: _parseChartData(json['chart_24h'] ?? json['chart24h'] ?? []),
        chart7d: _parseChartData(json['chart_7d'] ?? json['chart7d'] ?? []),
      );
    } catch (e) {
      throw FormatException('Failed to parse PriceDetailModel from JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'price': price,
      'change_24h': change24h,
      'market_cap': marketCap,
      'last_updated': lastUpdated.toIso8601String(),
      'high_24h': high24h,
      'low_24h': low24h,
      'volume_24h': volume24h,
      'chart_1h': chart1h.map((p) => ChartDataPointModel(timestamp: p.timestamp, price: p.price).toJson()).toList(),
      'chart_24h': chart24h.map((p) => ChartDataPointModel(timestamp: p.timestamp, price: p.price).toJson()).toList(),
      'chart_7d': chart7d.map((p) => ChartDataPointModel(timestamp: p.timestamp, price: p.price).toJson()).toList(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) throw const FormatException('Value cannot be null');
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    throw FormatException('Cannot parse $value to double');
  }

  static List<ChartDataPoint> _parseChartData(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    return value
        .map((item) => ChartDataPointModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  PriceDetailModel copyWith({
    String? symbol,
    String? name,
    double? price,
    double? change24h,
    double? marketCap,
    DateTime? lastUpdated,
    double? high24h,
    double? low24h,
    double? volume24h,
    List<ChartDataPoint>? chart1h,
    List<ChartDataPoint>? chart24h,
    List<ChartDataPoint>? chart7d,
  }) {
    return PriceDetailModel(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      change24h: change24h ?? this.change24h,
      marketCap: marketCap ?? this.marketCap,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      volume24h: volume24h ?? this.volume24h,
      chart1h: chart1h ?? this.chart1h,
      chart24h: chart24h ?? this.chart24h,
      chart7d: chart7d ?? this.chart7d,
    );
  }
}
