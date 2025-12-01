/// アプリケーション全体で使用されるカスタム例外クラス
library;

/// 基底例外クラス
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() {
    if (code != null) {
      return 'AppException [$code]: $message';
    }
    return 'AppException: $message';
  }
}

/// ネットワーク関連の例外
class NetworkException extends AppException {
  const NetworkException({
    String message = 'ネットワーク接続がありません',
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

/// タイムアウト例外
class TimeoutException extends AppException {
  const TimeoutException({
    String message = 'リクエストがタイムアウトしました',
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

/// API関連の例外
class ApiException extends AppException {
  final int? statusCode;

  const ApiException({
    required String message,
    this.statusCode,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException [${statusCode}]: $message';
    }
    return 'ApiException: $message';
  }
}

/// 認証エラー（401）
class AuthenticationException extends ApiException {
  const AuthenticationException({
    String message = 'APIキーが無効です',
    String? code = 'AUTH_ERROR',
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: 401,
          code: code,
          originalError: originalError,
        );
}

/// レート制限エラー（429）
class RateLimitException extends ApiException {
  const RateLimitException({
    String message = 'リクエスト制限に達しました。しばらくお待ちください',
    String? code = 'RATE_LIMIT',
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: 429,
          code: code,
          originalError: originalError,
        );
}

/// サーバーエラー（500番台）
class ServerException extends ApiException {
  const ServerException({
    String message = 'サーバーエラーが発生しました',
    int? statusCode = 500,
    String? code = 'SERVER_ERROR',
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: statusCode,
          code: code,
          originalError: originalError,
        );
}

/// データ関連の例外
class DataException extends AppException {
  const DataException({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

/// パース例外
class ParseException extends DataException {
  const ParseException({
    String message = 'データの解析に失敗しました',
    String? code = 'PARSE_ERROR',
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

/// キャッシュ例外
class CacheException extends DataException {
  const CacheException({
    String message = 'キャッシュの読み書きに失敗しました',
    String? code = 'CACHE_ERROR',
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

/// バリデーション例外
class ValidationException extends AppException {
  final Map<String, String>? errors;

  const ValidationException({
    String message = '入力値が不正です',
    this.errors,
    String? code = 'VALIDATION_ERROR',
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = errors!.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      return 'ValidationException: $message ($errorMessages)';
    }
    return 'ValidationException: $message';
  }
}

/// ストレージ例外
class StorageException extends AppException {
  const StorageException({
    String message = 'ストレージの操作に失敗しました',
    String? code = 'STORAGE_ERROR',
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}

/// 未実装機能例外
class NotImplementedException extends AppException {
  const NotImplementedException({
    String message = 'この機能はまだ実装されていません',
    String? code = 'NOT_IMPLEMENTED',
    dynamic originalError,
  }) : super(
          message: message,
          code: code,
          originalError: originalError,
        );
}
