import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/display_density.dart';
import '../../../../core/utils/safe_area_calculator.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../domain/entities/crypto_price.dart';
import '../bloc/price_list_bloc.dart';
import '../bloc/price_list_event.dart';
import '../bloc/price_list_state.dart';
import '../widgets/error_message.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/price_list_item.dart';

/// 価格リスト画面
class PriceListPage extends StatelessWidget {
  const PriceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // グローバルなPriceListBlocを使用
    return const _PriceListPageContent();
  }
}

class _PriceListPageContent extends StatelessWidget {
  const _PriceListPageContent();

  /// カスタム順序を適用
  List<CryptoPrice> _applyCustomOrder(
    List<CryptoPrice> prices,
    List<String> customOrder,
  ) {
    if (customOrder.isEmpty) return prices;

    final priceMap = {for (var p in prices) p.symbol: p};
    final ordered = <CryptoPrice>[];

    // カスタム順序に従って並べる
    for (final symbol in customOrder) {
      if (priceMap.containsKey(symbol)) {
        ordered.add(priceMap[symbol]!);
        priceMap.remove(symbol);
      }
    }

    // 残りを追加（新しく追加された通貨など）
    ordered.addAll(priceMap.values);

    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PriceListBloc, PriceListState>(
      listener: (context, state) {
        // エラーメッセージがある場合はSnackBarで表示
        if (state is PriceListLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: '閉じる',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  context.read<PriceListBloc>().add(const ClearErrorMessageEvent());
                },
              ),
            ),
          ).closed.then((_) {
            // SnackBarが閉じられたらエラーメッセージをクリア
            if (context.mounted) {
              context.read<PriceListBloc>().add(const ClearErrorMessageEvent());
            }
          });
        }
      },
      child: BlocBuilder<PriceListBloc, PriceListState>(
        builder: (context, state) {
          final isReorderMode = state is PriceListLoaded && state.isReorderMode;

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
            title: Text(
              isReorderMode ? '並び替えモード' : 'Crypto Watch',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.black,
            elevation: 0,
            actions: [
              if (!isReorderMode) ...[
                IconButton(
                  icon: const Icon(Icons.star, color: Colors.white),
                  iconSize: 24,
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  onPressed: () {
                    AppRouter.navigateTo(context, AppRoutes.favorites);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  iconSize: 24,
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  onPressed: () {
                    AppRouter.navigateTo(context, AppRoutes.alerts);
                  },
                ),
              ],
              IconButton(
                icon: Icon(
                  isReorderMode ? Icons.check : Icons.reorder,
                  color: Colors.white,
                ),
                iconSize: 24,
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                onPressed: () {
                  context.read<PriceListBloc>().add(const ToggleReorderModeEvent());
                },
              ),
              // 設定アイコンは常に表示（要件 3.1, 3.5）
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                iconSize: 24,
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                onPressed: () {
                  AppRouter.navigateTo(context, AppRoutes.settings);
                },
              ),
            ],
          ),
            body: _buildBody(context, state),
            // FloatingActionButtonを削除（要件 4.1）
            // プルトゥリフレッシュで更新可能
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PriceListState state) {
    // 画面サイズを取得して円形画面かどうかを判定（要件 5.1, 5.2）
    final screenSize = MediaQuery.of(context).size;
    final isCircular = screenSize.width == screenSize.height;
    final safeInsets = SafeAreaCalculator.calculateSafeInsets(screenSize, isCircular);
    
    return BlocBuilder<PriceListBloc, PriceListState>(
        builder: (context, state) {
          if (state is PriceListLoading) {
            return const LoadingIndicator(
              message: '価格データを読み込み中...',
            );
          }

          if (state is PriceListError) {
            return ErrorMessage(
              message: state.message,
              onRetry: () {
                context.read<PriceListBloc>().add(
                      const LoadPricesEvent(
                        symbols: ApiConstants.defaultSymbols,
                      ),
                    );
              },
            );
          }

          if (state is PriceListLoaded || state is PriceListRefreshing) {
            final prices = state is PriceListLoaded
                ? state.prices
                : (state as PriceListRefreshing).prices;
            final favoriteSymbols = state is PriceListLoaded
                ? state.favoriteSymbols.toSet()
                : (state as PriceListRefreshing).favoriteSymbols.toSet();
            final isReorderMode = state is PriceListLoaded
                ? state.isReorderMode
                : (state as PriceListRefreshing).isReorderMode;
            final customOrder = state is PriceListLoaded
                ? state.customOrder
                : (state as PriceListRefreshing).customOrder;

            // カスタム順序を適用
            final orderedPrices = _applyCustomOrder(prices, customOrder);

            return BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                final displayCurrency = settingsState is SettingsLoaded
                    ? settingsState.settings.displayCurrency.code
                    : 'JPY';
                final displayDensity = settingsState is SettingsLoaded
                    ? settingsState.settings.displayDensity
                    : DisplayDensity.standard;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<PriceListBloc>().add(const RefreshPricesEvent());
                    // Wait a bit for the refresh to complete
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  color: Colors.white,
                  backgroundColor: Colors.grey[900],
                  child: isReorderMode
                      ? ReorderableListView.builder(
                          itemCount: orderedPrices.length,
                          // パフォーマンス最適化: 固定高さを指定（要件 6.1）
                          itemExtent: DisplayDensityHelper.getConfig(displayDensity).itemHeight,
                          // 円形画面対応: 安全領域を確保（要件 5.1, 5.2, 5.5）
                          padding: EdgeInsets.symmetric(
                            horizontal: safeInsets.left > 8.0 ? safeInsets.left : 8.0,
                          ),
                          onReorder: (oldIndex, newIndex) {
                            context.read<PriceListBloc>().add(
                              ReorderPricesEvent(
                                oldIndex: oldIndex,
                                newIndex: newIndex,
                              ),
                            );
                          },
                          itemBuilder: (context, index) {
                            final price = orderedPrices[index];
                            final isFavorite = favoriteSymbols.contains(price.symbol);
                            
                            return PriceListItem(
                              key: ValueKey(price.symbol),
                              price: price,
                              displayCurrency: displayCurrency,
                              displayDensity: displayDensity,
                              isFavorite: isFavorite,
                              isReorderMode: isReorderMode,
                              onTap: null, // 並び替えモード中はタップ無効
                              onLongPress: () {
                                context.read<PriceListBloc>().add(
                                  ToggleFavoriteEvent(symbol: price.symbol),
                                );
                              },
                            );
                          },
                        )
                      : ListView.builder(
                          itemCount: orderedPrices.length,
                          // パフォーマンス最適化: 固定高さを指定（要件 6.1）
                          itemExtent: DisplayDensityHelper.getConfig(displayDensity).itemHeight,
                          // キャッシュ範囲を最適化
                          cacheExtent: DisplayDensityHelper.getConfig(displayDensity).itemHeight * 3,
                          // 円形画面対応: 安全領域を確保（要件 5.1, 5.2, 5.5）
                          padding: EdgeInsets.symmetric(
                            horizontal: safeInsets.left > 8.0 ? safeInsets.left : 8.0,
                          ),
                          itemBuilder: (context, index) {
                            final price = orderedPrices[index];
                            final isFavorite = favoriteSymbols.contains(price.symbol);
                            
                            return PriceListItem(
                              key: ValueKey(price.symbol),
                              price: price,
                              displayCurrency: displayCurrency,
                              displayDensity: displayDensity,
                              isFavorite: isFavorite,
                              isReorderMode: isReorderMode,
                              onTap: () {
                                AppRouter.navigateTo(
                                  context,
                                  AppRoutes.priceDetail,
                                  arguments: price.symbol,
                                );
                              },
                              onLongPress: () {
                                context.read<PriceListBloc>().add(
                                  ToggleFavoriteEvent(symbol: price.symbol),
                                );
                              },
                            );
                          },
                        ),
                );
              },
            );
          }

          return const Center(
            child: Text(
              'データがありません',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          );
        },
      );
  }
}
