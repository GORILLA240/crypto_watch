import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/utils/display_density.dart';
import 'dart:math';

/// **Feature: price-list-improvements, Property 2: 表示密度の制約**
/// **Validates: 要件 2.3, 2.4, 2.5**
/// 
/// 各表示密度について、画面サイズとアイテム高さから計算される銘柄数が指定範囲内であることを確認
void main() {
  group('DisplayDensity Tests', () {
    test('DisplayDensity.fromString should parse valid values', () {
      expect(DisplayDensity.fromString('standard'), DisplayDensity.standard);
      expect(DisplayDensity.fromString('compact'), DisplayDensity.compact);
      expect(DisplayDensity.fromString('maximum'), DisplayDensity.maximum);
      expect(DisplayDensity.fromString('STANDARD'), DisplayDensity.standard);
      expect(DisplayDensity.fromString('invalid'), DisplayDensity.standard);
    });

    test('DisplayDensity.toStringValue should return correct string', () {
      expect(DisplayDensity.standard.toStringValue(), 'standard');
      expect(DisplayDensity.compact.toStringValue(), 'compact');
      expect(DisplayDensity.maximum.toStringValue(), 'maximum');
    });
  });

  group('DisplayDensityConfig Tests', () {
    test('DisplayDensityConfig should support equality', () {
      const config1 = DisplayDensityConfig(
        density: DisplayDensity.standard,
        itemHeight: 80.0,
        iconSize: 40.0,
        fontSize: 18.0,
        padding: 16.0,
      );

      const config2 = DisplayDensityConfig(
        density: DisplayDensity.standard,
        itemHeight: 80.0,
        iconSize: 40.0,
        fontSize: 18.0,
        padding: 16.0,
      );

      const config3 = DisplayDensityConfig(
        density: DisplayDensity.compact,
        itemHeight: 60.0,
        iconSize: 32.0,
        fontSize: 16.0,
        padding: 12.0,
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });
  });

  group('DisplayDensityHelper Tests', () {
    test('getConfig should return correct configuration for standard', () {
      final config = DisplayDensityHelper.getConfig(DisplayDensity.standard);
      
      expect(config.density, DisplayDensity.standard);
      expect(config.itemHeight, 80.0);
      expect(config.iconSize, 40.0);
      expect(config.fontSize, 18.0);
      expect(config.padding, 16.0);
    });

    test('getConfig should return correct configuration for compact', () {
      final config = DisplayDensityHelper.getConfig(DisplayDensity.compact);
      
      expect(config.density, DisplayDensity.compact);
      expect(config.itemHeight, 60.0);
      expect(config.iconSize, 32.0);
      expect(config.fontSize, 16.0);
      expect(config.padding, 12.0);
    });

    test('getConfig should return correct configuration for maximum', () {
      final config = DisplayDensityHelper.getConfig(DisplayDensity.maximum);
      
      expect(config.density, DisplayDensity.maximum);
      expect(config.itemHeight, 52.0); // 最小タップ領域を確保するため52px
      expect(config.iconSize, 32.0);
      expect(config.fontSize, 14.0);
      expect(config.padding, 12.0); // 最小パディング要件（12px以上）
    });

    test('getMinItems should return correct minimum items', () {
      expect(DisplayDensityHelper.getMinItems(DisplayDensity.standard), 3);
      expect(DisplayDensityHelper.getMinItems(DisplayDensity.compact), 6);
      expect(DisplayDensityHelper.getMinItems(DisplayDensity.maximum), 9);
    });

    test('getMaxItems should return correct maximum items', () {
      expect(DisplayDensityHelper.getMaxItems(DisplayDensity.standard), 5);
      expect(DisplayDensityHelper.getMaxItems(DisplayDensity.compact), 8);
      expect(DisplayDensityHelper.getMaxItems(DisplayDensity.maximum), 12);
    });

    test('calculateVisibleItems should calculate correct item count', () {
      // Standard density with 600px screen height
      // Available height = 600 - 56 (app bar) = 544
      // Items = 544 / 80 = 6.8 -> floor = 6
      final standardItems = DisplayDensityHelper.calculateVisibleItems(
        600.0,
        DisplayDensity.standard,
      );
      expect(standardItems, 6);

      // Compact density with 600px screen height
      // Available height = 544
      // Items = 544 / 60 = 9.06 -> floor = 9
      final compactItems = DisplayDensityHelper.calculateVisibleItems(
        600.0,
        DisplayDensity.compact,
      );
      expect(compactItems, 9);

      // Maximum density with 600px screen height
      // Available height = 544
      // Items = 544 / 52 = 10.46 -> floor = 10
      final maximumItems = DisplayDensityHelper.calculateVisibleItems(
        600.0,
        DisplayDensity.maximum,
      );
      expect(maximumItems, 10);
    });
  });

  group('Property 2: Display Density Constraints', () {
    /// **Feature: price-list-improvements, Property 2: 表示密度の制約**
    /// **Validates: 要件 2.3, 2.4, 2.5**
    /// 
    /// プロパティ: すべての表示密度について、画面サイズとアイテム高さから計算される
    /// 銘柄数が指定範囲内である必要があります
    test('standard density should display 3-5 items on typical screens', () {
      // Test with 100 different screen heights
      final random = Random(42); // Fixed seed for reproducibility
      
      for (int i = 0; i < 100; i++) {
        // Generate screen heights that would typically show 3-5 items
        // For standard (80px items): 
        // Min: 3 items = 3 * 80 + 56 = 296px
        // Max: 5 items = 5 * 80 + 56 = 456px
        // We'll test a range around this
        final screenHeight = 296.0 + random.nextDouble() * 160.0; // 296-456px
        
        final visibleItems = DisplayDensityHelper.calculateVisibleItems(
          screenHeight,
          DisplayDensity.standard,
        );
        
        final minItems = DisplayDensityHelper.getMinItems(DisplayDensity.standard);
        final maxItems = DisplayDensityHelper.getMaxItems(DisplayDensity.standard);
        
        expect(
          visibleItems,
          greaterThanOrEqualTo(minItems),
          reason: 'Standard density should show at least $minItems items '
              'for screen height $screenHeight, but got $visibleItems',
        );
        
        expect(
          visibleItems,
          lessThanOrEqualTo(maxItems),
          reason: 'Standard density should show at most $maxItems items '
              'for screen height $screenHeight, but got $visibleItems',
        );
      }
    });

    test('compact density should display 6-8 items on typical screens', () {
      final random = Random(42);
      
      for (int i = 0; i < 100; i++) {
        // For compact (60px items):
        // Min: 6 items = 6 * 60 + 56 = 416px
        // Max: 8 items = 8 * 60 + 56 = 536px
        final screenHeight = 416.0 + random.nextDouble() * 120.0; // 416-536px
        
        final visibleItems = DisplayDensityHelper.calculateVisibleItems(
          screenHeight,
          DisplayDensity.compact,
        );
        
        final minItems = DisplayDensityHelper.getMinItems(DisplayDensity.compact);
        final maxItems = DisplayDensityHelper.getMaxItems(DisplayDensity.compact);
        
        expect(
          visibleItems,
          greaterThanOrEqualTo(minItems),
          reason: 'Compact density should show at least $minItems items '
              'for screen height $screenHeight, but got $visibleItems',
        );
        
        expect(
          visibleItems,
          lessThanOrEqualTo(maxItems),
          reason: 'Compact density should show at most $maxItems items '
              'for screen height $screenHeight, but got $visibleItems',
        );
      }
    });

    test('maximum density should display 9-12 items on typical screens', () {
      final random = Random(42);
      
      for (int i = 0; i < 100; i++) {
        // For maximum (48px items):
        // Min: 9 items = 9 * 52 + 56 = 524px
        // Max: 12 items = 12 * 52 + 56 = 680px
        final screenHeight = 524.0 + random.nextDouble() * 156.0; // 524-680px
        
        final visibleItems = DisplayDensityHelper.calculateVisibleItems(
          screenHeight,
          DisplayDensity.maximum,
        );
        
        final minItems = DisplayDensityHelper.getMinItems(DisplayDensity.maximum);
        final maxItems = DisplayDensityHelper.getMaxItems(DisplayDensity.maximum);
        
        expect(
          visibleItems,
          greaterThanOrEqualTo(minItems),
          reason: 'Maximum density should show at least $minItems items '
              'for screen height $screenHeight, but got $visibleItems',
        );
        
        expect(
          visibleItems,
          lessThanOrEqualTo(maxItems),
          reason: 'Maximum density should show at most $maxItems items '
              'for screen height $screenHeight, but got $visibleItems',
        );
      }
    });

    test('all densities maintain constraints across wide range of screen sizes', () {
      // Test all three densities with various screen sizes
      final densities = [
        DisplayDensity.standard,
        DisplayDensity.compact,
        DisplayDensity.maximum,
      ];
      
      final random = Random(42);
      
      for (final density in densities) {
        final minItems = DisplayDensityHelper.getMinItems(density);
        final maxItems = DisplayDensityHelper.getMaxItems(density);
        final config = DisplayDensityHelper.getConfig(density);
        
        // Generate 100 random screen heights for each density
        for (int i = 0; i < 100; i++) {
          // Calculate appropriate screen height range for this density
          final minScreenHeight = minItems * config.itemHeight + 56.0;
          final maxScreenHeight = maxItems * config.itemHeight + 56.0;
          final screenHeight = minScreenHeight + 
              random.nextDouble() * (maxScreenHeight - minScreenHeight);
          
          final visibleItems = DisplayDensityHelper.calculateVisibleItems(
            screenHeight,
            density,
          );
          
          expect(
            visibleItems,
            inInclusiveRange(minItems, maxItems),
            reason: '${density.name} density should show $minItems-$maxItems items '
                'for screen height $screenHeight, but got $visibleItems',
          );
        }
      }
    });

    test('font size should never be below minimum (12sp)', () {
      // 要件 5.5: すべての表示密度でフォントサイズが12sp以上であることを確認
      final densities = [
        DisplayDensity.standard,
        DisplayDensity.compact,
        DisplayDensity.maximum,
      ];
      
      for (final density in densities) {
        final config = DisplayDensityHelper.getConfig(density);
        
        expect(
          config.fontSize,
          greaterThanOrEqualTo(12.0),
          reason: '${density.name} density font size (${config.fontSize}) '
              'should be at least 12sp',
        );
      }
    });
  });
}
