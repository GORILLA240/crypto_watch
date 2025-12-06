import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/widgets/optimized_text_widget.dart';

/// Property-Based Tests for OptimizedTextWidget
/// 
/// Feature: smartwatch-ui-optimization
/// Property 1: テキストオーバーフロー防止
/// Validates: Requirements 1.1, 1.5
/// 
/// Property 2: 長いテキストの省略
/// Validates: Requirements 1.2

void main() {
  group('OptimizedTextWidget Property Tests', () {
    /// Property 1: テキストオーバーフロー防止
    /// 任意のテキスト要素と画面サイズに対して、テキストがビューポートの境界を超えてはならない
    /// Validates: Requirements 1.1, 1.5
    testWidgets('Property 1: text never overflows viewport boundaries',
        (WidgetTester tester) async {
      final random = Random(42); // 再現性のためのシード値
      
      // 100回のランダムなテストケースを実行
      for (int i = 0; i < 100; i++) {
        // ランダムなテキスト長を生成（10〜200文字）
        final textLength = 10 + random.nextInt(190);
        final text = _generateRandomText(textLength, random);
        
        // ランダムな画面幅を生成（100〜400ピクセル）
        final screenWidth = 100.0 + random.nextDouble() * 300.0;
        
        // ランダムなフォントサイズを生成（12〜24ピクセル）
        final fontSize = 12.0 + random.nextDouble() * 12.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: screenWidth,
                child: OptimizedTextWidget(
                  text,
                  style: TextStyle(fontSize: fontSize),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
        
        // テキストウィジェットを取得
        final textFinder = find.byType(Text);
        expect(textFinder, findsOneWidget);
        
        // テキストウィジェットのサイズを取得
        final textWidget = tester.widget<Text>(textFinder);
        final renderBox = tester.renderObject(textFinder) as RenderBox;
        final textWidth = renderBox.size.width;
        
        // テキストの幅が画面幅を超えないことを検証
        expect(
          textWidth,
          lessThanOrEqualTo(screenWidth),
          reason: 'Text width ($textWidth) should not exceed screen width ($screenWidth) '
              'for text length $textLength and font size $fontSize',
        );
        
        // オーバーフローが設定されていることを確認
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      }
    });
    
    /// Property 2: 長いテキストの省略
    /// 任意のコンテナ幅を超えるテキストに対して、省略記号（...）が適用され、
    /// テキストがコンテナ内に収まる
    /// Validates: Requirements 1.2
    testWidgets('Property 2: long text is truncated with ellipsis',
        (WidgetTester tester) async {
      final random = Random(123); // 再現性のためのシード値
      
      // 100回のランダムなテストケースを実行
      for (int i = 0; i < 100; i++) {
        // 長いテキストを生成（50〜300文字）
        final textLength = 50 + random.nextInt(250);
        final text = _generateRandomText(textLength, random);
        
        // 小さなコンテナ幅を生成（80〜200ピクセル）
        final containerWidth = 80.0 + random.nextDouble() * 120.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: containerWidth,
                child: OptimizedTextWidget(
                  text,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
        
        // テキストウィジェットを取得
        final textFinder = find.byType(Text);
        expect(textFinder, findsOneWidget);
        
        final textWidget = tester.widget<Text>(textFinder);
        final renderBox = tester.renderObject(textFinder) as RenderBox;
        
        // テキストがコンテナ内に収まっていることを確認
        expect(
          renderBox.size.width,
          lessThanOrEqualTo(containerWidth),
          reason: 'Text should fit within container width ($containerWidth) '
              'for text length $textLength',
        );
        
        // オーバーフロー設定が正しいことを確認
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
        expect(textWidget.maxLines, equals(1));
      }
    });
    
    /// 追加テスト: autoScale機能のテスト
    testWidgets('autoScale adjusts font size to fit within constraints',
        (WidgetTester tester) async {
      const longText = 'This is a very long text that should be scaled down to fit';
      const smallWidth = 100.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: smallWidth,
              child: OptimizedTextWidget(
                longText,
                style: const TextStyle(fontSize: 24),
                autoScale: true,
                minFontSize: 12.0,
                maxLines: 1,
              ),
            ),
          ),
        ),
      );
      
      // テキストウィジェットを取得
      final textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);
      
      final renderBox = tester.renderObject(textFinder) as RenderBox;
      
      // テキストが指定された幅内に収まっていることを確認
      expect(
        renderBox.size.width,
        lessThanOrEqualTo(smallWidth),
        reason: 'Text with autoScale should fit within the specified width',
      );
    });
    
    /// エッジケース: 空のテキスト
    testWidgets('handles empty text without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: OptimizedTextWidget(
                '',
                style: TextStyle(fontSize: 16),
                maxLines: 1,
              ),
            ),
          ),
        ),
      );
      
      final textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);
    });
    
    /// エッジケース: 非常に小さな画面
    testWidgets('handles very small screen widths', (WidgetTester tester) async {
      const text = 'Test';
      const verySmallWidth = 50.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: verySmallWidth,
              child: OptimizedTextWidget(
                text,
                style: TextStyle(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
      
      final textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);
      
      final renderBox = tester.renderObject(textFinder) as RenderBox;
      expect(renderBox.size.width, lessThanOrEqualTo(verySmallWidth));
    });
    
    /// エッジケース: 複数行テキスト
    testWidgets('handles multi-line text with maxLines', (WidgetTester tester) async {
      const longText = 'This is a very long text that should wrap to multiple lines '
          'when the maxLines property is set to a value greater than 1';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: OptimizedTextWidget(
                longText,
                style: TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
      
      final textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);
      
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.maxLines, equals(3));
    });
  });
}

/// ランダムなテキストを生成するヘルパー関数
String _generateRandomText(int length, Random random) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
}
