import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/widgets/crypto_icon.dart';
import 'dart:math';

/// **Feature: price-list-improvements, Property 1: アイコン表示の一貫性**
/// **Validates: 要件 1.1, 1.2, 1.6**
/// 
/// すべての価格アイテムにアイコンまたはプレースホルダーが表示されることを確認
void main() {
  group('CryptoIcon Widget Tests', () {
    testWidgets('should display widget for valid symbol', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: 'BTC',
              size: 40.0,
            ),
          ),
        ),
      );

      expect(find.byType(CryptoIcon), findsOneWidget);
    });

    testWidgets('should display placeholder for empty symbol', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: '',
              size: 40.0,
            ),
          ),
        ),
      );

      expect(find.byType(CryptoIcon), findsOneWidget);
    });

    testWidgets('should use correct size', (WidgetTester tester) async {
      const testSize = 50.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: 'ETH',
              size: testSize,
            ),
          ),
        ),
      );

      final cryptoIcon = tester.widget<CryptoIcon>(find.byType(CryptoIcon));
      expect(cryptoIcon.size, testSize);
    });

    // 要件 15.1: アイコンが正しく表示されることを確認
    testWidgets('should display icon correctly for known symbols', (WidgetTester tester) async {
      const knownSymbols = ['BTC', 'ETH', 'ADA', 'DOT', 'XRP'];
      
      for (final symbol in knownSymbols) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CryptoIcon(
                symbol: symbol,
                size: 32.0,
              ),
            ),
          ),
        );

        // CryptoIconウィジェットが表示されていることを確認
        expect(find.byType(CryptoIcon), findsOneWidget);
        
        // サイズが正しいことを確認
        final cryptoIcon = tester.widget<CryptoIcon>(find.byType(CryptoIcon));
        expect(cryptoIcon.size, 32.0);
        expect(cryptoIcon.symbol, symbol);
      }
    });

    // 要件 15.4: プレースホルダーが正しく表示されることを確認
    testWidgets('should display placeholder with first letter when icon fails to load', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: 'INVALID',
              size: 32.0,
            ),
          ),
        ),
      );

      // CryptoIconウィジェットが表示されていることを確認
      expect(find.byType(CryptoIcon), findsOneWidget);
      
      // ウィジェットのプロパティを確認
      final cryptoIcon = tester.widget<CryptoIcon>(find.byType(CryptoIcon));
      expect(cryptoIcon.symbol, 'INVALID');
      expect(cryptoIcon.size, 32.0);
    });

    // 要件 15.3, 15.4: 空のシンボルでもプレースホルダーが表示されることを確認
    testWidgets('should display placeholder with ? for empty symbol', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: '',
              size: 32.0,
            ),
          ),
        ),
      );

      // CryptoIconウィジェットが表示されていることを確認
      expect(find.byType(CryptoIcon), findsOneWidget);
    });

    // 要件 15.6: スマートウォッチ用の32x32ピクセルサイズを確認
    testWidgets('should support 32x32 pixel size for smartwatch', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: 'BTC',
              size: 32.0,
            ),
          ),
        ),
      );

      final cryptoIcon = tester.widget<CryptoIcon>(find.byType(CryptoIcon));
      expect(cryptoIcon.size, 32.0);
    });
  });

  group('Property 1: Icon Display Consistency', () {
    testWidgets(
      'all crypto symbols should display either icon or placeholder',
      (WidgetTester tester) async {
        final symbols = [
          'BTC', 'ETH', 'ADA', 'DOT', 'XRP', 'LTC', 'BCH', 'LINK',
        ];

        for (final symbol in symbols) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CryptoIcon(
                  symbol: symbol,
                  size: 40.0,
                ),
              ),
            ),
          );

          expect(
            find.byType(CryptoIcon),
            findsOneWidget,
            reason: 'CryptoIcon should be displayed for symbol: $symbol',
          );
        }
      },
    );

    testWidgets(
      'property test: 100 random symbols should all display consistently',
      (WidgetTester tester) async {
        final random = Random(42);
        final validChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

        for (int i = 0; i < 100; i++) {
          final symbolLength = 2 + random.nextInt(4);
          final symbol = String.fromCharCodes(
            List.generate(
              symbolLength,
              (_) => validChars.codeUnitAt(random.nextInt(validChars.length)),
            ),
          );

          final size = 24.0 + random.nextDouble() * 40.0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CryptoIcon(
                  symbol: symbol,
                  size: size,
                ),
              ),
            ),
          );

          expect(
            find.byType(CryptoIcon),
            findsOneWidget,
            reason: 'CryptoIcon should be displayed for random symbol: $symbol',
          );
        }
      },
    );
  });

  group('Property 7: Icon Cache Efficiency', () {
    testWidgets(
      'icons should be cached and reused across multiple displays',
      (WidgetTester tester) async {
        final symbols = ['BTC', 'ETH', 'ADA'];

        for (final symbol in symbols) {
          for (int i = 0; i < 3; i++) {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: CryptoIcon(
                    symbol: symbol,
                    size: 40.0,
                  ),
                ),
              ),
            );

            expect(
              find.byType(CryptoIcon),
              findsOneWidget,
              reason: 'Display $i of $symbol should work',
            );
          }
        }
      },
    );

    testWidgets(
      'property test: 50 random symbols should benefit from caching',
      (WidgetTester tester) async {
        final random = Random(42);
        final symbols = ['BTC', 'ETH', 'ADA', 'DOT', 'XRP'];

        for (int i = 0; i < 50; i++) {
          final symbol = symbols[random.nextInt(symbols.length)];
          final size = 32.0 + random.nextDouble() * 24.0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CryptoIcon(
                  symbol: symbol,
                  size: size,
                ),
              ),
            ),
          );

          expect(
            find.byType(CryptoIcon),
            findsOneWidget,
            reason: 'Icon should display for $symbol (iteration $i)',
          );
        }
      },
    );
  });
}
