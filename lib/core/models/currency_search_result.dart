import 'package:equatable/equatable.dart';

/// 通貨検索結果を表すモデル
/// CoinGecko APIの検索エンドポイントから返されるデータを表現
class CurrencySearchResult extends Equatable {
  /// CoinGecko内部ID (例: "bitcoin")
  final String id;

  /// ティッカーシンボル (例: "BTC")
  final String symbol;

  /// 通貨名 (例: "Bitcoin")
  final String name;

  /// アイコンURL (オプション)
  final String? iconUrl;

  /// 時価総額ランキング
  final int marketCapRank;

  const CurrencySearchResult({
    required this.id,
    required this.symbol,
    required this.name,
    this.iconUrl,
    required this.marketCapRank,
  });

  /// JSONからCurrencySearchResultを生成
  factory CurrencySearchResult.fromJson(Map<String, dynamic> json) {
    return CurrencySearchResult(
      id: json['id'] as String,
      symbol: (json['symbol'] as String).toUpperCase(),
      name: json['name'] as String,
      iconUrl: json['thumb'] as String?,
      marketCapRank: json['market_cap_rank'] as int? ?? 999999,
    );
  }

  /// CurrencySearchResultをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'thumb': iconUrl,
      'market_cap_rank': marketCapRank,
    };
  }

  @override
  List<Object?> get props => [id, symbol, name, iconUrl, marketCapRank];

  @override
  String toString() {
    return 'CurrencySearchResult(id: $id, symbol: $symbol, name: $name, '
        'iconUrl: $iconUrl, marketCapRank: $marketCapRank)';
  }

  /// エンティティをコピーして一部のフィールドを更新
  CurrencySearchResult copyWith({
    String? id,
    String? symbol,
    String? name,
    String? iconUrl,
    int? marketCapRank,
  }) {
    return CurrencySearchResult(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      marketCapRank: marketCapRank ?? this.marketCapRank,
    );
  }
}
