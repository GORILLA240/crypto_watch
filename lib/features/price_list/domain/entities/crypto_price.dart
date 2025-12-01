import 'package:equatable/equatable.dart';

/// 暗号通貨価格のエンティティ
/// ドメイン層で使用される不変のデータクラス
class CryptoPrice extends Equatable {
  final String symbol;
  final String name;
  final double price;
  final double change24h;
  final double marketCap;
  final DateTime lastUpdated;

  const CryptoPrice({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
    required this.marketCap,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
        symbol,
        name,
        price,
        change24h,
        marketCap,
        lastUpdated,
      ];

  @override
  String toString() {
    return 'CryptoPrice(symbol: $symbol, name: $name, price: $price, '
        'change24h: $change24h, marketCap: $marketCap, lastUpdated: $lastUpdated)';
  }

  /// エンティティをコピーして一部のフィールドを更新
  CryptoPrice copyWith({
    String? symbol,
    String? name,
    double? price,
    double? change24h,
    double? marketCap,
    DateTime? lastUpdated,
  }) {
    return CryptoPrice(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      change24h: change24h ?? this.change24h,
      marketCap: marketCap ?? this.marketCap,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
