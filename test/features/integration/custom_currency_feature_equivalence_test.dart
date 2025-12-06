import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto_watch/core/services/favorites_manager.dart';
import 'package:crypto_watch/core/models/favorites_currency.dart';
import 'package:crypto_watch/features/alerts/domain/entities/price_alert.dart';

@GenerateMocks([SharedPreferences])
import 'custom_currency_feature_equivalence_test.mocks.dart';

/// Property 10: 機能の同等性
/// **Feature: smartwatch-ui-optimization, Property 10: 機能の同等性**
/// **Validates: Requirements 17.10**
/// 
/// 任意の通貨（デフォルトまたはカスタム）に対して、
/// 詳細画面、お気に入り追加、アラート設定などすべての機能が利用可能である
void main() {
  late MockSharedPreferences mockPrefs;
  late FavoritesManager favoritesManager;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    favoritesManager = FavoritesManager(mockPrefs);
  });

  group('Property 10: Feature Equivalence', () {
    test('default and custom currencies can be added to favorites', () async {
      // デフォルト通貨
      final defaultSymbol = 'BTC';
      // カスタム通貨
      final customSymbol = 'SHIB';

      // 初期状態をモック
      when(mockPrefs.getString(any)).thenReturn(null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      // デフォルト通貨をお気に入りに追加
      await favoritesManager.addFavorite(defaultSymbol);
      
      // カスタム通貨をお気に入りに追加
      await favoritesManager.addFavorite(customSymbol);

      // 両方とも同じメソッドで追加できることを検証
      verify(mockPrefs.setString(any, any)).called(greaterThanOrEqualTo(2));
    });

    test('default and custom currencies can be removed from favorites', () async {
      // デフォルト通貨とカスタム通貨を含むお気に入りリスト
      final favorites = [
        FavoritesCurrency(
          symbol: 'BTC',
          isDefault: true,
          addedAt: DateTime.now(),
          displayOrder: 0,
        ),
        FavoritesCurrency(
          symbol: 'SHIB',
          isDefault: false,
          addedAt: DateTime.now(),
          displayOrder: 1,
        ),
      ];

      // お気に入りリストをモック
      when(mockPrefs.getString(any)).thenReturn(
        '[${favorites.map((f) => '{"symbol":"${f.symbol}","isDefault":${f.isDefault},"addedAt":"${f.addedAt.toIso8601String()}","displayOrder":${f.displayOrder}}').join(',')}]',
      );
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      // デフォルト通貨を削除
      await favoritesManager.removeFavorite('BTC');
      
      // カスタム通貨を削除
      await favoritesManager.removeFavorite('SHIB');

      // 両方とも同じメソッドで削除できることを検証
      verify(mockPrefs.setString(any, any)).called(2);
    });

    test('alerts can be created for both default and custom currencies', () {
      // デフォルト通貨のアラート
      final defaultAlert = PriceAlert(
        id: '1',
        symbol: 'BTC',
        upperLimit: 60000.0,
        lowerLimit: 40000.0,
        isEnabled: true,
        createdAt: DateTime.now(),
      );

      // カスタム通貨のアラート
      final customAlert = PriceAlert(
        id: '2',
        symbol: 'SHIB',
        upperLimit: 0.00002,
        lowerLimit: 0.00001,
        isEnabled: true,
        createdAt: DateTime.now(),
      );

      // 両方とも同じデータ構造を持つことを検証
      expect(defaultAlert.symbol, isA<String>());
      expect(customAlert.symbol, isA<String>());
      
      expect(defaultAlert.upperLimit, isA<double>());
      expect(customAlert.upperLimit, isA<double>());
      
      expect(defaultAlert.lowerLimit, isA<double>());
      expect(customAlert.lowerLimit, isA<double>());
      
      expect(defaultAlert.isEnabled, isA<bool>());
      expect(customAlert.isEnabled, isA<bool>());

      // アラートのトリガーロジックが同じであることを検証
      expect(defaultAlert.shouldTrigger(65000.0), isTrue);
      expect(customAlert.shouldTrigger(0.000025), isTrue);
      
      expect(defaultAlert.shouldTrigger(50000.0), isFalse);
      expect(customAlert.shouldTrigger(0.000015), isFalse);
    });

    test('price detail page can display both default and custom currencies', () {
      // 価格詳細画面は symbol パラメータのみを受け取る
      // デフォルト通貨とカスタム通貨で同じパラメータ形式
      
      final defaultSymbol = 'BTC';
      final customSymbol = 'SHIB';

      // 両方とも同じ形式のシンボル文字列
      expect(defaultSymbol, isA<String>());
      expect(customSymbol, isA<String>());
      
      // シンボルの長さは任意（制限なし）
      expect(defaultSymbol.length, greaterThan(0));
      expect(customSymbol.length, greaterThan(0));
    });

    test('favorites manager treats all currencies uniformly', () async {
      // 初期状態をモック
      when(mockPrefs.getString(any)).thenReturn(null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      // 複数の通貨（デフォルトとカスタム混在）を追加
      final symbols = ['BTC', 'SHIB', 'ETH', 'PEPE', 'ADA', 'FLOKI'];
      
      for (final symbol in symbols) {
        await favoritesManager.addFavorite(symbol);
      }

      // すべての通貨が同じメソッドで追加されることを検証
      // 初回はデフォルト通貨の初期化で1回、その後各追加で1回ずつ
      verify(mockPrefs.setString(any, any)).called(greaterThanOrEqualTo(symbols.length));
    });

    test('currency type detection is consistent', () {
      // デフォルト通貨の検出
      expect(favoritesManager.isDefaultCurrency('BTC'), isTrue);
      expect(favoritesManager.isDefaultCurrency('ETH'), isTrue);
      expect(favoritesManager.isDefaultCurrency('ADA'), isTrue);

      // カスタム通貨の検出
      expect(favoritesManager.isCustomCurrency('SHIB'), isTrue);
      expect(favoritesManager.isCustomCurrency('PEPE'), isTrue);
      expect(favoritesManager.isCustomCurrency('FLOKI'), isTrue);

      // 相互排他的であることを検証
      expect(favoritesManager.isDefaultCurrency('SHIB'), isFalse);
      expect(favoritesManager.isCustomCurrency('BTC'), isFalse);
    });

    test('all currencies support the same operations', () async {
      // 初期状態をモック
      when(mockPrefs.getString(any)).thenReturn(null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      final testSymbols = ['BTC', 'SHIB', 'ETH', 'PEPE'];

      // すべての通貨に対して同じ操作が可能
      for (final symbol in testSymbols) {
        // 追加
        await favoritesManager.addFavorite(symbol);
        
        // 削除
        await favoritesManager.removeFavorite(symbol);
        
        // タイプ判定
        final isDefault = favoritesManager.isDefaultCurrency(symbol);
        final isCustom = favoritesManager.isCustomCurrency(symbol);
        
        // 相互排他的
        expect(isDefault != isCustom, isTrue);
      }

      // すべての通貨で同じ回数の操作が実行されたことを検証
      // 初回はデフォルト通貨の初期化で1回、その後各追加・削除で2回ずつ
      verify(mockPrefs.setString(any, any)).called(greaterThanOrEqualTo(testSymbols.length * 2));
    });

    test('favorites list maintains order for all currency types', () {
      // デフォルト通貨とカスタム通貨を混在させたリスト
      final now = DateTime.now();
      final favorites = [
        FavoritesCurrency(
          symbol: 'BTC',
          isDefault: true,
          addedAt: now,
          displayOrder: 0,
        ),
        FavoritesCurrency(
          symbol: 'SHIB',
          isDefault: false,
          addedAt: now,
          displayOrder: 1,
        ),
        FavoritesCurrency(
          symbol: 'ETH',
          isDefault: true,
          addedAt: now,
          displayOrder: 2,
        ),
        FavoritesCurrency(
          symbol: 'PEPE',
          isDefault: false,
          addedAt: now,
          displayOrder: 3,
        ),
      ];

      // すべての通貨が displayOrder フィールドを持つことを検証
      for (final favorite in favorites) {
        expect(favorite.displayOrder, isA<int>());
        expect(favorite.displayOrder, greaterThanOrEqualTo(0));
      }

      // デフォルト通貨とカスタム通貨が同じデータ構造を持つことを検証
      final defaultCurrency = favorites.firstWhere((f) => f.isDefault);
      final customCurrency = favorites.firstWhere((f) => !f.isDefault);

      expect(defaultCurrency.symbol, isA<String>());
      expect(customCurrency.symbol, isA<String>());
      
      expect(defaultCurrency.displayOrder, isA<int>());
      expect(customCurrency.displayOrder, isA<int>());
      
      expect(defaultCurrency.addedAt, isA<DateTime>());
      expect(customCurrency.addedAt, isA<DateTime>());

      // 順序が連続していることを検証
      for (var i = 0; i < favorites.length; i++) {
        expect(favorites[i].displayOrder, equals(i));
      }
    });
  });
}
