import 'package:equatable/equatable.dart';

/// お気に入り銘柄エンティティ
class Favorite extends Equatable {
  final String symbol;
  final int order;
  final DateTime addedAt;

  const Favorite({
    required this.symbol,
    required this.order,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [symbol, order, addedAt];

  Favorite copyWith({
    String? symbol,
    int? order,
    DateTime? addedAt,
  }) {
    return Favorite(
      symbol: symbol ?? this.symbol,
      order: order ?? this.order,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'Favorite(symbol: $symbol, order: $order, addedAt: $addedAt)';
  }
}
