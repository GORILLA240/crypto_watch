import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/utils/performance_utils.dart';

/// プロパティ9: UI応答性の維持
/// 検証: 要件5.5, 10.1
/// 
/// パフォーマンス最適化が正しく機能することを検証
void main() {
  group('Performance Utils Tests', () {
    test('generateKey should create unique keys for different ids', () {
      // Arrange
      const prefix = 'test';
      const id1 = 'item1';
      const id2 = 'item2';

      // Act
      final key1 = PerformanceUtils.generateKey(prefix, id1);
      final key2 = PerformanceUtils.generateKey(prefix, id2);

      // Assert
      expect(key1, isNot(equals(key2)));
      expect(key1.toString(), contains(prefix));
      expect(key1.toString(), contains(id1));
    });

    test('listItemKey should create consistent keys for same id', () {
      // Arrange
      const id = 'item123';

      // Act
      final key1 = PerformanceUtils.listItemKey(id);
      final key2 = PerformanceUtils.listItemKey(id);

      // Assert
      expect(key1, equals(key2));
      expect(key1.toString(), contains(id));
    });

    test('debounce should limit rapid calls', () async {
      // Arrange
      int callCount = 0;
      final debouncedFunction = PerformanceUtils.debounce(
        () => callCount++,
        delay: const Duration(milliseconds: 100),
      );

      // Act
      debouncedFunction();
      debouncedFunction();
      debouncedFunction();
      await Future.delayed(const Duration(milliseconds: 50));
      debouncedFunction();

      // Assert - 最初の呼び出しのみ実行される
      expect(callCount, equals(1));

      // Wait for debounce period
      await Future.delayed(const Duration(milliseconds: 150));
      debouncedFunction();
      expect(callCount, equals(2));
    });

    test('throttle should limit call frequency', () async {
      // Arrange
      int callCount = 0;
      final throttledFunction = PerformanceUtils.throttle(
        () => callCount++,
        duration: const Duration(milliseconds: 100),
      );

      // Act
      throttledFunction();
      throttledFunction();
      throttledFunction();

      // Assert - 最初の呼び出しのみ実行される
      expect(callCount, equals(1));

      // Wait for throttle period
      await Future.delayed(const Duration(milliseconds: 150));
      throttledFunction();
      expect(callCount, equals(2));
    });
  });

  group('Image Cache Config Tests', () {
    testWidgets('optimizeImageCache should not throw', (tester) async {
      // Act & Assert
      expect(() => ImageCacheConfig.optimizeImageCache(), returnsNormally);
    });

    testWidgets('clearImageCache should not throw', (tester) async {
      // Act & Assert
      expect(() => ImageCacheConfig.clearImageCache(), returnsNormally);
    });
  });

  group('Property 9: UI Responsiveness', () {
    /// プロパティ: デバウンスとスロットルは常に呼び出し回数を制限する
    test('debounce and throttle always reduce call frequency', () async {
      // Arrange
      const rapidCallCount = 10;
      const delay = Duration(milliseconds: 50);

      // Test debounce
      int debounceCallCount = 0;
      final debouncedFn = PerformanceUtils.debounce(
        () => debounceCallCount++,
        delay: delay,
      );

      // Act - rapid calls
      for (int i = 0; i < rapidCallCount; i++) {
        debouncedFn();
      }

      // Assert - should be called only once initially
      expect(debounceCallCount, lessThan(rapidCallCount));

      // Test throttle
      int throttleCallCount = 0;
      final throttledFn = PerformanceUtils.throttle(
        () => throttleCallCount++,
        duration: delay,
      );

      // Act - rapid calls
      for (int i = 0; i < rapidCallCount; i++) {
        throttledFn();
        await Future.delayed(const Duration(milliseconds: 5));
      }

      // Assert - should be called less than rapid call count
      expect(throttleCallCount, lessThan(rapidCallCount));
    });

    /// プロパティ: キー生成は一意性を保証する
    test('key generation maintains uniqueness', () {
      // Arrange
      const itemCount = 100;
      final keys = <String>{};

      // Act
      for (int i = 0; i < itemCount; i++) {
        final key = PerformanceUtils.listItemKey('item_$i');
        keys.add(key.toString());
      }

      // Assert - all keys should be unique
      expect(keys.length, equals(itemCount));
    });
  });
}
