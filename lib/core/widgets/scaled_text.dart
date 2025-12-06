import 'package:flutter/material.dart';
import '../services/font_size_manager.dart';

/// A text widget that automatically scales font size based on user preferences
/// 
/// This widget uses [FontSizeManager] to apply user-selected font size scaling
/// while ensuring the minimum font size constraint (12sp) is maintained.
class ScaledText extends StatelessWidget {
  /// The text to display
  final String text;
  
  /// The base font size before scaling
  final double baseFontSize;
  
  /// Optional text style to apply
  final TextStyle? style;
  
  /// How visual overflow should be handled
  final TextOverflow? overflow;
  
  /// Maximum number of lines for the text to span
  final int? maxLines;
  
  /// How the text should be aligned horizontally
  final TextAlign? textAlign;
  
  /// Whether the text should break at soft line breaks
  final bool? softWrap;
  
  /// The font size manager instance
  final FontSizeManager _fontSizeManager = FontSizeManager();
  
  ScaledText(
    this.text, {
    super.key,
    required this.baseFontSize,
    this.style,
    this.overflow,
    this.maxLines,
    this.textAlign,
    this.softWrap,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FontSizeOption>(
      future: _fontSizeManager.getFontSizeOption(),
      builder: (context, snapshot) {
        // Use normal size as default while loading
        final option = snapshot.data ?? FontSizeOption.normal;
        
        // Calculate scaled font size with minimum constraint
        final fontSize = _fontSizeManager.getScaledFontSize(
          baseFontSize,
          option,
        );
        
        // Apply the scaled font size to the style
        final effectiveStyle = (style ?? const TextStyle()).copyWith(
          fontSize: fontSize,
        );
        
        return Text(
          text,
          style: effectiveStyle,
          overflow: overflow ?? TextOverflow.ellipsis,
          maxLines: maxLines,
          textAlign: textAlign,
          softWrap: softWrap,
        );
      },
    );
  }
}
