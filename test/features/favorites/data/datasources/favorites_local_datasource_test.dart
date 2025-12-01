import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/features/favorites/data/datasources/favorites_local_datasource.dart';
import 'package:crypto_watch/features/favorites/data/models/favorite_model.dart';
import 'package:crypto_watch/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FavoritesLocalDataSourceImpl dataSource;
  late LocalStorage localStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();
    localStorage = LocalStorageImpl(sharedPreferences: sharedPreferences);
    dataSource = FavoritesLocalDataSourceImpl(localStorage: localStorage);
  });

  group('FavoritesLocalDataSource', () {
    group('Property 2: お気に入りの順序保持', () {
      test(
        '**Feature: crypto-watch-frontend, Property 2: お気に入りの順序保持** - '
        '**Validates: Requirements 11.3, 11.4** - '
        '並び替え操作後に保存し再読み込みした場合、順序は保持されるべき',
        () async {
          // Property-based test: 様々な順序のお気に入りリストで検証
          for (var testCase = 0; testCase < 50; testCase++) {
            // テストケースごとにストレージをクリア
            await localStorage.clear();

            // ランダムな順序のお気に入りリストを生成
            final originalFavorites = _generateFavorites(testCase);

            // 保存
            await dataSource.reorderFavorites(originalFavorites);

            // 再読み込み
            final loadedFavorites = await dataSource.getFavorites();

            // 順序が保持されていることを検証
            expect(loadedFavorites.length, originalFavorites.length,
                reason: 'リストの長さが一致すべき');

            for (var i = 0; i < originalFavorites.length; i++) {
              expect(loadedFavorites[i].symbol, originalFavorites[i].symbol,
                  reason: '位置 $i のシンボルが一致すべき');
              expect(loadedFavorites[i].order, i,
                  reason: '位置 $i の順序が正しく設定されるべき');
            }
          }
        },
      );
    });

    group('addFavorite', () {
      test('お気に入りを追加できる', () async {
        final favorite = FavoriteModel(
          symbol: 'BTC',
          order: 0,
          addedAt: DateTime.now(),
        );

        await dataSource.addFavorite(favorite);
        final favorites = await dataSource.getFavorites();

        expect(favorites.length, 1);
        expect(favorites.first.symbol, 'BTC');
      });

      test('重複したシンボルは追加されない', () async {
        final favorite1 = FavoriteModel(
          symbol: 'BTC',
          order: 0,
          addedAt: DateTime.now(),
        );
        final favorite2 = FavoriteModel(
          symbol: 'BTC',
          order: 1,
          addedAt: DateTime.now(),
        );

        await dataSource.addFavorite(favorite1);
        await dataSource.addFavorite(favorite2);
        final favorites = await dataSource.getFavorites();

        expect(favorites.length, 1);
      });
    });

    group('removeFavorite', () {
      test('お気に入りを削除できる', () async {
        final favorite1 = FavoriteModel(
          symbol: 'BTC',
          order: 0,
          addedAt: DateTime.now(),
        );
        final favorite2 = FavoriteModel(
          symbol: 'ETH',
          order: 1,
          addedAt: DateTime.now(),
        );

        await dataSource.addFavorite(favorite1);
        await dataSource.addFavorite(favorite2);
        await dataSource.removeFavorite('BTC');

        final favorites = await dataSource.getFavorites();
        expect(favorites.length, 1);
        expect(favorites.first.symbol, 'ETH');
        expect(favorites.first.order, 0); // 順序が再調整される
      });
    });

    group('reorderFavorites', () {
      test('お気に入りの順序を変更できる', () async {
        final favorites = [
          FavoriteModel(symbol: 'BTC', order: 0, addedAt: DateTime.now()),
          FavoriteModel(symbol: 'ETH', order: 1, addedAt: DateTime.now()),
          FavoriteModel(symbol: 'ADA', order: 2, addedAt: DateTime.now()),
        ];

        await dataSource.reorderFavorites(favorites);

        // 順序を入れ替え
        final reordered = [favorites[2], favorites[0], favorites[1]];
        await dataSource.reorderFavorites(reordered);

        final loaded = await dataSource.getFavorites();
        expect(loaded[0].symbol, 'ADA');
        expect(loaded[1].symbol, 'BTC');
        expect(loaded[2].symbol, 'ETH');
      });
    });

    group('isFavorite', () {
      test('お気に入りに存在するシンボルはtrueを返す', () async {
        final favorite = FavoriteModel(
          symbol: 'BTC',
          order: 0,
          addedAt: DateTime.now(),
        );

        await dataSource.addFavorite(favorite);
        final result = await dataSource.isFavorite('BTC');

        expect(result, isTrue);
      });

      test('お気に入りに存在しないシンボルはfalseを返す', () async {
        final result = await dataSource.isFavorite('BTC');
        expect(result, isFalse);
      });
    });

    group('getFavorites', () {
      test('空のリストを返す（初期状態）', () async {
        final favorites = await dataSource.getFavorites();
        expect(favorites, isEmpty);
      });

      test('お気に入りを順序通りに返す', () async {
        final favorites = [
          FavoriteModel(symbol: 'BTC', order: 0, addedAt: DateTime.now()),
          FavoriteModel(symbol: 'ETH', order: 1, addedAt: DateTime.now()),
          FavoriteModel(symbol: 'ADA', order: 2, addedAt: DateTime.now()),
        ];

        for (final fav in favorites) {
          await dataSource.addFavorite(fav);
        }

        final loaded = await dataSource.getFavorites();
        expect(loaded.length, 3);
        expect(loaded[0].symbol, 'BTC');
        expect(loaded[1].symbol, 'ETH');
        expect(loaded[2].symbol, 'ADA');
      });
    });
  });
}

/// テスト用のお気に入りリストを生成
List<FavoriteModel> _generateFavorites(int seed) {
  final symbols = ['BTC', 'ETH', 'ADA', 'BNB', 'XRP', 'SOL', 'DOT', 'DOGE'];
  final count = (seed % 5) + 3; // 3-7個のお気に入り

  final favorites = <FavoriteModel>[];
  for (var i = 0; i < count; i++) {
    final symbolIndex = (seed + i) % symbols.length;
    favorites.add(FavoriteModel(
      symbol: symbols[symbolIndex],
      order: i,
      addedAt: DateTime.now().subtract(Duration(days: i)),
    ));
  }

  return favorites;
}
