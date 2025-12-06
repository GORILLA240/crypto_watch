import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/widgets/responsive_layout_builder.dart';
import 'package:crypto_watch/core/utils/screen_size.dart';

void main() {
  group('ResponsiveLayoutBuilder', () {
    testWidgets('ビルダー関数が正しいScreenSizeで呼び出される', (tester) async {
      ScreenSize? capturedScreenSize;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 250,
              height: 250,
              child: ResponsiveLayoutBuilder(
                builder: (context, screenSize) {
                  capturedScreenSize = screenSize;
                  return Container();
                },
              ),
            ),
          ),
        ),
      );
      
      expect(capturedScreenSize, isNotNull);
      expect(capturedScreenSize!.width, 250);
      expect(capturedScreenSize!.height, 250);
      expect(capturedScreenSize!.category, ScreenSizeCategory.medium);
    });
    
    testWidgets('円形画面フラグが正しく渡される', (tester) async {
      ScreenSize? capturedScreenSize;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: ResponsiveLayoutBuilder(
                isCircular: true,
                builder: (context, screenSize) {
                  capturedScreenSize = screenSize;
                  return Container();
                },
              ),
            ),
          ),
        ),
      );
      
      expect(capturedScreenSize, isNotNull);
      expect(capturedScreenSize!.isCircular, true);
    });
    
    testWidgets('小さい画面サイズでsmallカテゴリーが渡される', (tester) async {
      ScreenSize? capturedScreenSize;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              height: 150,
              child: ResponsiveLayoutBuilder(
                builder: (context, screenSize) {
                  capturedScreenSize = screenSize;
                  return Container();
                },
              ),
            ),
          ),
        ),
      );
      
      expect(capturedScreenSize, isNotNull);
      expect(capturedScreenSize!.category, ScreenSizeCategory.small);
      expect(capturedScreenSize!.primaryFontSize, 14.0);
    });
    
    testWidgets('大きい画面サイズでlargeカテゴリーが渡される', (tester) async {
      ScreenSize? capturedScreenSize;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 350,
              child: ResponsiveLayoutBuilder(
                builder: (context, screenSize) {
                  capturedScreenSize = screenSize;
                  return Container();
                },
              ),
            ),
          ),
        ),
      );
      
      expect(capturedScreenSize, isNotNull);
      expect(capturedScreenSize!.category, ScreenSizeCategory.large);
      expect(capturedScreenSize!.primaryFontSize, 18.0);
    });
    
    testWidgets('ビルダー関数が返すウィジェットが正しく表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 250,
              height: 250,
              child: ResponsiveLayoutBuilder(
                builder: (context, screenSize) {
                  return Text(
                    'Test Text',
                    style: TextStyle(fontSize: screenSize.primaryFontSize),
                  );
                },
              ),
            ),
          ),
        ),
      );
      
      expect(find.text('Test Text'), findsOneWidget);
      
      final textWidget = tester.widget<Text>(find.text('Test Text'));
      expect(textWidget.style?.fontSize, 16.0); // medium category
    });
    
    testWidgets('画面サイズ変更時にビルダーが再実行される', (tester) async {
      int buildCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              height: 150,
              child: ResponsiveLayoutBuilder(
                builder: (context, screenSize) {
                  buildCount++;
                  return Container();
                },
              ),
            ),
          ),
        ),
      );
      
      expect(buildCount, 1);
      
      // 画面サイズを変更
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 350,
              child: ResponsiveLayoutBuilder(
                builder: (context, screenSize) {
                  buildCount++;
                  return Container();
                },
              ),
            ),
          ),
        ),
      );
      
      expect(buildCount, 2);
    });
  });
}
