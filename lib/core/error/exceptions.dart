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
    super.message = 'ネットワーク接続がありません',
    super.code,
    super.originalError,
  });
}

/// タイムアウト例外
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'リクエストがタイムアウトしました',
    super.code,
    super.originalError,
  });
}

/// API関連の例外
class ApiException extends AppException {
  final int? statusCode;

  const ApiException({
    required super.message,
    this.statusCode,
    super.code,
    super.originalError,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException [$statusCode]: $message';
    }
    return 'ApiException: $message';
  }
}

/// 認証エラー（401）
/// バックエンドのエラーコード: UNAUTHORIZED
class AuthenticationException extends ApiException {
  const AuthenticationException({
    super.message = 'APIキーが無効です',
    super.code = 'UNAUTHORIZED',
    super.originalError,
  }) : super(statusCode: 401);
}

/// レート制限エラー（429）
/// バックエンドのエラーコード: RATE_LIMIT_EXCEEDED
class RateLimitException extends ApiException {
  const RateLimitException({
    super.message = 'リクエスト制限に達しました。しばらくお待ちください',
    super.code = 'RATE_LIMIT_EXCEEDED',
    super.originalError,
  }) : super(statusCode: 429);
}

/// サーバーエラー（500番台）
/// バックエンドのエラーコード: INTERNAL_ERROR
class ServerException extends ApiException {
  const ServerException({
    super.message = 'サーバーエラーが発生しました',
    super.statusCode = 500,
    super.code = 'INTERNAL_ERROR',
    super.originalError,
  });
}

/// データ関連の例外
class DataException extends AppException {
  const DataException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// パース例外
class ParseException extends DataException {
  const ParseException({
    super.message = 'データの解析に失敗しました',
    super.code = 'PARSE_ERROR',
    super.originalError,
  });
}

/// キャッシュ例外
class CacheException extends DataException {
  const CacheException({
    super.message = 'キャッシュの読み書きに失敗しました',
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

/// バリデーション例外
class ValidationException extends AppException {
  final Map<String, String>? errors;

  const ValidationException({
    super.message = '入力値が不正です',
    this.errors,
    super.code = 'VALIDATION_ERROR',
    super.originalError,
  });

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
    super.message = 'ストレージの操作に失敗しました',
    super.code = 'STORAGE_ERROR',
    super.originalError,
  });
}

/// 未実装機能例外
class NotImplementedException extends AppException {
  const NotImplementedException({
    super.message = 'この機能はまだ実装されていません',
    super.code = 'NOT_IMPLEMENTED',
    super.originalError,
  });
}
