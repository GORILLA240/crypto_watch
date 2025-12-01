import 'package:equatable/equatable.dart';

/// 失敗を表す抽象クラス
/// Either型の左側の値として使用され、エラー状態を表現する
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() {
    if (code != null) {
      return '$runtimeType [$code]: $message';
    }
    return '$runtimeType: $message';
  }
}

/// ネットワーク関連の失敗
class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'ネットワーク接続がありません',
    String? code,
  }) : super(message: message, code: code);
}

/// サーバー関連の失敗
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    String message = 'サーバーエラーが発生しました',
    this.statusCode,
    String? code,
  }) : super(message: message, code: code);

  @override
  List<Object?> get props => [message, code, statusCode];

  @override
  String toString() {
    if (statusCode != null) {
      return 'ServerFailure [$statusCode]: $message';
    }
    return super.toString();
  }
}

/// キャッシュ関連の失敗
class CacheFailure extends Failure {
  const CacheFailure({
    String message = 'キャッシュの読み書きに失敗しました',
    String? code,
  }) : super(message: message, code: code);
}

/// バリデーション関連の失敗
class ValidationFailure extends Failure {
  final Map<String, String>? errors;

  const ValidationFailure({
    String message = '入力値が不正です',
    this.errors,
    String? code,
  }) : super(message: message, code: code);

  @override
  List<Object?> get props => [message, code, errors];

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = errors!.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      return 'ValidationFailure: $message ($errorMessages)';
    }
    return super.toString();
  }
}

/// 認証関連の失敗
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    String message = 'APIキーが無効です',
    String? code = 'AUTH_ERROR',
  }) : super(message: message, code: code);
}

/// レート制限の失敗
class RateLimitFailure extends Failure {
  const RateLimitFailure({
    String message = 'リクエスト制限に達しました。しばらくお待ちください',
    String? code = 'RATE_LIMIT',
  }) : super(message: message, code: code);
}

/// パース関連の失敗
class ParseFailure extends Failure {
  const ParseFailure({
    String message = 'データの解析に失敗しました',
    String? code = 'PARSE_ERROR',
  }) : super(message: message, code: code);
}

/// ストレージ関連の失敗
class StorageFailure extends Failure {
  const StorageFailure({
    String message = 'ストレージの操作に失敗しました',
    String? code = 'STORAGE_ERROR',
  }) : super(message: message, code: code);
}

/// タイムアウトの失敗
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    String message = 'リクエストがタイムアウトしました',
    String? code = 'TIMEOUT',
  }) : super(message: message, code: code);
}

/// 予期しないエラー
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    String message = '予期しないエラーが発生しました',
    String? code = 'UNEXPECTED_ERROR',
  }) : super(message: message, code: code);
}

/// データが見つからない失敗
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    String message = 'データが見つかりません',
    String? code = 'NOT_FOUND',
  }) : super(message: message, code: code);
}
