import 'package:flutter/material.dart';
import '../../features/price_list/presentation/pages/price_list_page.dart';
import '../../features/price_list/presentation/pages/single_view_page.dart';
import '../../features/price_detail/presentation/pages/price_detail_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/alerts/presentation/pages/alerts_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

/// アプリケーションのルート名定義
class AppRoutes {
  // プライベートコンストラクタ
  AppRoutes._();

  static const String priceList = '/';
  static const String priceDetail = '/price-detail';
  static const String singleView = '/single-view';
  static const String favorites = '/favorites';
  static const String alerts = '/alerts';
  static const String settings = '/settings';
}

/// アプリケーションのルーター
class AppRouter {
  // プライベートコンストラクタ
  AppRouter._();

  /// ルート設定を生成
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.priceList:
        return _buildRoute(
          const PriceListPage(),
          settings: settings,
        );

      case AppRoutes.priceDetail:
        final symbol = settings.arguments as String?;
        if (symbol == null) {
          return _buildErrorRoute('Symbol is required for price detail');
        }
        return _buildRoute(
          PriceDetailPage(symbol: symbol),
          settings: settings,
        );

      case AppRoutes.singleView:
        final args = settings.arguments as Map<String, dynamic>?;
        final prices = args?['prices'] as List?;
        final initialIndex = args?['initialIndex'] as int? ?? 0;
        
        if (prices == null) {
          return _buildErrorRoute('Prices list is required');
        }
        
        return _buildRoute(
          SingleViewPage(
            prices: prices.cast(),
            initialIndex: initialIndex,
          ),
          settings: settings,
        );

      case AppRoutes.favorites:
        return _buildRoute(
          const FavoritesPage(),
          settings: settings,
        );

      case AppRoutes.alerts:
        return _buildRoute(
          const AlertsPage(),
          settings: settings,
        );

      case AppRoutes.settings:
        return _buildRoute(
          const SettingsPage(),
          settings: settings,
        );

      default:
        return _buildErrorRoute('Route not found: ${settings.name}');
    }
  }

  /// ページ遷移アニメーション付きルートを構築
  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page, {
    required RouteSettings settings,
  }) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }

  /// エラールートを構築
  static MaterialPageRoute<dynamic> _buildErrorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 名前付きルートへ遷移
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// 名前付きルートへ置き換え
  static Future<T?> navigateReplaceTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, void>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// すべてのルートをクリアして遷移
  static Future<T?> navigateAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// 戻る
  static void goBack<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  /// 戻れるかチェック
  static bool canGoBack(BuildContext context) {
    return Navigator.canPop(context);
  }
}
