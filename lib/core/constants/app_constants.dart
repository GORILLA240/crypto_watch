/// アプリケーション全体で使用される定数定義
class AppConstants {
  // プライベートコンストラクタ - インスタンス化を防ぐ
  AppConstants._();

  // アプリケーション情報
  static const String appName = 'Crypto Watch';
  static const String appVersion = '1.0.0';

  // 自動更新設定
  static const Duration autoRefreshInterval = Duration(seconds: 30);
  static const Duration autoRefreshMinInterval = Duration(seconds: 10);

  // キャッシュ設定
  static const Duration cacheValidDuration = Duration(minutes: 5);
  static const int maxCacheSize = 100;

  // UI設定
  static const int pricesPerPage = 20;
  static const int itemsPerScreenSmall = 3;
  static const int itemsPerScreenMedium = 5;
  static const double minTapTargetSize = 48.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // フォントサイズ
  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeXLarge = 24.0;
  static const double fontSizeXXLarge = 36.0;
  static const double fontSizeHuge = 48.0;

  // アニメーション設定
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // ローカルストレージキー
  static const String favoritesKey = 'favorites';
  static const String settingsKey = 'settings';
  static const String alertsKey = 'alerts';
  static const String lastUpdateKey = 'last_update';
  static const String displayCurrencyKey = 'display_currency';
  static const String autoRefreshEnabledKey = 'auto_refresh_enabled';
  static const String notificationsEnabledKey = 'notifications_enabled';

  // 通貨設定
  static const List<String> supportedCurrencies = ['JPY', 'USD', 'EUR', 'BTC'];
  static const String defaultCurrency = 'JPY';

  // 通貨記号
  static const Map<String, String> currencySymbols = {
    'JPY': '¥',
    'USD': '\$',
    'EUR': '€',
    'BTC': '₿',
  };

  // 為替レート（仮の値、実際はAPIから取得）
  static const Map<String, double> exchangeRates = {
    'JPY': 1.0,
    'USD': 0.0067,
    'EUR': 0.0062,
  };

  // チャート設定
  static const List<String> chartPeriods = ['1H', '24H', '7D'];
  static const String defaultChartPeriod = '24H';

  // エラーメッセージ
  static const String networkErrorMessage = 'ネットワーク接続がありません';
  static const String apiErrorMessage = 'データの取得に失敗しました';
  static const String authErrorMessage = 'APIキーが無効です';
  static const String rateLimitErrorMessage = 'リクエスト制限に達しました。しばらくお待ちください';
  static const String unknownErrorMessage = '予期しないエラーが発生しました';
  static const String noDataMessage = 'データがありません';
  static const String noFavoritesMessage = '銘柄を追加してください';

  // リトライ設定
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // レート制限
  static const int maxRequestsPerMinute = 100;

  // 通知設定
  static const String notificationChannelId = 'crypto_watch_alerts';
  static const String notificationChannelName = 'Price Alerts';
  static const String notificationChannelDescription = '価格アラート通知';

  // パフォーマンス設定
  static const int targetFps = 60;
  static const Duration frameTime = Duration(milliseconds: 16); // 1000ms / 60fps

  // デバッグ設定
  static const bool enableLogging = true;
  static const bool enablePerformanceMonitoring = true;
}
