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

/// お気に入りをトグルするイベント
class ToggleFavoriteEvent extends PriceListEvent {
  final String symbol;

  const ToggleFavoriteEvent({required this.symbol});

  @override
  List<Object?> get props => [symbol];
}

/// 並び替えモードをトグルするイベント
class ToggleReorderModeEvent extends PriceListEvent {
  const ToggleReorderModeEvent();
}

/// 価格リストを並び替えるイベント
class ReorderPricesEvent extends PriceListEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderPricesEvent({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// エラーメッセージをクリアするイベント
class ClearErrorMessageEvent extends PriceListEvent {
  const ClearErrorMessageEvent();
}
