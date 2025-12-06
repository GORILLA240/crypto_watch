import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto_watch/core/services/font_size_manager.dart';

/// **Feature: smartwatch-ui-optimization, Property 6: 最小フォントサイズ**
/// 
/// Property: For any base font size and any font size option,
/// the scaled font size must be at least 12sp
/// 
/// **Validates: Requirements 7.1, 19.5**
void main() {
  late FontSizeManager fontSizeManager;
  final random = Random();

  setUp(() {
    fontSizeManager = FontSizeManager();
    SharedPreferences.setMockInitialValues({});
  });

  group('Property 6: 最小フォントサイズ', () {
    test('任意のベースサイズとオプションで、スケール後のフォントサイズは最小12sp', () {
      // Property-based test with 100 iterations
      for (int i = 0; i < 100; i++) {
        // Generate random base font size between 1.0 and 50.0
        final baseSize = 1.0 + random.nextDouble() * 49.0;
        
        // Test with all font size options
        for (final option in FontSizeOption.values) {
          // Act
          final scaledSize = fontSizeManager.getScaledFontSize(
            baseSize,
            option,
          );
          
          // Assert: Scaled font size must be at least 12sp
          expect(
            scaledSize,
            greaterThanOrEqualTo(12.0),
            reason: 'Base size: $baseSize, Option: $option, '
                'Scaled: $scaledSize should be >= 12.0',
          );
        }
      }
    });

    test('任意の小さいベースサイズで、最小フォントサイズが保証される', () {
      // Test specifically with small base sizes that would scale below minimum
      for (int i = 0; i < 100; i++) {
        // Generate random small base font size between 0.1 and 13.0
        final baseSize = 0.1 + random.nextDouble() * 12.9;
        
        // Test with small option (0.9 scale) which is most likely to go below minimum
        final scaledSize = fontSizeManager.getScaledFontSize(
          baseSize,
          FontSizeOption.small,
        );
        
        // Assert: Even with small base and small scale, must be at least 12sp
        expect(
          scaledSize,
          greaterThanOrEqualTo(12.0),
          reason: 'Base size: $baseSize with small option (0.9x) '
              'should be clamped to 12.0, got: $scaledSize',
        );
      }
    });

    test('任意の大きいベースサイズで、最小フォントサイズ制約が適用されない', () {
      // Test with large base sizes that should never hit the minimum
      for (int i = 0; i < 100; i++) {
        // Generate random large base font size between 20.0 and 100.0
        final baseSize = 20.0 + random.nextDouble() * 80.0;
        
        for (final option in FontSizeOption.values) {
          final scaledSize = fontSizeManager.getScaledFontSize(
            baseSize,
            option,
          );
          
          final expectedSize = baseSize * FontSizeManager.scales[option]!;
          
          // Assert: Large base sizes should scale normally without clamping
          expect(
            scaledSize,
            expectedSize,
            reason: 'Base size: $baseSize, Option: $option, '
                'Expected: $expectedSize, Got: $scaledSize',
          );
        }
      }
    });

    test('clampFontSize は任意の入力で最小12spを保証', () {
      // Test clampFontSize directly with random values
      for (int i = 0; i < 100; i++) {
        // Generate random font size between -10.0 and 100.0
        final fontSize = -10.0 + random.nextDouble() * 110.0;
        
        // Act
        final clampedSize = fontSizeManager.clampFontSize(fontSize);
        
        // Assert: Clamped size must be at least 12.0
        expect(
          clampedSize,
          greaterThanOrEqualTo(12.0),
          reason: 'Input: $fontSize should be clamped to at least 12.0, '
              'got: $clampedSize',
        );
        
        // Assert: If input was already >= 12, it should be unchanged
        if (fontSize >= 12.0) {
          expect(
            clampedSize,
            fontSize,
            reason: 'Input: $fontSize was already >= 12.0, '
                'should not be modified',
          );
        }
      }
    });

    test('境界値テスト: 12sp付近のベースサイズ', () {
      // Test boundary cases around the minimum font size
      final boundarySizes = [
        11.0, 11.5, 11.9, 12.0, 12.1, 12.5, 13.0, 13.5,
      ];
      
      for (final baseSize in boundarySizes) {
        for (final option in FontSizeOption.values) {
          final scaledSize = fontSizeManager.getScaledFontSize(
            baseSize,
            option,
          );
          
          // Assert: All scaled sizes must be at least 12sp
          expect(
            scaledSize,
            greaterThanOrEqualTo(12.0),
            reason: 'Boundary base size: $baseSize, Option: $option, '
                'Scaled: $scaledSize should be >= 12.0',
          );
        }
      }
    });

    test('スケール係数の正確性検証', () {
      // Verify that scale factors are applied correctly
      const testBaseSize = 20.0;
      
      final smallScaled = fontSizeManager.getScaledFontSize(
        testBaseSize,
        FontSizeOption.small,
      );
      expect(smallScaled, 18.0); // 20 * 0.9
      
      final normalScaled = fontSizeManager.getScaledFontSize(
        testBaseSize,
        FontSizeOption.normal,
      );
      expect(normalScaled, 20.0); // 20 * 1.0
      
      final largeScaled = fontSizeManager.getScaledFontSize(
        testBaseSize,
        FontSizeOption.large,
      );
      expect(largeScaled, 22.0); // 20 * 1.1
      
      final extraLargeScaled = fontSizeManager.getScaledFontSize(
        testBaseSize,
        FontSizeOption.extraLarge,
      );
      expect(extraLargeScaled, 24.0); // 20 * 1.2
    });
  });
}
