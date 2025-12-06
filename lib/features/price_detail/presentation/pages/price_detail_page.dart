import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../price_list/domain/entities/crypto_price.dart';
import '../../../price_list/presentation/bloc/price_list_bloc.dart';
import '../../../price_list/presentation/bloc/price_list_state.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../widgets/price_stats.dart';

/// 価格詳細画面
class PriceDetailPage extends StatefulWidget {
  final String symbol;

  const PriceDetailPage({
    super.key,
    required this.symbol,
  });

  @override
  State<PriceDetailPage> createState() => _PriceDetailPageState();
}

class _PriceDetailPageState extends State<PriceDetailPage> {
  String _selectedPeriod = '24H';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              onPressed: () {
                AppRouter.navigateTo(context, AppRoutes.favorites);
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              onPressed: () {
                AppRouter.navigateTo(context, AppRoutes.alerts);
              },
            ),
          ],
        ),
        body: BlocBuilder<PriceListBloc, PriceListState>(
          builder: (context, priceState) {
            if (priceState is! PriceListLoaded && priceState is! PriceListRefreshing) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final prices = priceState is PriceListLoaded
                ? priceState.prices
                : (priceState as PriceListRefreshing).prices;

            // シンボルに一致する価格を検索
            CryptoPrice? foundPrice;
            try {
              foundPrice = prices.firstWhere((p) => p.symbol == widget.symbol);
            } catch (e) {
              // 見つからない場合は最初の価格を使用
              foundPrice = prices.isNotEmpty ? prices.first : null;
            }

            if (foundPrice == null) {
              return const Center(
                child: Text(
                  '価格データが見つかりません',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            // null チェック後、non-nullable変数に代入
            final price = foundPrice;

            return BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                final displayCurrency = settingsState is SettingsLoaded
                    ? settingsState.settings.displayCurrency.code
                    : 'JPY';

                final isPositive = price.change24h >= 0;
                final changeColor = isPositive ? Colors.green : Colors.red;

                // BTC換算は現時点では未対応
                final effectiveCurrency = displayCurrency == 'BTC' ? 'USD' : displayCurrency;

                // 価格をUSDから指定通貨に換算
                final convertedPrice = CurrencyFormatter.convert(
                  price.price,
                  fromCurrency: 'USD',
                  toCurrency: effectiveCurrency,
                );

                // 24時間の高値・安値を計算（仮の計算）
                final high24h = CurrencyFormatter.convert(
                  price.price * 1.04,
                  fromCurrency: 'USD',
                  toCurrency: effectiveCurrency,
                );
                final low24h = CurrencyFormatter.convert(
                  price.price * 0.96,
                  fromCurrency: 'USD',
                  toCurrency: effectiveCurrency,
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price display
                      Center(
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.format(
                                  convertedPrice,
                                  currency: effectiveCurrency,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                CurrencyFormatter.formatChangePercent(price.change24h),
                                style: TextStyle(
                                  color: changeColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Chart period selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['1H', '24H', '7D'].map((period) {
                          final isSelected = _selectedPeriod == period;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedPeriod = period;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      isSelected ? Colors.blue : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    period,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey,
                                      fontSize: 14,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Chart placeholder
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'チャートデータを読み込み中...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Stats - 24時間の高値・安値・出来高
                      PriceStats(
                        high24h: high24h,
                        low24h: low24h,
                        volume24h: price.marketCap * 0.1, // 仮の計算: 時価総額の10%
                        displayCurrency: effectiveCurrency,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
  }
}
