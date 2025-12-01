import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../injection_container.dart';
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
    return BlocProvider(
      create: (_) => sl<PriceListBloc>()
        ..add(const LoadPricesEvent(
          symbols: ApiConstants.defaultSymbols,
        ))
        ..startAutoRefresh(),
      child: const _PriceListPageContent(),
    );
  }
}

class _PriceListPageContent extends StatelessWidget {
  const _PriceListPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Crypto Watch',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<PriceListBloc>().add(const RefreshPricesEvent());
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: BlocBuilder<PriceListBloc, PriceListState>(
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

            return RefreshIndicator(
              onRefresh: () async {
                context.read<PriceListBloc>().add(const RefreshPricesEvent());
                // Wait a bit for the refresh to complete
                await Future.delayed(const Duration(seconds: 1));
              },
              color: Colors.white,
              backgroundColor: Colors.grey[900],
              child: ListView.builder(
                itemCount: prices.length,
                itemBuilder: (context, index) {
                  final price = prices[index];
                  return PriceListItem(
                    price: price,
                    onTap: () {
                      // TODO: Navigate to detail page
                    },
                  );
                },
              ),
            );
          }

          return const Center(
            child: Text(
              'データがありません',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<PriceListBloc>().add(const RefreshPricesEvent());
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
