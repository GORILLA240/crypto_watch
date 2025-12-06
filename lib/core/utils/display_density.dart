/// 表示密度の列挙型
enum DisplayDensity {
  /// 標準モード: 3-5銘柄/画面
  standard,
  
  /// コンパクトモード: 6-8銘柄/画面
  compact,
  
  /// 最大モード: 9-12銘柄/画面
  maximum;

  /// 文字列から表示密度を取得
  static DisplayDensity fromString(String value) {
    switch (value.toLowerCase()) {
      case 'standard':
        return DisplayDensity.standard;
      case 'compact':
        return DisplayDensity.compact;
      case 'maximum':
        return DisplayDensity.maximum;
      default:
        return DisplayDensity.standard;
    }
  }

  /// 表示密度を文字列に変換
  String toStringValue() {
    return name;
  }
}

/// 表示密度の設定クラス
class DisplayDensityConfig {
  final DisplayDensity density;
  final double itemHeight;
  final double iconSize;
  final double fontSize;
  final double padding;

  const DisplayDensityConfig({
    required this.density,
    required this.itemHeight,
    required this.iconSize,
    required this.fontSize,
    required this.padding,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplayDensityConfig &&
        other.density == density &&
        other.itemHeight == itemHeight &&
        other.iconSize == iconSize &&
        other.fontSize == fontSize &&
        other.padding == padding;
  }

  @override
  int get hashCode {
    return Object.hash(
      density,
      itemHeight,
      iconSize,
      fontSize,
      padding,
    );
  }
}

/// 表示密度ヘルパークラス
class DisplayDensityHelper {
  // パフォーマンス最適化: 設定をキャッシュ（要件 6.1）
  // 最小パディング要件を満たす（要件 8.1, 8.2, 8.5）
  static const _standardConfig = DisplayDensityConfig(
    density: DisplayDensity.standard,
    itemHeight: 80.0,
    iconSize: 40.0,
    fontSize: 18.0,
    padding: 16.0, // 横方向パディング（12px以上）
  );

  static const _compactConfig = DisplayDensityConfig(
    density: DisplayDensity.compact,
    itemHeight: 60.0,
    iconSize: 32.0,
    fontSize: 16.0,
    padding: 12.0, // 横方向パディング（12px以上）
  );

  static const _maximumConfig = DisplayDensityConfig(
    density: DisplayDensity.maximum,
    itemHeight: 52.0, // 最小タップ領域を確保するため52pxに増加
    iconSize: 32.0,
    fontSize: 14.0,
    padding: 12.0, // 横方向パディング（12px以上、8pxから増加）
  );

  /// 表示密度に応じた設定を取得
  static DisplayDensityConfig getConfig(DisplayDensity density) {
    switch (density) {
      case DisplayDensity.standard:
        return _standardConfig;
      case DisplayDensity.compact:
        return _compactConfig;
      case DisplayDensity.maximum:
        return _maximumConfig;
    }
  }

  /// 画面に表示可能な銘柄数を計算
  static int calculateVisibleItems(
    double screenHeight,
    DisplayDensity density,
  ) {
    final config = getConfig(density);
    const appBarHeight = 56.0;
    final availableHeight = screenHeight - appBarHeight;
    return (availableHeight / config.itemHeight).floor();
  }

  /// 表示密度の最小銘柄数を取得
  static int getMinItems(DisplayDensity density) {
    switch (density) {
      case DisplayDensity.standard:
        return 3;
      case DisplayDensity.compact:
        return 6;
      case DisplayDensity.maximum:
        return 9;
    }
  }

  /// 表示密度の最大銘柄数を取得
  static int getMaxItems(DisplayDensity density) {
    switch (density) {
      case DisplayDensity.standard:
        return 5;
      case DisplayDensity.compact:
        return 8;
      case DisplayDensity.maximum:
        return 12;
    }
  }
}
