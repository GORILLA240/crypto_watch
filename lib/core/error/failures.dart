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
    super.message = 'ネットワーク接続がありません',
    super.code,
  });
}

/// サーバー関連の失敗
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    super.message = 'サーバーエラーが発生しました',
    this.statusCode,
    super.code,
  });

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
    super.message = 'キャッシュの読み書きに失敗しました',
    super.code,
  });
}

/// バリデーション関連の失敗
class ValidationFailure extends Failure {
  final Map<String, String>? errors;

  const ValidationFailure({
    super.message = '入力値が不正です',
    this.errors,
    super.code,
  });

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
    super.message = 'APIキーが無効です',
    super.code = 'AUTH_ERROR',
  });
}

/// レート制限の失敗
class RateLimitFailure extends Failure {
  const RateLimitFailure({
    super.message = 'リクエスト制限に達しました。しばらくお待ちください',
    super.code = 'RATE_LIMIT',
  });
}

/// パース関連の失敗
class ParseFailure extends Failure {
  const ParseFailure({
    super.message = 'データの解析に失敗しました',
    super.code = 'PARSE_ERROR',
  });
}

/// ストレージ関連の失敗
class StorageFailure extends Failure {
  const StorageFailure({
    super.message = 'ストレージの操作に失敗しました',
    super.code = 'STORAGE_ERROR',
  });
}

/// タイムアウトの失敗
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'リクエストがタイムアウトしました',
    super.code = 'TIMEOUT',
  });
}

/// 予期しないエラー
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = '予期しないエラーが発生しました',
    super.code = 'UNEXPECTED_ERROR',
  });
}

/// データが見つからない失敗
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'データが見つかりません',
    super.code = 'NOT_FOUND',
  });
}
