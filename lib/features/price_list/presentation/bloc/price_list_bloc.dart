import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../domain/usecases/get_prices.dart';
import '../../domain/usecases/refresh_prices.dart';
import '../../../favorites/domain/usecases/get_favorites.dart';
import '../../../favorites/domain/usecases/add_favorite.dart';
import '../../../favorites/domain/usecases/remove_favorite.dart';
import 'price_list_event.dart';
import 'price_list_state.dart';

/// 価格リストのBloc
class PriceListBloc extends Bloc<PriceListEvent, PriceListState> {
  final GetPrices getPrices;
  final RefreshPrices refreshPrices;
  final GetFavorites getFavorites;
  final AddFavorite addFavorite;
  final RemoveFavorite removeFavorite;
  final LocalStorage localStorage;

  Timer? _autoRefreshTimer;

  PriceListBloc({
    required this.getPrices,
    required this.refreshPrices,
    required this.getFavorites,
    required this.addFavorite,
    required this.removeFavorite,
    required this.localStorage,
  }) : super(const PriceListInitial()) {
    on<LoadPricesEvent>(_onLoadPrices);
    on<RefreshPricesEvent>(_onRefreshPrices);
    on<AutoRefreshEvent>(_onAutoRefresh);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<ToggleReorderModeEvent>(_onToggleReorderMode);
    on<ReorderPricesEvent>(_onReorderPrices);
    on<ClearErrorMessageEvent>(_onClearErrorMessage);
  }

  /// 価格データを読み込む
  Future<void> _onLoadPrices(
    LoadPricesEvent event,
    Emitter<PriceListState> emit,
  ) async {
    emit(const PriceListLoading());

    final result = await getPrices(event.symbols);

    await result.fold(
      (failure) async => emit(PriceListError(message: failure.message)),
      (prices) async {
        // お気に入りリストも読み込む
        final favoritesResult = await getFavorites();
        final favoriteSymbols = favoritesResult.fold(
          (_) => <String>[],
          (favorites) => favorites.map((f) => f.symbol).toList(),
        );

        // カスタム順序を読み込む
        final customOrder = await _loadCustomOrder();

        emit(PriceListLoaded(
          prices: prices,
          favoriteSymbols: favoriteSymbols,
          customOrder: customOrder,
        ));
      },
    );
  }

  /// 価格データをリフレッシュ
  Future<void> _onRefreshPrices(
    RefreshPricesEvent event,
    Emitter<PriceListState> emit,
  ) async {
    // 現在の価格とお気に入りを保持しながらリフレッシュ中状態に
    List<String> currentFavorites = [];
    bool currentReorderMode = false;
    List<String> currentCustomOrder = [];
    
    if (state is PriceListLoaded) {
      final currentState = state as PriceListLoaded;
      currentFavorites = currentState.favoriteSymbols;
      currentReorderMode = currentState.isReorderMode;
      currentCustomOrder = currentState.customOrder;
      emit(PriceListRefreshing(
        prices: currentState.prices,
        favoriteSymbols: currentFavorites,
        isReorderMode: currentReorderMode,
        customOrder: currentCustomOrder,
      ));
    } else {
      emit(const PriceListLoading());
    }

    final result = await refreshPrices();

    await result.fold(
      (failure) async {
        // エラーが発生しても、既存のデータがあれば保持
        if (state is PriceListRefreshing) {
          final currentState = state as PriceListRefreshing;
          emit(PriceListLoaded(
            prices: currentState.prices,
            favoriteSymbols: currentState.favoriteSymbols,
            isReorderMode: currentState.isReorderMode,
            customOrder: currentState.customOrder,
          ));
        } else {
          emit(PriceListError(message: failure.message));
        }
      },
      (prices) async {
        // お気に入りリストも更新
        final favoritesResult = await getFavorites();
        final favoriteSymbols = favoritesResult.fold(
          (_) => currentFavorites,
          (favorites) => favorites.map((f) => f.symbol).toList(),
        );

        emit(PriceListLoaded(
          prices: prices,
          favoriteSymbols: favoriteSymbols,
          isReorderMode: currentReorderMode,
          customOrder: currentCustomOrder,
        ));
      },
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

  /// お気に入りをトグル
  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<PriceListState> emit,
  ) async {
    if (state is! PriceListLoaded) return;

    final currentState = state as PriceListLoaded;
    final isFavorite = currentState.favoriteSymbols.contains(event.symbol);

    // お気に入りの追加または削除
    final result = isFavorite
        ? await removeFavorite(event.symbol)
        : await addFavorite(event.symbol);

    await result.fold(
      (failure) async {
        // エラーが発生した場合はエラーメッセージを表示
        emit(currentState.copyWith(
          errorMessage: 'お気に入りの${isFavorite ? "削除" : "追加"}に失敗しました',
        ));
      },
      (_) async {
        // お気に入りリストを再読み込み
        final favoritesResult = await getFavorites();
        final favoriteSymbols = favoritesResult.fold(
          (_) => currentState.favoriteSymbols,
          (favorites) => favorites.map((f) => f.symbol).toList(),
        );

        emit(currentState.copyWith(favoriteSymbols: favoriteSymbols));
      },
    );
  }

  /// 並び替えモードをトグル
  Future<void> _onToggleReorderMode(
    ToggleReorderModeEvent event,
    Emitter<PriceListState> emit,
  ) async {
    if (state is! PriceListLoaded) return;

    final currentState = state as PriceListLoaded;
    emit(currentState.copyWith(isReorderMode: !currentState.isReorderMode));
  }

  /// 価格リストを並び替え
  Future<void> _onReorderPrices(
    ReorderPricesEvent event,
    Emitter<PriceListState> emit,
  ) async {
    if (state is! PriceListLoaded) return;

    final currentState = state as PriceListLoaded;
    
    // 元の順序を保存（ロールバック用）
    final originalOrder = List<String>.from(currentState.customOrder);
    
    try {
      // 現在の順序を取得（カスタム順序がある場合はそれを使用）
      final currentOrder = currentState.customOrder.isEmpty
          ? currentState.prices.map((p) => p.symbol).toList()
          : List<String>.from(currentState.customOrder);

      // 並び替えを実行
      int oldIndex = event.oldIndex;
      int newIndex = event.newIndex;
      
      // ReorderableListViewの仕様に合わせて調整
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final symbol = currentOrder.removeAt(oldIndex);
      currentOrder.insert(newIndex, symbol);

      // 新しい順序を保存
      await _saveCustomOrder(currentOrder);

      // 状態を更新
      emit(currentState.copyWith(customOrder: currentOrder));
    } catch (e) {
      // エラーが発生した場合は元の順序に戻す（ロールバック - 要件 8.9）
      emit(currentState.copyWith(
        customOrder: originalOrder,
        errorMessage: '並び替えの保存に失敗しました',
      ));
    }
  }

  /// エラーメッセージをクリア
  Future<void> _onClearErrorMessage(
    ClearErrorMessageEvent event,
    Emitter<PriceListState> emit,
  ) async {
    if (state is! PriceListLoaded) return;

    final currentState = state as PriceListLoaded;
    if (currentState.errorMessage != null) {
      emit(currentState.copyWith(errorMessage: null));
    }
  }

  /// カスタム順序を読み込む
  /// 
  /// ストレージ操作が失敗した場合はデフォルト値（空のリスト）を返す（要件 9.5）
  Future<List<String>> _loadCustomOrder() async {
    try {
      final order = await localStorage.getStringList(AppConstants.priceListOrderKey);
      return order ?? [];
    } catch (e) {
      // エラーが発生した場合は空のリストを返す（デフォルト値）
      return [];
    }
  }

  /// カスタム順序を保存
  /// 
  /// ストレージ操作が失敗した場合は例外をスローして呼び出し元でハンドリング
  Future<void> _saveCustomOrder(List<String> order) async {
    try {
      await localStorage.setStringList(AppConstants.priceListOrderKey, order);
    } catch (e) {
      // エラーを再スローして呼び出し元でハンドリング
      rethrow;
    }
  }

  /// 自動更新タイマーを開始
  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(interval, (_) {
      if (!isClosed) {
        add(const AutoRefreshEvent());
      }
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
