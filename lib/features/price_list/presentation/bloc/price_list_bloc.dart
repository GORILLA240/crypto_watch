import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_prices.dart';
import '../../domain/usecases/refresh_prices.dart';
import 'price_list_event.dart';
import 'price_list_state.dart';

/// 価格リストのBloc
class PriceListBloc extends Bloc<PriceListEvent, PriceListState> {
  final GetPrices getPrices;
  final RefreshPrices refreshPrices;

  Timer? _autoRefreshTimer;

  PriceListBloc({
    required this.getPrices,
    required this.refreshPrices,
  }) : super(const PriceListInitial()) {
    on<LoadPricesEvent>(_onLoadPrices);
    on<RefreshPricesEvent>(_onRefreshPrices);
    on<AutoRefreshEvent>(_onAutoRefresh);
  }

  /// 価格データを読み込む
  Future<void> _onLoadPrices(
    LoadPricesEvent event,
    Emitter<PriceListState> emit,
  ) async {
    emit(const PriceListLoading());

    final result = await getPrices(event.symbols);

    result.fold(
      (failure) => emit(PriceListError(message: failure.message)),
      (prices) => emit(PriceListLoaded(prices: prices)),
    );
  }

  /// 価格データをリフレッシュ
  Future<void> _onRefreshPrices(
    RefreshPricesEvent event,
    Emitter<PriceListState> emit,
  ) async {
    // 現在の価格を保持しながらリフレッシュ中状態に
    if (state is PriceListLoaded) {
      final currentPrices = (state as PriceListLoaded).prices;
      emit(PriceListRefreshing(prices: currentPrices));
    } else {
      emit(const PriceListLoading());
    }

    final result = await refreshPrices();

    result.fold(
      (failure) {
        // エラーが発生しても、既存のデータがあれば保持
        if (state is PriceListRefreshing) {
          final currentPrices = (state as PriceListRefreshing).prices;
          emit(PriceListLoaded(prices: currentPrices));
        } else {
          emit(PriceListError(message: failure.message));
        }
      },
      (prices) => emit(PriceListLoaded(prices: prices)),
    );
  }

  /// 自動更新
  Future<void> _onAutoRefresh(
    AutoRefreshEvent event,
    Emitter<PriceListState> emit,
  ) async {
    // リフレッシュイベントを発火
    add(const RefreshPricesEvent());
  }

  /// 自動更新タイマーを開始
  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(interval, (_) {
      add(const AutoRefreshEvent());
    });
  }

  /// 自動更新タイマーを停止
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  Future<void> close() {
    _autoRefreshTimer?.cancel();
    return super.close();
  }
}
