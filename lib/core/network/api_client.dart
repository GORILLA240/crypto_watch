import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../error/exceptions.dart';

/// HTTPクライアントのラッパークラス
/// APIとの通信を担当し、エラーハンドリングとヘッダー管理を行う
class ApiClient {
  final http.Client client;
  final String baseUrl;
  final String apiKey;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    String? apiKey,
  })  : client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConstants.baseUrl,
        apiKey = apiKey ?? ApiConstants.apiKey;

  /// 共通のHTTPヘッダーを取得
  Map<String, String> get _headers => {
        ApiConstants.apiKeyHeader: apiKey,
        ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
        ApiConstants.acceptEncodingHeader: ApiConstants.acceptEncodingGzip,
      };

  /// GETリクエストを実行
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      // クエリパラメータを含むURIを構築
      final uri = _buildUri(endpoint, queryParameters);

      // リクエストを実行
      final response = await client
          .get(uri, headers: _headers)
          .timeout(ApiConstants.connectionTimeout);

      // レスポンスを処理
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'ネットワーク接続がありません',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'ネットワークエラーが発生しました',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw TimeoutException(
        message: 'リクエストがタイムアウトしました',
        originalError: e,
      );
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ApiException(
        message: '予期しないエラーが発生しました: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// POSTリクエストを実行
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);

      final response = await client
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.connectionTimeout);

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'ネットワーク接続がありません',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      throw NetworkException(
        message: 'ネットワークエラーが発生しました',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw TimeoutException(
        message: 'リクエストがタイムアウトしました',
        originalError: e,
      );
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ApiException(
        message: '予期しないエラーが発生しました: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// URIを構築
  Uri _buildUri(String endpoint, Map<String, String>? queryParameters) {
    final uri = Uri.parse('$baseUrl$endpoint');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters);
    }
    return uri;
  }

  /// HTTPレスポンスを処理
  Map<String, dynamic> _handleResponse(http.Response response) {
    // ステータスコードに応じて処理
    switch (response.statusCode) {
      case 200:
      case 201:
        // 成功レスポンス
        return _parseResponse(response);

      case 400:
        // バリデーションエラー
        final errorData = _parseResponse(response);
        throw ValidationException(
          message: errorData['message'] ?? '入力値が不正です',
          code: errorData['code'],
        );

      case 401:
        // 認証エラー
        final errorData = _parseResponse(response);
        throw AuthenticationException(
          message: errorData['message'] ?? 'APIキーが無効です',
          code: errorData['code'],
        );

      case 429:
        // レート制限エラー
        final errorData = _parseResponse(response);
        throw RateLimitException(
          message: errorData['message'] ?? 'リクエスト制限に達しました',
          code: errorData['code'],
        );

      case 500:
      case 502:
      case 503:
      case 504:
        // サーバーエラー
        final errorData = _parseResponse(response);
        throw ServerException(
          message: errorData['message'] ?? 'サーバーエラーが発生しました',
          statusCode: response.statusCode,
          code: errorData['code'],
        );

      default:
        // その他のエラー
        throw ApiException(
          message: 'HTTPエラー: ${response.statusCode}',
          statusCode: response.statusCode,
        );
    }
  }

  /// レスポンスボディをパース
  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return {};
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } catch (e) {
      throw ParseException(
        message: 'レスポンスの解析に失敗しました',
        originalError: e,
      );
    }
  }

  /// クライアントをクローズ
  void dispose() {
    client.close();
  }
}
