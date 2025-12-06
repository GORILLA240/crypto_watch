import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto_watch/core/services/favorites_manager.dart';

void main() {
  late FavoritesManager favoritesManager;
  late SharedPreferences prefs;

  setUp(() async {
    // SharedPreferencesのモックを初期化
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    favoritesManager = FavoritesManager(prefs);
  });

  tearDown(() async {
    // テスト後にクリーンアップ
    await favoritesManager.clearFavorites();
  });

  group('FavoritesManager - デフォルト通貨の初期化', () {
    test('初回起動時にデフォルト通貨20種類が返される', () async {
      // Act
      final favorites = await favoritesManager.getFavorites();

      // Assert
      expect(favorites.length, equals(20));
      expect(favorites.every((f) => f.isDefault), isTrue);
      expect(
        favorites.map((f) => f.symbol).toList(),
        equals(FavoritesManager.defaultCurrencies),
      );
    });

    test('デフォルト通貨は正しい順序で初期化される', () async {
      // Act
      final favorites = await favoritesManager.getFavorites();

      // Assert
      for (var i = 0; i < favorites.length; i++) {
        expect(favorites[i].displayOrder, equals(i));
        expect(favorites[i].symbol, equals(FavoritesManager.defaultCurrencies[i]));
      }
    });

    test('デフォルト通貨はすべて同じ追加日時を持つ', () async {
      // Act
      final favorites = await favoritesManager.getFavorites();

      // Assert
      final firstAddedAt = favorites.first.addedAt;
      expect(
        favorites.every((f) => f.addedAt.difference(firstAddedAt).inSeconds < 1),
        isTrue,
      );
    });
  });

  group('FavoritesManager - お気に入りの追加', () {
    test('カスタム通貨を追加できる', () async {
      // Arrange
      const customSymbol = 'SHIB';

      // Act
      await favoritesManager.addFavorite(customSymbol);
      final favorites = await favoritesManager.getFavorites();

      // Assert
      expect(favorites.length, equals(21)); // 20 default + 1 custom
      final customCurrency = favorites.firstWhere((f) => f.symbol == customSymbol);
      expect(customCurrency.isDefault, isFalse);
      expect(customCurrency.displayOrder, equals(20));
    });

    test('既に存在する通貨は追加されない', () async {
      // Arrange
      const existingSymbol = 'BTC';

      // Act
      await favoritesManager.addFavorite(existingSymbol);
      final favorites = await favoritesManager.getFavorites();

      // Assert
      expect(favorites.length, equals(20)); // デフォルトのみ
      expect(
        favorites.where((f) => f.symbol == existingSymbol).length,
        equals(1),
      );
    });

    test('小文字のシンボルは大文字に変換される', () async {
      // Arrange
      const customSymbol = 'shib';

      // Act
      await favoritesManager.addFavorite(customSymbol);
      final favorites = await favoritesManager.getFavorites();

      // Assert
      final customCurrency = favorites.firstWhere((f) => f.symbol == 'SHIB');
      expect(customCurrency.symbol, equals('SHIB'));
    });

    test('複数のカスタム通貨を追加できる', () async {
      // Arrange
      const customSymbols = ['SHIB', 'PEPE', 'FLOKI'];

      // Act
      for (final symbol in customSymbols) {
        await favoritesManager.addFavorite(symbol);
      }
      final favorites = await favoritesManager.getFavorites();

      // Assert
      expect(favorites.length, equals(23)); // 20 default + 3 custom
      for (final symbol in customSymbols) {
        expect(favorites.any((f) => f.symbol == symbol), isTrue);
      }
    });
  });

  group('FavoritesManager - お気に入りの削除', () {
    test('デフォルト通貨を削除できる', () async {
      // Arrange
      const symbolToRemove = 'BTC';

      // Act
      await favoritesManager.removeFavorite(symbolToRemove);
      final favorites = await favoritesManager.getFavorites();

      // Assert
      expect(favorites.length, equals(19));
      expect(favorites.any((f) => f.symbol == symbolToRemove), isFalse);
    });

    test('カスタム通貨を削除できる', () async {
      // Arrange
      const customSymbol = 'SHIB';
      await favoritesManager.addFavorite(customSymbol);

      // Act
      await favoritesManager.removeFavorite(customSymbol);
      final favorites = await favoritesManager.getFavorites();

      // Assert
      expect(favorites.length, equals(20)); // デフォルトのみ
      expect(favorites.any((f) => f.symbol == customSymbol), isFalse);
    });

    test('削除後に表示順序が再調整される', () async {
      // Arrange
      await favoritesManager.addFavorite('SHIB');
      await favoritesManager.addFavorite('PEPE');

      // Act
      await favoritesManager.removeFavorite('ETH'); // 2番目を削除
      final favorites = await favoritesManager.getFavorites();

      // Assert
      for (var i = 0; i < favorites.length; i++) {
        expect(favorites[i].displayOrder, equals(i));
      }
    });

    test('存在しない通貨を削除してもエラーにならない', () async {
      // Act & Assert
      expect(
        () => favoritesManager.removeFavorite('NONEXISTENT'),
        returnsNormally,
      );
    });
  });

  group('FavoritesManager - ローカルストレージの永続化', () {
    test('追加した通貨が永続化される', () async {
      // Arrange
      const customSymbol = 'SHIB';
      await favoritesManager.addFavorite(customSymbol);

      // Act: 新しいインスタンスを作成
      final newManager = FavoritesManager(prefs);
      final favorites = await newManager.getFavorites();

      // Assert
      expect(favorites.any((f) => f.symbol == customSymbol), isTrue);
    });

    test('削除した通貨が永続化される', () async {
      // Arrange
      const symbolToRemove = 'BTC';
      await favoritesManager.removeFavorite(symbolToRemove);

      // Act: 新しいインスタンスを作成
      final newManager = FavoritesManager(prefs);
      final favorites = await newManager.getFavorites();

      // Assert
      expect(favorites.any((f) => f.symbol == symbolToRemove), isFalse);
    });

    test('並び替えが永続化される', () async {
      // Arrange
      final favorites = await favoritesManager.getFavorites();
      final reordered = favorites.reversed.toList();

      // Act
      await favoritesManager.reorderFavorites(reordered);
      final newManager = FavoritesManager(prefs);
      final loadedFavorites = await newManager.getFavorites();

      // Assert
      expect(loadedFavorites.first.symbol, equals(reordered.first.symbol));
      expect(loadedFavorites.last.symbol, equals(reordered.last.symbol));
    });
  });

  group('FavoritesManager - デフォルト/カスタム判定', () {
    test('isDefaultCurrency はデフォルト通貨に対してtrueを返す', () {
      // Assert
      expect(favoritesManager.isDefaultCurrency('BTC'), isTrue);
      expect(favoritesManager.isDefaultCurrency('ETH'), isTrue);
      expect(favoritesManager.isDefaultCurrency('ADA'), isTrue);
    });

    test('isDefaultCurrency はカスタム通貨に対してfalseを返す', () {
      // Assert
      expect(favoritesManager.isDefaultCurrency('SHIB'), isFalse);
      expect(favoritesManager.isDefaultCurrency('PEPE'), isFalse);
    });

    test('isCustomCurrency はカスタム通貨に対してtrueを返す', () {
      // Assert
      expect(favoritesManager.isCustomCurrency('SHIB'), isTrue);
      expect(favoritesManager.isCustomCurrency('PEPE'), isTrue);
    });

    test('isCustomCurrency はデフォルト通貨に対してfalseを返す', () {
      // Assert
      expect(favoritesManager.isCustomCurrency('BTC'), isFalse);
      expect(favoritesManager.isCustomCurrency('ETH'), isFalse);
    });

    test('大文字小文字を区別しない', () {
      // Assert
      expect(favoritesManager.isDefaultCurrency('btc'), isTrue);
      expect(favoritesManager.isDefaultCurrency('Eth'), isTrue);
      expect(favoritesManager.isCustomCurrency('shib'), isTrue);
    });
  });

  group('FavoritesManager - 並び替え', () {
    test('お気に入りを並び替えできる', () async {
      // Arrange
      final favorites = await favoritesManager.getFavorites();
      final reordered = favorites.reversed.toList();

      // Act
      await favoritesManager.reorderFavorites(reordered);
      final result = await favoritesManager.getFavorites();

      // Assert
      expect(result.first.symbol, equals(reordered.first.symbol));
      expect(result.last.symbol, equals(reordered.last.symbol));
    });

    test('並び替え後の表示順序が正しい', () async {
      // Arrange
      final favorites = await favoritesManager.getFavorites();
      final reordered = favorites.reversed.toList();

      // Act
      await favoritesManager.reorderFavorites(reordered);
      final result = await favoritesManager.getFavorites();

      // Assert
      for (var i = 0; i < result.length; i++) {
        expect(result[i].displayOrder, equals(i));
      }
    });
  });

  group('FavoritesManager - エラーハンドリング', () {
    test('破損したJSONデータがある場合はデフォルト通貨を返す', () async {
      // Arrange: 破損したJSONを保存
      await prefs.setString('favorites_currencies', 'invalid json');

      // Act
      final favorites = await favoritesManager.getFavorites();

      // Assert
      expect(favorites.length, equals(20));
      expect(favorites.every((f) => f.isDefault), isTrue);
    });
  });
}
