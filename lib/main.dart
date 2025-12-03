import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/routing/app_router.dart';
import 'core/services/complication_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/performance_utils.dart';
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

class CryptoWatchApp extends StatelessWidget {
  const CryptoWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (_) => di.sl<SettingsBloc>()..add(const LoadSettingsEvent()),
        ),
        BlocProvider<PriceListBloc>(
          create: (_) => di.sl<PriceListBloc>()
            ..add(const LoadPricesEvent(
              symbols: ['BTC', 'ETH', 'XRP', 'BNB', 'SOL'],
            ))
            ..startAutoRefresh(),
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
}
