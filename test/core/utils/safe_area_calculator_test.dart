import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/utils/safe_area_calculator.dart';

void main() {
  group('SafeAreaCalculator', () {
    group('calculateSafeInsets', () {
      test('正方形画面の場合、最小限の余白（8ピクセル）を返す', () {
        final screenSize = const Size(300, 300);
        final insets = SafeAreaCalculator.calculateSafeInsets(screenSize, false);
        
        expect(insets.left, 8.0);
        expect(insets.right, 8.0);
        expect(insets.top, 8.0);
        expect(insets.bottom, 8.0);
      });
      
      test('円形画面の場合、中央70%を安全領域とする大きめの余白を返す', () {
        final screenSize = const Size(200, 200);
        final insets = SafeAreaCalculator.calculateSafeInsets(screenSize, true);
        
        // 半径100、安全半径70、インセット30
        expect(insets.left, 30.0);
        expect(insets.right, 30.0);
        expect(insets.top, 30.0);
        expect(insets.bottom, 30.0);
      });
      
      test('異なるサイズの円形画面でも正しく計算される', () {
        final screenSize = const Size(400, 400);
        final insets = SafeAreaCalculator.calculateSafeInsets(screenSize, true);
        
        // 半径200、安全半径140、インセット60
        expect(insets.left, 60.0);
        expect(insets.right, 60.0);
        expect(insets.top, 60.0);
        expect(insets.bottom, 60.0);
      });
    });
    
    group('getMaxContentWidth', () {
      test('正方形画面の場合、余白を除いた幅を返す', () {
        final screenSize = const Size(300, 300);
        final maxWidth = SafeAreaCalculator.getMaxContentWidth(screenSize, false);
        
        // 300 - 16 = 284
        expect(maxWidth, 284.0);
      });
      
      test('円形画面の場合、画面幅の70%を返す', () {
        final screenSize = const Size(200, 200);
        final maxWidth = SafeAreaCalculator.getMaxContentWidth(screenSize, true);
        
        // 200 * 0.7 = 140
        expect(maxWidth, 140.0);
      });
      
      test('異なるサイズの円形画面でも正しく計算される', () {
        final screenSize = const Size(400, 400);
        final maxWidth = SafeAreaCalculator.getMaxContentWidth(screenSize, true);
        
        // 400 * 0.7 = 280
        expect(maxWidth, 280.0);
      });
    });
    
    group('isInSafeArea', () {
      test('画面中央の位置は安全領域内', () {
        final screenSize = const Size(200, 200);
        final center = const Offset(100, 100);
        
        expect(SafeAreaCalculator.isInSafeArea(center, screenSize), true);
      });
      
      test('安全半径内の位置は安全領域内', () {
        final screenSize = const Size(200, 200);
        // 中心から50ピクセル離れた位置（安全半径70以内）
        final position = const Offset(150, 100);
        
        expect(SafeAreaCalculator.isInSafeArea(position, screenSize), true);
      });
      
      test('安全半径外の位置は安全領域外', () {
        final screenSize = const Size(200, 200);
        // 画面の角（中心から約141ピクセル離れた位置、安全半径70を超える）
        final corner = const Offset(200, 200);
        
        expect(SafeAreaCalculator.isInSafeArea(corner, screenSize), false);
      });
      
      test('安全半径の境界付近の位置を正しく判定', () {
        final screenSize = const Size(200, 200);
        // 中心から70ピクセル離れた位置（安全半径の境界）
        final boundary = const Offset(170, 100);
        
        expect(SafeAreaCalculator.isInSafeArea(boundary, screenSize), true);
      });
    });
  });
}
