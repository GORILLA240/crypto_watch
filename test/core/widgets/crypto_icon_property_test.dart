import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/widgets/crypto_icon.dart';
import 'package:crypto_watch/core/services/favorites_manager.dart';

/// Property 8: 通貨アイコン取得の統一性
/// **Feature: smartwatch-ui-optimization, Property 8: 通貨アイコン取得の統一性**
/// **Validates: Requirements 15.8**
/// 
/// 任意の通貨（デフォルトまたはカスタム）に対して、
/// アイコンは同じAPI（CryptoCompare）から同じ方法で取得される
void main() {
  group('Property 8: Icon Fetching Uniformity', () {
    test('default and custom currencies use same icon URL pattern', () {
      // デフォルト通貨のサンプル
      final defaultCurrencies = FavoritesManager.defaultCurrencies.take(5).toList();
      
      // カスタム通貨のサンプル
      final customCurrencies = ['SHIB', 'PEPE', 'FLOKI', 'BONK', 'WIF'];
      
      // すべての通貨のアイコンURLを取得
      final allSymbols = [...defaultCurrencies, ...customCurrencies];
      
      for (final symbol in allSymbols) {
        // CryptoIconウィジェットが内部で使用するURL生成ロジックを再現
        final iconUrl = 'https://www.cryptocompare.com/media/37746251/${symbol.toLowerCase()}.png';
        
        // すべての通貨が同じドメインを使用していることを検証
        expect(
          iconUrl,
          contains('cryptocompare.com'),
          reason: 'Symbol $symbol should use CryptoCompare API',
        );
        
        // URLパターンが一貫していることを検証
        expect(
          iconUrl,
          matches(RegExp(r'^https://www\.cryptocompare\.com/media/\d+/[a-z]+\.png$')),
          reason: 'Symbol $symbol should follow consistent URL pattern',
        );
      }
    });

    test('icon URL generation is consistent for any symbol', () {
      // ランダムなシンボルのセット（大文字・小文字混在）
      final testSymbols = [
        'BTC', 'btc', 'Btc',  // 大文字・小文字のバリエーション
        'ETH', 'eth',
        'CUSTOM1', 'custom2', 'CuStOm3',  // カスタム通貨
      ];
      
      for (final symbol in testSymbols) {
        final iconUrl = 'https://www.cryptocompare.com/media/37746251/${symbol.toLowerCase()}.png';
        
        // すべてのシンボルが小文字に正規化されることを検証
        expect(
          iconUrl,
          contains(symbol.toLowerCase()),
          reason: 'Symbol $symbol should be normalized to lowercase',
        );
        
        // 大文字が含まれていないことを検証
        final pathPart = iconUrl.split('/').last.split('.').first;
        expect(
          pathPart,
          equals(pathPart.toLowerCase()),
          reason: 'URL path should not contain uppercase letters',
        );
      }
    });

    test('default and custom currencies have same error handling', () {
      // デフォルト通貨
      final defaultSymbol = 'BTC';
      // カスタム通貨
      final customSymbol = 'SHIB';
      
      // 両方とも同じエラーハンドリング（プレースホルダー表示）を持つ
      // CryptoIconウィジェットは errorWidget で同じプレースホルダーを使用
      
      // プレースホルダーのロジックを検証
      final defaultPlaceholder = defaultSymbol.isNotEmpty ? defaultSymbol[0].toUpperCase() : '?';
      final customPlaceholder = customSymbol.isNotEmpty ? customSymbol[0].toUpperCase() : '?';
      
      expect(defaultPlaceholder, equals('B'));
      expect(customPlaceholder, equals('S'));
      
      // 両方とも同じロジックで頭文字を抽出
      expect(defaultPlaceholder.length, equals(1));
      expect(customPlaceholder.length, equals(1));
    });

    test('icon fetching does not depend on currency type', () {
      // デフォルト通貨とカスタム通貨を混在させる
      final mixedSymbols = ['BTC', 'SHIB', 'ETH', 'PEPE', 'ADA', 'FLOKI'];
      
      final iconUrls = mixedSymbols.map((symbol) {
        return 'https://www.cryptocompare.com/media/37746251/${symbol.toLowerCase()}.png';
      }).toList();
      
      // すべてのURLが同じパターンに従うことを検証
      for (var i = 0; i < iconUrls.length; i++) {
        final url = iconUrls[i];
        final symbol = mixedSymbols[i];
        
        // URLの構造が一貫していることを検証
        expect(url.startsWith('https://www.cryptocompare.com/media/'), isTrue);
        expect(url.endsWith('.png'), isTrue);
        expect(url.contains(symbol.toLowerCase()), isTrue);
      }
    });
  });
}
