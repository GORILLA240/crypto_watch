import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto_watch/core/services/font_size_manager.dart';

void main() {
  late FontSizeManager fontSizeManager;

  setUp(() {
    fontSizeManager = FontSizeManager();
    // Clear shared preferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('FontSizeManager', () {
    group('getFontSizeOption', () {
      test('returns normal when no preference is saved', () async {
        // Act
        final result = await fontSizeManager.getFontSizeOption();

        // Assert
        expect(result, FontSizeOption.normal);
      });

      test('returns saved font size option', () async {
        // Arrange
        await fontSizeManager.setFontSizeOption(FontSizeOption.large);

        // Act
        final result = await fontSizeManager.getFontSizeOption();

        // Assert
        expect(result, FontSizeOption.large);
      });

      test('returns normal for invalid saved value', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('font_size_option', 'invalid_value');

        // Act
        final result = await fontSizeManager.getFontSizeOption();

        // Assert
        expect(result, FontSizeOption.normal);
      });
    });

    group('setFontSizeOption', () {
      test('saves small font size option', () async {
        // Act
        await fontSizeManager.setFontSizeOption(FontSizeOption.small);

        // Assert
        final result = await fontSizeManager.getFontSizeOption();
        expect(result, FontSizeOption.small);
      });

      test('saves normal font size option', () async {
        // Act
        await fontSizeManager.setFontSizeOption(FontSizeOption.normal);

        // Assert
        final result = await fontSizeManager.getFontSizeOption();
        expect(result, FontSizeOption.normal);
      });

      test('saves large font size option', () async {
        // Act
        await fontSizeManager.setFontSizeOption(FontSizeOption.large);

        // Assert
        final result = await fontSizeManager.getFontSizeOption();
        expect(result, FontSizeOption.large);
      });

      test('saves extraLarge font size option', () async {
        // Act
        await fontSizeManager.setFontSizeOption(FontSizeOption.extraLarge);

        // Assert
        final result = await fontSizeManager.getFontSizeOption();
        expect(result, FontSizeOption.extraLarge);
      });

      test('persists across multiple instances', () async {
        // Arrange
        await fontSizeManager.setFontSizeOption(FontSizeOption.large);

        // Act - Create new instance
        final newManager = FontSizeManager();
        final result = await newManager.getFontSizeOption();

        // Assert
        expect(result, FontSizeOption.large);
      });
    });

    group('getScaledFontSize', () {
      test('scales font size correctly for small option (90%)', () {
        // Arrange
        const baseSize = 16.0;

        // Act
        final result = fontSizeManager.getScaledFontSize(
          baseSize,
          FontSizeOption.small,
        );

        // Assert
        expect(result, 14.4); // 16 * 0.9
      });

      test('scales font size correctly for normal option (100%)', () {
        // Arrange
        const baseSize = 16.0;

        // Act
        final result = fontSizeManager.getScaledFontSize(
          baseSize,
          FontSizeOption.normal,
        );

        // Assert
        expect(result, 16.0); // 16 * 1.0
      });

      test('scales font size correctly for large option (110%)', () {
        // Arrange
        const baseSize = 16.0;

        // Act
        final result = fontSizeManager.getScaledFontSize(
          baseSize,
          FontSizeOption.large,
        );

        // Assert
        expect(result, 17.6); // 16 * 1.1
      });

      test('scales font size correctly for extraLarge option (120%)', () {
        // Arrange
        const baseSize = 16.0;

        // Act
        final result = fontSizeManager.getScaledFontSize(
          baseSize,
          FontSizeOption.extraLarge,
        );

        // Assert
        expect(result, 19.2); // 16 * 1.2
      });

      test('clamps font size to minimum 12sp', () {
        // Arrange
        const baseSize = 10.0;

        // Act
        final result = fontSizeManager.getScaledFontSize(
          baseSize,
          FontSizeOption.small,
        );

        // Assert
        // 10 * 0.9 = 9.0, but should be clamped to 12.0
        expect(result, 12.0);
      });

      test('does not clamp font size above minimum', () {
        // Arrange
        const baseSize = 20.0;

        // Act
        final result = fontSizeManager.getScaledFontSize(
          baseSize,
          FontSizeOption.small,
        );

        // Assert
        // 20 * 0.9 = 18.0, which is above minimum
        expect(result, 18.0);
      });
    });

    group('clampFontSize', () {
      test('returns minimum font size when below threshold', () {
        // Act
        final result = fontSizeManager.clampFontSize(10.0);

        // Assert
        expect(result, 12.0);
      });

      test('returns original size when at minimum threshold', () {
        // Act
        final result = fontSizeManager.clampFontSize(12.0);

        // Assert
        expect(result, 12.0);
      });

      test('returns original size when above minimum threshold', () {
        // Act
        final result = fontSizeManager.clampFontSize(16.0);

        // Assert
        expect(result, 16.0);
      });

      test('handles edge case of very small font size', () {
        // Act
        final result = fontSizeManager.clampFontSize(1.0);

        // Assert
        expect(result, 12.0);
      });

      test('handles edge case of zero font size', () {
        // Act
        final result = fontSizeManager.clampFontSize(0.0);

        // Assert
        expect(result, 12.0);
      });
    });

    group('scale factors', () {
      test('small scale factor is 0.9', () {
        expect(FontSizeManager.scales[FontSizeOption.small], 0.9);
      });

      test('normal scale factor is 1.0', () {
        expect(FontSizeManager.scales[FontSizeOption.normal], 1.0);
      });

      test('large scale factor is 1.1', () {
        expect(FontSizeManager.scales[FontSizeOption.large], 1.1);
      });

      test('extraLarge scale factor is 1.2', () {
        expect(FontSizeManager.scales[FontSizeOption.extraLarge], 1.2);
      });
    });

    group('minimum font size', () {
      test('minimum font size is 12.0', () {
        expect(FontSizeManager.minFontSize, 12.0);
      });
    });
  });
}
