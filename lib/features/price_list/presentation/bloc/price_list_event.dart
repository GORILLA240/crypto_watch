import 'package:equatable/equatable.dart';

/// 価格リストのイベント
abstract class PriceListEvent extends Equatable {
  const PriceListEvent();

  @override
  List<Object?> get props => [];
}

/// 価格データを読み込むイベント
class LoadPricesEvent extends PriceListEvent {
  final List<String> symbols;

  const LoadPricesEvent({required this.symbols});

  @override
  List<Object?> get props => [symbols];
}

/// 価格データをリフレッシュするイベント
class RefreshPricesEvent extends PriceListEvent {
  const RefreshPricesEvent();
}

/// 自動更新イベント
class AutoRefreshEvent extends PriceListEvent {
  const AutoRefreshEvent();
}
