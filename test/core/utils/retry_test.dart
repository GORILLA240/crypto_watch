import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/utils/retry_utils.dart';

/// プロパティ7: エラー後の回復
/// 検証: 要件4.5
/// 
/// リトライ機能が正しく動作し、エラーから回復できることを検証
void main() {
  group('Retry Utils Tests', () {
    test('retry should succeed on first attempt if no error', () async {
      // Arrange
      int callCount = 0;
      Future<String> operation() async {
        callCount++;
        return 'success';
      }

      // Act
      final result = await RetryUtils.retry(operation);

      // Assert
      expect(result, equals('success'));
      expect(callCount, equals(1));
    });

    test('retry should retry on failure and eventually succeed', () async {
      // Arrange
      int callCount = 0;
      Future<String> operation() async {
        callCount++;
        if (callCount < 3) {
          throw Exception('Temporary error');
        }
        return 'success';
      }

      // Act
      final result = await RetryUtils.retry(
        operation,
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
      );

      // Assert
      expect(result, equals('success'));
      expect(callCount, equals(3));
    });

    test('retry should throw after max attempts', () async {
      // Arrange
      int callCount = 0;
      Future<String> operation() async {
        callCount++;
        throw Exception('Persistent error');
      }

      // Act & Assert
      expect(
        () => RetryUtils.retry(
          operation,
          config: const RetryConfig(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 10),
          ),
        ),
        throwsException,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, equals(3));
    });

    test('retry should respect retryIf condition', () async {
      // Arrange
      int callCount = 0;
      Future<String> operation() async {
        callCount++;
        throw Exception('Network error');
      }

      // Act & Assert - should not retry
      expect(
        () => RetryUtils.retry(
          operation,
          config: RetryConfig(
            maxAttempts: 3,
            initialDelay: const Duration(milliseconds: 10),
            retryIf: (error) => false, // Never retry
          ),
        ),
        throwsException,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount, equals(1)); // Only called once
    });

    test('retryWithTimeout should timeout long operations', () async {
      // Arrange
      Future<String> operation() async {
        await Future.delayed(const Duration(seconds: 2));
        return 'success';
      }

      // Act & Assert
      expect(
        () => RetryUtils.retryWithTimeout(
          operation,
          timeout: const Duration(milliseconds: 100),
          config: const RetryConfig(
            maxAttempts: 1,
            initialDelay: Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('onRetry callback should be called on each retry', () async {
      // Arrange
      int callCount = 0;
      int retryCallbackCount = 0;
      Future<String> operation() async {
        callCount++;
        if (callCount < 3) {
          throw Exception('Error');
        }
        return 'success';
      }

      // Act
      await RetryUtils.retry(
        operation,
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
        onRetry: (attempt, error) {
          retryCallbackCount++;
        },
      );

      // Assert
      expect(retryCallbackCount, equals(2)); // Called on 2 retries
    });
  });

  group('Retry Config Tests', () {
    test('default config should have reasonable values', () {
      // Arrange
      const config = RetryConfig.defaultConfig;

      // Assert
      expect(config.maxAttempts, equals(3));
      expect(config.initialDelay, equals(const Duration(seconds: 1)));
      expect(config.maxDelay, equals(const Duration(seconds: 30)));
      expect(config.backoffMultiplier, equals(2.0));
    });

    test('network config should be optimized for network errors', () {
      // Arrange
      const config = RetryConfig.networkConfig;

      // Assert
      expect(config.maxAttempts, equals(3));
      expect(config.initialDelay.inMilliseconds, lessThan(1000));
    });
  });

  group('Retryable Operation Tests', () {
    test('RetryableOperation should execute successfully', () async {
      // Arrange
      bool successCalled = false;
      final operation = RetryableOperation<String>(
        operation: () async => 'success',
        onSuccess: (result) {
          successCalled = true;
        },
      );

      // Act
      final result = await operation.execute();

      // Assert
      expect(result, equals('success'));
      expect(successCalled, isTrue);
    });

    test('RetryableOperation should call onError on failure', () async {
      // Arrange
      bool errorCalled = false;
      final operation = RetryableOperation<String>(
        operation: () async => throw Exception('Error'),
        config: const RetryConfig(
          maxAttempts: 1,
          initialDelay: Duration(milliseconds: 10),
        ),
        onError: (error) {
          errorCalled = true;
        },
      );

      // Act & Assert
      expect(() => operation.execute(), throwsException);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(errorCalled, isTrue);
    });
  });

  group('Property 7: Error Recovery', () {
    /// プロパティ: リトライは最終的に成功するか、最大試行回数で失敗する
    test('retry always either succeeds or fails after max attempts', () async {
      // Test case 1: Eventually succeeds
      int successAttempt = 0;
      Future<String> eventuallySucceeds() async {
        successAttempt++;
        if (successAttempt < 2) throw Exception('Error');
        return 'success';
      }

      final result1 = await RetryUtils.retry(
        eventuallySucceeds,
        config: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
      );
      expect(result1, equals('success'));
      expect(successAttempt, lessThanOrEqualTo(3));

      // Test case 2: Always fails
      int failAttempt = 0;
      Future<String> alwaysFails() async {
        failAttempt++;
        throw Exception('Persistent error');
      }

      try {
        await RetryUtils.retry(
          alwaysFails,
          config: const RetryConfig(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 10),
          ),
        );
        fail('Should have thrown exception');
      } catch (e) {
        expect(failAttempt, equals(3)); // Exactly max attempts
      }
    });

    /// プロパティ: 指数バックオフは遅延時間を増加させる
    test('exponential backoff increases delay between retries', () async {
      // Arrange
      final delays = <Duration>[];
      DateTime? lastCallTime;
      int callCount = 0;

      Future<String> operation() async {
        final now = DateTime.now();
        if (lastCallTime != null) {
          delays.add(now.difference(lastCallTime!));
        }
        lastCallTime = now;
        callCount++;
        throw Exception('Error');
      }

      // Act
      try {
        await RetryUtils.retry(
          operation,
          config: const RetryConfig(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 50),
            backoffMultiplier: 2.0,
          ),
        );
      } catch (e) {
        // Expected to fail
      }

      // Assert - each delay should be longer than the previous
      expect(delays.length, equals(2)); // 2 retries = 2 delays
      if (delays.length >= 2) {
        expect(
          delays[1].inMilliseconds,
          greaterThan(delays[0].inMilliseconds),
        );
      }
    });
  });
}
