import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ユーティリティクラス：円形画面の安全領域を計算
/// 
/// スマートウォッチの円形画面において、コンテンツが画面の角で切れないように
/// 安全な表示領域を計算します。
class SafeAreaCalculator {
  /// 円形画面の安全なインセットを計算
  /// 
  /// [screenSize] 画面のサイズ
  /// [isCircular] 円形画面かどうか
  /// 
  /// Returns: 安全な余白（EdgeInsets）
  /// 
  /// 円形画面の場合、画面の角を避けるため、中央70%を安全領域とします。
  /// 正方形画面の場合は、最小限の余白（8ピクセル）を返します。
  static EdgeInsets calculateSafeInsets(Size screenSize, bool isCircular) {
    if (!isCircular) {
      // 正方形画面の場合は最小限の余白
      return const EdgeInsets.all(8.0);
    }
    
    // 円形画面の場合、角を避けるため大きめのインセット
    final radius = screenSize.width / 2;
    final safeRadius = radius * 0.7; // 中央70%を安全領域とする
    final inset = radius - safeRadius;
    
    return EdgeInsets.all(inset);
  }
  
  /// 円形画面での最大コンテンツ幅を取得
  /// 
  /// [screenSize] 画面のサイズ
  /// [isCircular] 円形画面かどうか
  /// 
  /// Returns: 安全に表示できる最大幅
  /// 
  /// 円形画面の場合、画面幅の70%を安全な最大幅とします。
  /// 正方形画面の場合は、余白を除いた幅を返します。
  static double getMaxContentWidth(Size screenSize, bool isCircular) {
    if (!isCircular) {
      // 正方形画面の場合は余白を除いた幅
      return screenSize.width - 16.0; // 左右8ピクセルずつの余白
    }
    
    // 円形画面の場合、中央70%の幅
    return screenSize.width * 0.7;
  }
  
  /// 指定された位置が安全領域内にあるかチェック
  /// 
  /// [position] チェックする位置
  /// [screenSize] 画面のサイズ
  /// 
  /// Returns: 安全領域内の場合true
  /// 
  /// 円形画面を想定し、画面中心からの距離が安全半径内かどうかを判定します。
  static bool isInSafeArea(Offset position, Size screenSize) {
    final center = Offset(screenSize.width / 2, screenSize.height / 2);
    final radius = screenSize.width / 2;
    final safeRadius = radius * 0.7;
    
    // 中心からの距離を計算
    final distance = math.sqrt(
      math.pow(position.dx - center.dx, 2) + 
      math.pow(position.dy - center.dy, 2)
    );
    
    return distance <= safeRadius;
  }
}
