import 'package:flutter/material.dart';
import '../error/failures.dart';

/// エラー表示とリトライ機能を持つウィジェット
class ErrorRetryWidget extends StatelessWidget {
  final Failure? failure;
  final String? errorMessage;
  final VoidCallback onRetry;
  final String? retryButtonText;
  final IconData? errorIcon;
  final bool showDetails;

  const ErrorRetryWidget({
    super.key,
    this.failure,
    this.errorMessage,
    required this.onRetry,
    this.retryButtonText,
    this.errorIcon,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _getErrorMessage();
    final icon = _getErrorIcon();
    final color = _getErrorColor();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            if (showDetails && failure != null) ...[
              const SizedBox(height: 12),
              Text(
                failure!.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryButtonText ?? '再試行'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getErrorMessage() {
    if (errorMessage != null) return errorMessage!;
    if (failure == null) return 'エラーが発生しました';

    if (failure is NetworkFailure) {
      return 'ネットワーク接続がありません';
    } else if (failure is ServerFailure) {
      return 'サーバーエラーが発生しました';
    } else if (failure is CacheFailure) {
      return 'データの読み込みに失敗しました';
    } else if (failure is AuthenticationFailure) {
      return '認証エラーが発生しました';
    } else if (failure is RateLimitFailure) {
      return 'リクエスト制限に達しました\nしばらくお待ちください';
    } else {
      return 'エラーが発生しました';
    }
  }

  IconData _getErrorIcon() {
    if (errorIcon != null) return errorIcon!;
    if (failure == null) return Icons.error_outline;

    if (failure is NetworkFailure) {
      return Icons.wifi_off;
    } else if (failure is ServerFailure) {
      return Icons.cloud_off;
    } else if (failure is CacheFailure) {
      return Icons.storage;
    } else if (failure is AuthenticationFailure) {
      return Icons.lock_outline;
    } else if (failure is RateLimitFailure) {
      return Icons.timer_off;
    } else {
      return Icons.error_outline;
    }
  }

  Color _getErrorColor() {
    if (failure is NetworkFailure) {
      return Colors.orange;
    } else if (failure is ServerFailure) {
      return Colors.red;
    } else if (failure is AuthenticationFailure) {
      return Colors.amber;
    } else if (failure is RateLimitFailure) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }
}

/// コンパクトなエラー表示ウィジェット
class CompactErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const CompactErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.error_outline,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              color: theme.colorScheme.primary,
              tooltip: '再試行',
            ),
          ],
        ],
      ),
    );
  }
}

/// エラーバナーウィジェット
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    '再試行',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
