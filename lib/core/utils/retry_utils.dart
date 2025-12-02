import 'dart:async';
import 'package:flutter/foundation.dart';

/// リトライ設定
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool Function(dynamic error)? retryIf;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryIf,
  });

  /// デフォルト設定
  static const RetryConfig defaultConfig = RetryConfig();

  /// ネットワークエラー用の設定
  static const RetryConfig networkConfig = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 10),
    backoffMultiplier: 2.0,
  );

  /// API呼び出し用の設定
  static const RetryConfig apiConfig = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 5),
    backoffMultiplier: 1.5,
  );
}

/// リトライユーティリティ
class RetryUtils {
  RetryUtils._();

  /// 指数バックオフでリトライを実行
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    RetryConfig config = RetryConfig.defaultConfig,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempt = 0;
    Duration delay = config.initialDelay;

    while (true) {
      attempt++;

      try {
        return await operation();
      } catch (error) {
        // 最大試行回数に達した場合
        if (attempt >= config.maxAttempts) {
          if (kDebugMode) {
            debugPrint('❌ Retry failed after $attempt attempts: $error');
          }
          rethrow;
        }

        // リトライ条件をチェック
        if (config.retryIf != null && !config.retryIf!(error)) {
          if (kDebugMode) {
            debugPrint('❌ Retry condition not met: $error');
          }
          rethrow;
        }

        // リトライコールバック
        onRetry?.call(attempt, error);

        if (kDebugMode) {
          debugPrint(
            '🔄 Retry attempt $attempt/${ config.maxAttempts} after ${delay.inMilliseconds}ms',
          );
        }

        // 待機
        await Future.delayed(delay);

        // 次の遅延時間を計算（指数バックオフ）
        delay = Duration(
          milliseconds: (delay.inMilliseconds * config.backoffMultiplier)
              .round()
              .clamp(0, config.maxDelay.inMilliseconds),
        );
      }
    }
  }

  /// タイムアウト付きリトライ
  static Future<T> retryWithTimeout<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    RetryConfig config = RetryConfig.defaultConfig,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    return retry(
      () => operation().timeout(timeout),
      config: config,
      onRetry: onRetry,
    );
  }

  /// 条件付きリトライ
  static Future<T> retryIf<T>(
    Future<T> Function() operation, {
    required bool Function(dynamic error) condition,
    RetryConfig? config,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    final retryConfig = config ?? RetryConfig.defaultConfig;
    return retry(
      operation,
      config: RetryConfig(
        maxAttempts: retryConfig.maxAttempts,
        initialDelay: retryConfig.initialDelay,
        maxDelay: retryConfig.maxDelay,
        backoffMultiplier: retryConfig.backoffMultiplier,
        retryIf: condition,
      ),
      onRetry: onRetry,
    );
  }

  /// ネットワークエラーのみリトライ
  static Future<T> retryOnNetworkError<T>(
    Future<T> Function() operation, {
    RetryConfig config = RetryConfig.networkConfig,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    return retryIf(
      operation,
      condition: (error) => _isNetworkError(error),
      config: config,
      onRetry: onRetry,
    );
  }

  /// ネットワークエラーかどうかを判定
  static bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('failed host lookup');
  }
}

/// リトライ可能な操作のラッパー
class RetryableOperation<T> {
  final Future<T> Function() operation;
  final RetryConfig config;
  final void Function(int attempt, dynamic error)? onRetry;
  final void Function(T result)? onSuccess;
  final void Function(dynamic error)? onError;

  RetryableOperation({
    required this.operation,
    this.config = RetryConfig.defaultConfig,
    this.onRetry,
    this.onSuccess,
    this.onError,
  });

  /// 実行
  Future<T> execute() async {
    try {
      final result = await RetryUtils.retry(
        operation,
        config: config,
        onRetry: onRetry,
      );
      onSuccess?.call(result);
      return result;
    } catch (error) {
      onError?.call(error);
      rethrow;
    }
  }

  /// タイムアウト付きで実行
  Future<T> executeWithTimeout(Duration timeout) async {
    try {
      final result = await RetryUtils.retryWithTimeout(
        operation,
        timeout: timeout,
        config: config,
        onRetry: onRetry,
      );
      onSuccess?.call(result);
      return result;
    } catch (error) {
      onError?.call(error);
      rethrow;
    }
  }
}
