/// API関連の定数定義
class ApiConstants {
  // プライベートコンストラクタ - インスタンス化を防ぐ
  ApiConstants._();

  // API基底URL（環境変数から取得、デフォルトは開発環境）
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-api-gateway-url.execute-api.region.amazonaws.com/dev',
  );

  // APIキー（環境変数から取得）
  static const String apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: '',
  );

  // エンドポイント
  static const String pricesEndpoint = '/prices';
  static const String healthEndpoint = '/health';

  // HTTPヘッダー
  static const String apiKeyHeader = 'X-API-Key';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptEncodingHeader = 'Accept-Encoding';
  static const String contentTypeJson = 'application/json';
  static const String acceptEncodingGzip = 'gzip';

  // タイムアウト設定
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // サポートされる暗号通貨シンボル
  static const List<String> supportedSymbols = [
    'BTC',
    'ETH',
    'ADA',
    'BNB',
    'XRP',
    'SOL',
    'DOT',
    'DOGE',
    'AVAX',
    'MATIC',
    'LINK',
    'UNI',
    'LTC',
    'ATOM',
    'XLM',
    'ALGO',
    'VET',
    'ICP',
    'FIL',
    'TRX',
  ];

  // デフォルトで表示する暗号通貨
  static const List<String> defaultSymbols = [
    'BTC',
    'ETH',
    'ADA',
    'BNB',
    'XRP',
  ];
}
