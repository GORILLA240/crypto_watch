/// API関連の定数定義
class ApiConstants {
  // プライベートコンストラクタ - インスタンス化を防ぐ
  ApiConstants._();

  // API基底URL（環境変数から取得）
  // デプロイ後は --dart-define=API_BASE_URL=<your-url> で指定
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
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
  // バックエンドのtemplate.yamlのSupportedSymbolsパラメータと同期すること
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
    'XRP',
    'BNB',
    'SOL',
  ];

  // サポート通貨リストの同期に関する注意:
  // このリストはバックエンドのtemplate.yamlのSupportedSymbolsパラメータと
  // 手動で同期する必要があります。将来的にはAPIから動的に取得することを推奨します。
}
