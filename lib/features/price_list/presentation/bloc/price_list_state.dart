import 'package:equatable/equatable.dart';
import '../../domain/entities/crypto_price.dart';

/// 価格リストの状態
abstract class PriceListState extends Equatable {
  const PriceListState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class PriceListInitial extends PriceListState {
  const PriceListInitial();
}

/// 読み込み中
class PriceListLoading extends PriceListState {
  const PriceListLoading();
}

/// 読み込み完了
class PriceListLoaded extends PriceListState {
  final List<CryptoPrice> prices;

  const PriceListLoaded({required this.prices});

  @override
  List<Object?> get props => [prices];
}

/// リフレッシュ中
class PriceListRefreshing extends PriceListState {
  final List<CryptoPrice> prices;

  const PriceListRefreshing({required this.prices});

  @override
  List<Object?> get props => [prices];
}

/// エラー
class PriceListError extends PriceListState {
  final String message;

  const PriceListError({required this.message});

  @override
  List<Object?> get props => [message];
}
