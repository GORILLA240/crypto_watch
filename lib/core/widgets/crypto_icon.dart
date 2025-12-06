import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 暗号通貨アイコンウィジェット
/// 
/// アイコンURLから画像を読み込み、失敗時はプレースホルダーを表示します。
/// キャッシング機能により、一度読み込んだアイコンは再利用されます。
class CryptoIcon extends StatelessWidget {
  final String symbol;
  final double size;

  const CryptoIcon({
    super.key,
    required this.symbol,
    this.size = 40.0,
  });

  /// アイコンURLを生成
  String _getIconUrl(String symbol) {
    // CryptoCompare APIを使用（無料で利用可能）
    return 'https://www.cryptocompare.com/media/37746251/${symbol.toLowerCase()}.png';
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _getIconUrl(symbol),
      placeholder: (context, url) => _buildLoadingPlaceholder(),
      // エラー時はプレースホルダーを表示（要件 1.6）
      errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      width: size,
      height: size,
      fit: BoxFit.cover,
      // パフォーマンス最適化: メモリキャッシュ設定（要件 6.2）
      memCacheWidth: (size * 2).toInt(), // Retina対応
      memCacheHeight: (size * 2).toInt(),
      maxWidthDiskCache: 200, // ディスクキャッシュの最大幅
      maxHeightDiskCache: 200, // ディスクキャッシュの最大高さ
      fadeInDuration: const Duration(milliseconds: 200),
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// 読み込み中のプレースホルダー
  Widget _buildLoadingPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
      ),
    );
  }

  /// エラー時のプレースホルダー（ティッカーシンボルの頭文字を表示）
  /// 要件 15.3: アイコン取得失敗時にティッカーシンボルの頭文字を表示
  /// 要件 15.4: 円形の枠内に表示
  Widget _buildErrorPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle, // 円形の枠（要件 15.4）
      ),
      child: Center(
        child: Text(
          symbol.isNotEmpty ? symbol[0].toUpperCase() : '?', // 頭文字を表示（要件 15.3）
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
