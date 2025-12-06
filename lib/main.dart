import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routing/app_router.dart';
import 'core/services/complication_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/performance_utils.dart';
import 'features/favorites/domain/usecases/get_favorites.dart' as di;
import 'features/price_list/presentation/bloc/price_list_bloc.dart';
import 'features/price_list/presentation/bloc/price_list_event.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 依存性注入の初期化
  await di.init();
  
  // パフォーマンス最適化の初期化
  ImageCacheConfig.optimizeImageCache();
  
  // 通知サービスの初期化
  await NotificationService().initialize();
  
  // コンプリケーションサービスの初期化
  await ComplicationService().initialize();
  
  runApp(const CryptoWatchApp());
}

class CryptoWatchApp extends StatefulWidget {
  const CryptoWatchApp({super.key});

  @override
  State<CryptoWatchApp> createState() => _CryptoWatchAppState();
}

class _CryptoWatchAppState extends State<CryptoWatchApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (_) => di.sl<SettingsBloc>()..add(const LoadSettingsEvent()),
        ),
        BlocProvider<PriceListBloc>(
          create: (context) {
            final bloc = di.sl<PriceListBloc>();
            _loadFavoritesAndPrices(bloc);
            return bloc;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Crypto Watch',
        debugShowCheckedModeBanner: false,
        
        // テーマ設定
        theme: AppTheme.darkTheme,
        
        // ルーティング設定
        initialRoute: AppRoutes.priceList,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }

  /// お気に入りを読み込んで価格データを取得
  /// カスタム通貨とデフォルト通貨の両方をサポート（要件 16.7, 17.10）
  Future<void> _loadFavoritesAndPrices(PriceListBloc bloc) async {
    // Blocが既に閉じられている場合は何もしない
    if (bloc.isClosed) return;
    
    // お気に入りリストを取得
    final getFavorites = di.sl<di.GetFavorites>();
    final favoritesResult = await getFavorites();
    
    // 再度チェック（非同期処理中に閉じられた可能性がある）
    if (bloc.isClosed) return;
    
    favoritesResult.fold(
      (_) {
        // エラー時はデフォルトシンボルを使用
        if (!bloc.isClosed) {
          bloc.add(const LoadPricesEvent(
            symbols: ['BTC', 'ETH', 'XRP', 'BNB', 'SOL'],
          ));
        }
      },
      (favorites) {
        // お気に入りのシンボルリストを取得
        if (!bloc.isClosed) {
          final symbols = favorites.map((f) => f.symbol).toList();
          
          // シンボルが空の場合はデフォルトを使用
          if (symbols.isEmpty) {
            bloc.add(const LoadPricesEvent(
              symbols: ['BTC', 'ETH', 'XRP', 'BNB', 'SOL'],
            ));
          } else {
            // お気に入りの通貨（デフォルト + カスタム）の価格を読み込む
            bloc.add(LoadPricesEvent(symbols: symbols));
          }
        }
      },
    );
    
    // Blocがまだ閉じられていない場合のみ自動更新を開始
    if (!bloc.isClosed) {
      bloc.startAutoRefresh();
    }
  }
}
