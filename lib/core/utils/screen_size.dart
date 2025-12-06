import 'package:flutter/material.dart';
import 'safe_area_calculator.dart';

/// 画面サイズのカテゴリー
enum ScreenSizeCategory {
  /// 小さい画面（幅 < 200px）
  small,
  
  /// 中サイズ画面（200px <= 幅 < 300px）
  medium,
  
  /// 大きい画面（幅 >= 300px）
  large,
}

/// 画面サイズ情報を表すモデルクラス
/// 
/// 画面サイズに応じた推奨値（フォントサイズ、パディング、アイコンサイズ）を提供します。
class ScreenSize {
  /// 画面の幅
  final double width;
  
  /// 画面の高さ
  final double height;
  
  /// 円形画面かどうか
  final bool isCircular;
  
  /// 画面サイズカテゴリー
  final ScreenSizeCategory category;
  
  /// 安全な余白
  final EdgeInsets safeInsets;
  
  const ScreenSize({
    required this.width,
    required this.height,
    required this.isCircular,
    required this.category,
    required this.safeInsets,
  });
  
  /// BoxConstraintsから ScreenSize を作成
  /// 
  /// [constraints] レイアウト制約
  /// [isCircular] 円形画面かどうか（デフォルト: false）
  /// 
  /// Returns: ScreenSize インスタンス
  factory ScreenSize.fromConstraints(
    BoxConstraints constraints, {
    bool isCircular = false,
  }) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    
    // 画面サイズカテゴリーを判定
    final category = _determineCategory(width);
    
    // 安全な余白を計算
    final safeInsets = SafeAreaCalculator.calculateSafeInsets(
      Size(width, height),
      isCircular,
    );
    
    return ScreenSize(
      width: width,
      height: height,
      isCircular: isCircular,
      category: category,
      safeInsets: safeInsets,
    );
  }
  
  /// MediaQueryから ScreenSize を作成
  /// 
  /// [context] ビルドコンテキスト
  /// [isCircular] 円形画面かどうか（デフォルト: false）
  /// 
  /// Returns: ScreenSize インスタンス
  factory ScreenSize.fromContext(
    BuildContext context, {
    bool isCircular = false,
  }) {
    final size = MediaQuery.of(context).size;
    final category = _determineCategory(size.width);
    final safeInsets = SafeAreaCalculator.calculateSafeInsets(
      size,
      isCircular,
    );
    
    return ScreenSize(
      width: size.width,
      height: size.height,
      isCircular: isCircular,
      category: category,
      safeInsets: safeInsets,
    );
  }
  
  /// 画面幅からカテゴリーを判定
  static ScreenSizeCategory _determineCategory(double width) {
    if (width < 200) {
      return ScreenSizeCategory.small;
    } else if (width < 300) {
      return ScreenSizeCategory.medium;
    } else {
      return ScreenSizeCategory.large;
    }
  }
  
  /// プライマリフォントサイズ（主要なテキスト用）
  double get primaryFontSize {
    switch (category) {
      case ScreenSizeCategory.small:
        return 14.0;
      case ScreenSizeCategory.medium:
        return 16.0;
      case ScreenSizeCategory.large:
        return 18.0;
    }
  }
  
  /// セカンダリフォントサイズ（補助的なテキスト用）
  double get secondaryFontSize {
    switch (category) {
      case ScreenSizeCategory.small:
        return 12.0;
      case ScreenSizeCategory.medium:
        return 14.0;
      case ScreenSizeCategory.large:
        return 16.0;
    }
  }
  
  /// アイコンサイズ
  double get iconSize {
    switch (category) {
      case ScreenSizeCategory.small:
        return 28.0;
      case ScreenSizeCategory.medium:
        return 32.0;
      case ScreenSizeCategory.large:
        return 40.0;
    }
  }
  
  /// デフォルトパディング
  EdgeInsets get defaultPadding {
    switch (category) {
      case ScreenSizeCategory.small:
        return const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0);
      case ScreenSizeCategory.medium:
        return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
      case ScreenSizeCategory.large:
        return const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0);
    }
  }
  
  /// リストアイテムの高さ
  double get listItemHeight {
    switch (category) {
      case ScreenSizeCategory.small:
        return 48.0;
      case ScreenSizeCategory.medium:
        return 56.0;
      case ScreenSizeCategory.large:
        return 64.0;
    }
  }
  
  /// 最小タップ領域サイズ
  double get minTapTargetSize {
    return 44.0; // すべてのカテゴリーで44x44ピクセル以上を確保
  }
}
