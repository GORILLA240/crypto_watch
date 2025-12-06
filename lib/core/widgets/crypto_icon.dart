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

  /// アイコンURLを生成（複数のソースを試行）
  List<String> _getIconUrls(String symbol) {
    final symbolLower = symbol.toLowerCase();
    return [
      // CoinGecko API（最も信頼性が高い）
      'https://assets.coingecko.com/coins/images/${_getCoinGeckoId(symbolLower)}/large/$symbolLower.png',
      // CryptoCompare API（フォールバック）
      'https://www.cryptocompare.com/media/37746251/$symbolLower.png',
      // Coinpaprika API（セカンダリフォールバック）
      'https://static.coinpaprika.com/coin/$symbolLower/logo.png',
    ];
  }

  /// CoinGecko IDマッピング（主要通貨）
  String _getCoinGeckoId(String symbol) {
    const idMap = {
      'btc': '1',
      'eth': '279',
      'ada': '2010',
      'bnb': '825',
      'xrp': '52',
      'sol': '5426',
      'dot': '6636',
      'doge': '5',
      'avax': '12559',
      'matic': '4713',
      'link': '1975',
      'uni': '7083',
      'ltc': '2',
      'atom': '3794',
      'xlm': '5',
      'algo': '4030',
      'vet': '1063',
      'icp': '8916',
      'fil': '5817',
      'trx': '1094',
    };
    return idMap[symbol] ?? '1';
  }

  @override
  Widget build(BuildContext context) {
    return _CryptoIconWithFallback(
      urls: _getIconUrls(symbol),
      symbol: symbol,
      size: size,
    );
  }
}

/// フォールバック機能付きアイコンウィジェット
class _CryptoIconWithFallback extends StatefulWidget {
  final List<String> urls;
  final String symbol;
  final double size;

  const _CryptoIconWithFallback({
    required this.urls,
    required this.symbol,
    required this.size,
  });

  @override
  State<_CryptoIconWithFallback> createState() => _CryptoIconWithFallbackState();
}

class _CryptoIconWithFallbackState extends State<_CryptoIconWithFallback> {
  int _currentUrlIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentUrlIndex >= widget.urls.length) {
      return _buildErrorPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: widget.urls[_currentUrlIndex],
      placeholder: (context, url) => _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) {
        // 次のURLを試す
        if (_currentUrlIndex < widget.urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentUrlIndex++;
              });
            }
          });
          return _buildLoadingPlaceholder();
        }
        return _buildErrorPlaceholder();
      },
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      memCacheWidth: (widget.size * 2).toInt(),
      memCacheHeight: (widget.size * 2).toInt(),
      maxWidthDiskCache: 200,
      maxHeightDiskCache: 200,
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

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.5,
          height: widget.size * 0.5,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.symbol.isNotEmpty ? widget.symbol[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
