import 'package:equatable/equatable.dart';
import '../../../price_list/domain/entities/crypto_price.dart';

/// チャートデータポイント
class ChartDataPoint extends Equatable {
  final DateTime timestamp;
  final double price;

  const ChartDataPoint({
    required this.timestamp,
    required this.price,
  });

  @override
  List<Object?> get props => [timestamp, price];
}

/// 価格詳細エンティティ（CryptoPriceを拡張）
class PriceDetail extends CryptoPrice {
  final double high24h;
  final double low24h;
  final double volume24h;
  final List<ChartDataPoint> chart1h;
  final List<ChartDataPoint> chart24h;
  final List<ChartDataPoint> chart7d;

  const PriceDetail({
    required super.symbol,
    required super.name,
    required super.price,
    required super.change24h,
    required super.marketCap,
    required super.lastUpdated,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    required this.chart1h,
    required this.chart24h,
    required this.chart7d,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        high24h,
        low24h,
        volume24h,
        chart1h,
        chart24h,
        chart7d,
      ];

  @override
  PriceDetail copyWith({
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
    return PriceDetail(
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
