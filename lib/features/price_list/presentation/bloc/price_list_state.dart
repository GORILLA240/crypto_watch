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
  final List<String> favoriteSymbols;
  final bool isReorderMode;
  final List<String> customOrder;
  final String? errorMessage;

  const PriceListLoaded({
    required this.prices,
    this.favoriteSymbols = const [],
    this.isReorderMode = false,
    this.customOrder = const [],
    this.errorMessage,
  });

  @override
  List<Object?> get props => [prices, favoriteSymbols, isReorderMode, customOrder, errorMessage];

  PriceListLoaded copyWith({
    List<CryptoPrice>? prices,
    List<String>? favoriteSymbols,
    bool? isReorderMode,
    List<String>? customOrder,
    String? errorMessage,
  }) {
    return PriceListLoaded(
      prices: prices ?? this.prices,
      favoriteSymbols: favoriteSymbols ?? this.favoriteSymbols,
      isReorderMode: isReorderMode ?? this.isReorderMode,
      customOrder: customOrder ?? this.customOrder,
      errorMessage: errorMessage,
    );
  }
}

/// リフレッシュ中
class PriceListRefreshing extends PriceListState {
  final List<CryptoPrice> prices;
  final List<String> favoriteSymbols;
  final bool isReorderMode;
  final List<String> customOrder;

  const PriceListRefreshing({
    required this.prices,
    this.favoriteSymbols = const [],
    this.isReorderMode = false,
    this.customOrder = const [],
  });

  @override
  List<Object?> get props => [prices, favoriteSymbols, isReorderMode, customOrder];
}

/// エラー
class PriceListError extends PriceListState {
  final String message;

  const PriceListError({required this.message});

  @override
  List<Object?> get props => [message];
}
