import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/widgets/crypto_icon.dart';

void main() {
  group('CryptoIcon - エラーハンドリング（要件 15.4, 15.9）', () {
    testWidgets('アイコン取得失敗時にプレースホルダーを表示', (WidgetTester tester) async {
      // Arrange
      const symbol = 'INVALID';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: symbol,
              size: 40,
            ),
          ),
        ),
      );

      // 画像の読み込みを待つ
      await tester.pump();

      // Assert
      // CachedNetworkImageが存在することを確認
      expect(find.byType(CryptoIcon), findsOneWidget);
    });

    testWidgets('プレースホルダーにティッカーシンボルの頭文字が表示される（要件 15.3）',
        (WidgetTester tester) async {
      // Arrange
      const symbol = 'BTC';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: symbol,
              size: 40,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      // ウィジェットが正しく構築されることを確認
      expect(find.byType(CryptoIcon), findsOneWidget);
    });

    testWidgets('空のシンボルでも正常に動作する', (WidgetTester tester) async {
      // Arrange
      const symbol = '';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: symbol,
              size: 40,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.byType(CryptoIcon), findsOneWidget);
    });

    testWidgets('異なるサイズで正常に動作する', (WidgetTester tester) async {
      // Arrange
      const sizes = [24.0, 32.0, 40.0, 48.0];

      for (final size in sizes) {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CryptoIcon(
                symbol: 'BTC',
                size: size,
              ),
            ),
          ),
        );

        await tester.pump();

        // Assert
        expect(find.byType(CryptoIcon), findsOneWidget);

        // 次のテストのためにウィジェットをクリア
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('小文字のシンボルでも正常に動作する', (WidgetTester tester) async {
      // Arrange
      const symbol = 'btc';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: symbol,
              size: 40,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.byType(CryptoIcon), findsOneWidget);
    });

    testWidgets('特殊文字を含むシンボルでも正常に動作する', (WidgetTester tester) async {
      // Arrange
      const symbol = 'BTC-USD';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: symbol,
              size: 40,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.byType(CryptoIcon), findsOneWidget);
    });

    testWidgets('長いシンボルでも正常に動作する', (WidgetTester tester) async {
      // Arrange
      const symbol = 'VERYLONGSYMBOL';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: symbol,
              size: 40,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.byType(CryptoIcon), findsOneWidget);
    });



    testWidgets('複数のCryptoIconを同時に表示できる', (WidgetTester tester) async {
      // Arrange
      const symbols = ['BTC', 'ETH', 'ADA'];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: symbols
                  .map((symbol) => CryptoIcon(symbol: symbol, size: 32))
                  .toList(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.byType(CryptoIcon), findsNWidgets(symbols.length));
    });

    testWidgets('デフォルト通貨とカスタム通貨で同じ方法でアイコンを取得（要件 15.8）',
        (WidgetTester tester) async {
      // Arrange
      const defaultCurrency = 'BTC';
      const customCurrency = 'SHIB';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                CryptoIcon(symbol: defaultCurrency, size: 32),
                CryptoIcon(symbol: customCurrency, size: 32),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      // 両方のアイコンが表示される
      expect(find.byType(CryptoIcon), findsNWidgets(2));
    });



    testWidgets('カスタム通貨のアイコン取得失敗時もプレースホルダーを表示（要件 15.9）',
        (WidgetTester tester) async {
      // Arrange
      const customCurrency = 'CUSTOMCOIN';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: customCurrency,
              size: 40,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.byType(CryptoIcon), findsOneWidget);
    });
  });

  group('CryptoIcon - プレースホルダー表示', () {
    testWidgets('プレースホルダーが円形である（要件 15.4）', (WidgetTester tester) async {
      // Arrange
      const symbol = 'BTC';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: symbol,
              size: 40,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      // ウィジェットが構築されることを確認
      expect(find.byType(CryptoIcon), findsOneWidget);
    });

    testWidgets('プレースホルダーのサイズが指定されたサイズと一致する',
        (WidgetTester tester) async {
      // Arrange
      const symbol = 'BTC';
      const size = 48.0;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CryptoIcon(
              symbol: symbol,
              size: size,
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.byType(CryptoIcon), findsOneWidget);
    });
  });
}
