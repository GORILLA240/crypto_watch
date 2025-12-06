import 'package:flutter/material.dart';
import '../utils/screen_size.dart';

/// 画面サイズに応じて動的にレイアウトを調整するビルダーウィジェット
/// 
/// LayoutBuilderを使用して利用可能なサイズを取得し、
/// ScreenSizeオブジェクトをビルダー関数に渡します。
/// 
/// 使用例:
/// ```dart
/// ResponsiveLayoutBuilder(
///   isCircular: true,
///   builder: (context, screenSize) {
///     return Text(
///       'Hello',
///       style: TextStyle(fontSize: screenSize.primaryFontSize),
///     );
///   },
/// )
/// ```
class ResponsiveLayoutBuilder extends StatelessWidget {
  /// レイアウトを構築するビルダー関数
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;
  
  /// 円形画面かどうか
  final bool isCircular;
  
  const ResponsiveLayoutBuilder({
    super.key,
    required this.builder,
    this.isCircular = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 利用可能なサイズからScreenSizeを作成
        final screenSize = ScreenSize.fromConstraints(
          constraints,
          isCircular: isCircular,
        );
        
        // ビルダー関数を呼び出してウィジェットを構築
        return builder(context, screenSize);
      },
    );
  }
}
