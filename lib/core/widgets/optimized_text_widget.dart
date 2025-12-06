import 'package:flutter/material.dart';

/// テキストオーバーフローを防止する最適化されたテキストウィジェット
/// 
/// このウィジェットは以下の機能を提供します：
/// - テキストの自動省略（...）
/// - 画面幅に応じたフォントサイズ調整
/// - 複数行テキストの適切な折り返し
/// 
/// Requirements: 1.1, 1.2
class OptimizedTextWidget extends StatelessWidget {
  /// 表示するテキスト
  final String text;
  
  /// テキストスタイル
  final TextStyle? style;
  
  /// 最大行数（nullの場合は無制限）
  final int? maxLines;
  
  /// オーバーフロー時の動作
  final TextOverflow overflow;
  
  /// 自動フォントサイズ調整を有効にするか
  final bool autoScale;
  
  /// テキストの配置
  final TextAlign? textAlign;
  
  /// 最小フォントサイズ（autoScaleがtrueの場合に使用）
  final double minFontSize;
  
  /// 最大フォントサイズ（autoScaleがtrueの場合に使用）
  final double? maxFontSize;
  
  /// ソフトラップを有効にするか
  final bool softWrap;
  
  /// 最大幅（autoScaleがtrueの場合に使用）
  final double? maxWidth;

  const OptimizedTextWidget(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.autoScale = false,
    this.textAlign,
    this.minFontSize = 12.0,
    this.maxFontSize,
    this.softWrap = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (autoScale) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = maxWidth ?? constraints.maxWidth;
          
          // 利用可能な幅が無限の場合は通常のTextウィジェットを返す
          if (availableWidth.isInfinite) {
            return _buildText();
          }
          
          // フォントサイズを計算
          final baseFontSize = style?.fontSize ?? 14.0;
          final effectiveMaxFontSize = maxFontSize ?? baseFontSize;
          
          // テキストの幅を測定して適切なフォントサイズを決定
          double fontSize = effectiveMaxFontSize;
          
          // 最小フォントサイズまで縮小を試みる
          while (fontSize >= minFontSize) {
            final textPainter = TextPainter(
              text: TextSpan(
                text: text,
                style: (style ?? const TextStyle()).copyWith(fontSize: fontSize),
              ),
              maxLines: maxLines,
              textDirection: TextDirection.ltr,
            );
            
            textPainter.layout(maxWidth: availableWidth);
            
            // テキストが収まる場合はこのフォントサイズを使用
            if (!textPainter.didExceedMaxLines && 
                textPainter.width <= availableWidth) {
              break;
            }
            
            // フォントサイズを1ポイント縮小
            fontSize -= 1.0;
          }
          
          // 最小フォントサイズを下回らないように調整
          fontSize = fontSize.clamp(minFontSize, effectiveMaxFontSize);
          
          return _buildText(fontSize: fontSize);
        },
      );
    }
    
    return _buildText();
  }
  
  Widget _buildText({double? fontSize}) {
    final effectiveStyle = fontSize != null
        ? (style ?? const TextStyle()).copyWith(fontSize: fontSize)
        : style;
    
    return Text(
      text,
      style: effectiveStyle,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      softWrap: softWrap,
    );
  }
}
