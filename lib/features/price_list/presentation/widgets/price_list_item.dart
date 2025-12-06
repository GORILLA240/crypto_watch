import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/display_density.dart';
import '../../../../core/widgets/crypto_icon.dart';
import '../../../../core/widgets/optimized_text_widget.dart';
import '../../domain/entities/crypto_price.dart';

/// 価格リストアイテムウィジェット
class PriceListItem extends StatelessWidget {
  final CryptoPrice price;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String displayCurrency;
  final bool isFavorite;
  final DisplayDensity displayDensity;
  final bool isReorderMode;

  const PriceListItem({
    super.key,
    required this.price,
    this.onTap,
    this.onLongPress,
    this.displayCurrency = 'JPY',
    this.isFavorite = false,
    this.displayDensity = DisplayDensity.standard,
    this.isReorderMode = false,
  });

  /// コンテキストメニューを表示
  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ハンドルバー
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
            // お気に入り追加/削除オプション
            Semantics(
              label: isFavorite 
                  ? '${price.symbol}をお気に入りから削除' 
                  : '${price.symbol}をお気に入りに追加',
              button: true,
              child: ListTile(
                leading: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.white,
                ),
                title: Text(
                  isFavorite ? 'お気に入りから削除' : 'お気に入りに追加',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onLongPress?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = price.change24h >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    // 価格をUSDから指定通貨に換算
    // BTC換算は現時点では未対応（BTC価格の取得が必要）
    final effectiveCurrency = displayCurrency == 'BTC' ? 'USD' : displayCurrency;
    final convertedPrice = CurrencyFormatter.convert(
      price.price,
      fromCurrency: 'USD',
      toCurrency: effectiveCurrency,
    );

    // 表示密度に応じた設定を取得
    final config = DisplayDensityHelper.getConfig(displayDensity);

    // アクセシビリティ用のセマンティックラベルを構築
    final formattedPrice = CurrencyFormatter.format(
      convertedPrice,
      currency: effectiveCurrency,
    );
    final formattedChange = CurrencyFormatter.formatChangePercent(price.change24h);
    final changeDirection = isPositive ? '上昇' : '下落';
    
    final semanticLabel = '${price.name}, ${price.symbol}, '
        '価格 $formattedPrice, '
        '24時間変動 $formattedChange $changeDirection'
        '${isFavorite ? ", お気に入り登録済み" : ""}';

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: !isReorderMode,
      child: InkWell(
        onTap: isReorderMode ? null : onTap,
        onLongPress: isReorderMode ? null : () {
          // 触覚フィードバックを提供
          HapticFeedback.mediumImpact();
          // コンテキストメニューを表示
          _showContextMenu(context);
        },
        child: Container(
          // 最小タップ領域を確保（44x44ポイント）
          constraints: const BoxConstraints(
            minHeight: 48.0, // 最小タップ領域を確保（要件 12.1）
            minWidth: 44.0,
          ),
          height: config.itemHeight,
          // 最小パディング要件を満たす（要件 8.1, 8.2, 8.5）
          padding: EdgeInsets.symmetric(
            horizontal: config.padding, // 12px以上
            vertical: config.padding * 0.5 < 8.0 ? 8.0 : config.padding * 0.5, // 8px以上
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[800]!,
                width: 1,
              ),
            ),
          ),
        child: Row(
          children: [
            // ドラッグハンドル（並び替えモード時のみ表示）
            if (isReorderMode) ...[
              Icon(
                Icons.drag_handle,
                color: Colors.grey[600],
                size: config.iconSize * 0.8,
              ),
              SizedBox(width: config.padding * 0.5),
            ],
            
            // 通貨アイコン（左端）（要件 15.1, 15.2, 15.6）
            CryptoIcon(
              symbol: price.symbol,
              size: config.iconSize,
            ),
            // アイコンとテキストの間隔を8ピクセル確保（要件 15.7）
            const SizedBox(width: 8.0),
            
            // シンボルと名前
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OptimizedTextWidget(
                    price.symbol,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: config.fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (displayDensity == DisplayDensity.standard) ...[
                    const SizedBox(height: 4),
                    OptimizedTextWidget(
                      price.name,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: config.fontSize * 0.75,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (displayDensity == DisplayDensity.compact) ...[
                    const SizedBox(height: 2),
                    OptimizedTextWidget(
                      price.name,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: config.fontSize * 0.7,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // 価格
            Expanded(
              flex: 2,
              child: OptimizedTextWidget(
                CurrencyFormatter.format(
                  convertedPrice,
                  currency: effectiveCurrency,
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: config.fontSize,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: config.padding * 0.75),
            
            // 変動率
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: config.padding * 0.5,
                  vertical: config.padding * 0.25,
                ),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.2),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                child: OptimizedTextWidget(
                  CurrencyFormatter.formatChangePercent(price.change24h),
                  style: TextStyle(
                    color: changeColor,
                    fontSize: config.fontSize * 0.85,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            // お気に入りアイコン（右端）
            if (isFavorite) ...[
              SizedBox(width: config.padding * 0.5),
              Icon(
                Icons.star,
                color: Colors.amber,
                size: displayDensity == DisplayDensity.maximum 
                    ? config.iconSize * 0.5 
                    : config.iconSize * 0.6,
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
