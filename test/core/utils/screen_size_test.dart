import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/utils/screen_size.dart';

void main() {
  group('ScreenSize', () {
    group('fromConstraints', () {
      test('幅が200未満の場合、smallカテゴリーと判定される', () {
        final constraints = const BoxConstraints(
          maxWidth: 150,
          maxHeight: 150,
        );
        final screenSize = ScreenSize.fromConstraints(constraints);
        
        expect(screenSize.category, ScreenSizeCategory.small);
        expect(screenSize.width, 150);
        expect(screenSize.height, 150);
      });
      
      test('幅が200以上300未満の場合、mediumカテゴリーと判定される', () {
        final constraints = const BoxConstraints(
          maxWidth: 250,
          maxHeight: 250,
        );
        final screenSize = ScreenSize.fromConstraints(constraints);
        
        expect(screenSize.category, ScreenSizeCategory.medium);
        expect(screenSize.width, 250);
        expect(screenSize.height, 250);
      });
      
      test('幅が300以上の場合、largeカテゴリーと判定される', () {
        final constraints = const BoxConstraints(
          maxWidth: 350,
          maxHeight: 350,
        );
        final screenSize = ScreenSize.fromConstraints(constraints);
        
        expect(screenSize.category, ScreenSizeCategory.large);
        expect(screenSize.width, 350);
        expect(screenSize.height, 350);
      });
      
      test('円形画面フラグが正しく設定される', () {
        final constraints = const BoxConstraints(
          maxWidth: 200,
          maxHeight: 200,
        );
        final screenSize = ScreenSize.fromConstraints(
          constraints,
          isCircular: true,
        );
        
        expect(screenSize.isCircular, true);
      });
      
      test('正方形画面の場合、安全な余白が8ピクセル', () {
        final constraints = const BoxConstraints(
          maxWidth: 200,
          maxHeight: 200,
        );
        final screenSize = ScreenSize.fromConstraints(constraints);
        
        expect(screenSize.safeInsets.left, 8.0);
        expect(screenSize.safeInsets.right, 8.0);
      });
      
      test('円形画面の場合、安全な余白が大きめに設定される', () {
        final constraints = const BoxConstraints(
          maxWidth: 200,
          maxHeight: 200,
        );
        final screenSize = ScreenSize.fromConstraints(
          constraints,
          isCircular: true,
        );
        
        // 円形画面の場合、インセットは30ピクセル
        expect(screenSize.safeInsets.left, 30.0);
        expect(screenSize.safeInsets.right, 30.0);
      });
    });
    
    group('推奨値の取得', () {
      test('smallカテゴリーの場合、適切なフォントサイズを返す', () {
        final constraints = const BoxConstraints(
          maxWidth: 150,
          maxHeight: 150,
        );
        final screenSize = ScreenSize.fromConstraints(constraints);
        
        expect(screenSize.primaryFontSize, 14.0);
        expect(screenSize.secondaryFontSize, 12.0);
      });
      
      test('mediumカテゴリーの場合、適切なフォントサイズを返す', () {
        final constraints = const BoxConstraints(
          maxWidth: 250,
          maxHeight: 250,
        );
        final screenSize = ScreenSize.fromConstraints(constraints);
        
        expect(screenSize.primaryFontSize, 16.0);
        expect(screenSize.secondaryFontSize, 14.0);
      });
      
      test('largeカテゴリーの場合、適切なフォントサイズを返す', () {
        final constraints = const BoxConstraints(
          maxWidth: 350,
          maxHeight: 350,
        );
        final screenSize = ScreenSize.fromConstraints(constraints);
        
        expect(screenSize.primaryFontSize, 18.0);
        expect(screenSize.secondaryFontSize, 16.0);
      });
      
      test('smallカテゴリーの場合、適切なアイコンサイズを返す', () {
        final constraints = const BoxConstraints(
          maxWidth: 150,
          maxHeight: 150,
        );
        final screenSize = ScreenSize.fromConstraints(constraints);
        
        expect(screenSize.iconSize, 28.0);
      });
      
      test('mediumカテゴリーの場合、適切なアイコンサイズを返す', () {
        final constraints = const BoxConstraints(
          maxWidth: 250,
          maxHeight: 250,
        );
        final screenSize = ScreenSize.fromConstraints(constraints);
        
        expect(screenSize.iconSize, 32.0);
      });
      
      test('largeカテゴリーの場合、適切なアイコンサイズを返す', () {
        final constraints = const BoxConstraints(
          maxWidth: 350,
          maxHeight: 350,
        );
        final screenSize = ScreenSize.fromConstraints(constraints);
        
        expect(screenSize.iconSize, 40.0);
      });
      
      test('デフォルトパディングが画面サイズに応じて変化する', () {
        final smallConstraints = const BoxConstraints(
          maxWidth: 150,
          maxHeight: 150,
        );
        final smallScreenSize = ScreenSize.fromConstraints(smallConstraints);
        
        expect(smallScreenSize.defaultPadding.horizontal, 16.0); // 8 * 2
        expect(smallScreenSize.defaultPadding.vertical, 12.0); // 6 * 2
        
        final largeConstraints = const BoxConstraints(
          maxWidth: 350,
          maxHeight: 350,
        );
        final largeScreenSize = ScreenSize.fromConstraints(largeConstraints);
        
        expect(largeScreenSize.defaultPadding.horizontal, 32.0); // 16 * 2
        expect(largeScreenSize.defaultPadding.vertical, 20.0); // 10 * 2
      });
      
      test('リストアイテムの高さが画面サイズに応じて変化する', () {
        final smallConstraints = const BoxConstraints(
          maxWidth: 150,
          maxHeight: 150,
        );
        final smallScreenSize = ScreenSize.fromConstraints(smallConstraints);
        
        expect(smallScreenSize.listItemHeight, 48.0);
        
        final mediumConstraints = const BoxConstraints(
          maxWidth: 250,
          maxHeight: 250,
        );
        final mediumScreenSize = ScreenSize.fromConstraints(mediumConstraints);
        
        expect(mediumScreenSize.listItemHeight, 56.0);
        
        final largeConstraints = const BoxConstraints(
          maxWidth: 350,
          maxHeight: 350,
        );
        final largeScreenSize = ScreenSize.fromConstraints(largeConstraints);
        
        expect(largeScreenSize.listItemHeight, 64.0);
      });
      
      test('最小タップ領域サイズは常に44ピクセル', () {
        final smallConstraints = const BoxConstraints(
          maxWidth: 150,
          maxHeight: 150,
        );
        final smallScreenSize = ScreenSize.fromConstraints(smallConstraints);
        
        expect(smallScreenSize.minTapTargetSize, 44.0);
        
        final largeConstraints = const BoxConstraints(
          maxWidth: 350,
          maxHeight: 350,
        );
        final largeScreenSize = ScreenSize.fromConstraints(largeConstraints);
        
        expect(largeScreenSize.minTapTargetSize, 44.0);
      });
    });
  });
}
