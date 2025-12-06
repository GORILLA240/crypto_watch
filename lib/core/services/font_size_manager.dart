import 'package:shared_preferences/shared_preferences.dart';

/// Font size options available to users
enum FontSizeOption {
  small,
  normal,
  large,
  extraLarge,
}

/// Manages user font size preferences and provides scaled font sizes
/// 
/// This manager handles:
/// - Storing and retrieving user font size preferences
/// - Scaling base font sizes according to user preference
/// - Ensuring minimum font size constraints are met
class FontSizeManager {
  static const String _key = 'font_size_option';
  static const double minFontSize = 12.0;
  
  /// Scale factors for each font size option
  /// - small: 90% of base size
  /// - normal: 100% of base size (default)
  /// - large: 110% of base size
  /// - extraLarge: 120% of base size
  static const Map<FontSizeOption, double> scales = {
    FontSizeOption.small: 0.9,
    FontSizeOption.normal: 1.0,
    FontSizeOption.large: 1.1,
    FontSizeOption.extraLarge: 1.2,
  };
  
  /// Retrieves the current font size option from shared preferences
  /// 
  /// Returns [FontSizeOption.normal] if no preference is saved
  Future<FontSizeOption> getFontSizeOption() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    
    if (value == null) {
      return FontSizeOption.normal;
    }
    
    return FontSizeOption.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => FontSizeOption.normal,
    );
  }
  
  /// Saves the font size option to shared preferences
  /// 
  /// [option] The font size option to save
  Future<void> setFontSizeOption(FontSizeOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, option.toString());
  }
  
  /// Calculates the scaled font size based on the base size and option
  /// 
  /// [baseSize] The base font size to scale
  /// [option] The font size option to apply
  /// 
  /// Returns the scaled font size, clamped to the minimum font size
  double getScaledFontSize(double baseSize, FontSizeOption option) {
    final scaled = baseSize * scales[option]!;
    return clampFontSize(scaled);
  }
  
  /// Ensures the font size is not below the minimum threshold
  /// 
  /// [size] The font size to clamp
  /// 
  /// Returns the font size, ensuring it's at least [minFontSize]
  double clampFontSize(double size) {
    return size < minFontSize ? minFontSize : size;
  }
}
