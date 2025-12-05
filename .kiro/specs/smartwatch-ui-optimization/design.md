# デザイン文書

## 概要

スマートウォッチ向けUI最適化は、既存のCrypto Watch Flutterアプリケーションの表示問題を解決し、小さな円形画面でも快適に使用できるようにする改善です。主な改善点は以下の通りです：

1. **テキストオーバーフローの防止**: すべてのテキストを画面内に収め、見切れを防止
2. **レイアウトの最適化**: 円形画面に対応した安全領域の確保
3. **ナビゲーションの改善**: 設定アイコンの可視化、大きな更新ボタンの削除
4. **通貨アイコンの表示**: 視覚的な識別性の向上
5. **任意通貨の検索・追加**: デフォルト20種類以外の通貨もサポート

## アーキテクチャ

### レイヤー構成

```
┌─────────────────────────────────────┐
│   Presentation Layer (UI)           │
│  - PriceListScreen (改善)           │
│  - PriceDetailScreen (改善)         │
│  - CurrencySearchScreen (新規)      │
│  - CryptoIcon (既存)                │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│   Domain Layer                      │
│  - CryptoPrice (既存)               │
│  - CurrencySearchResult (新規)      │
│  - FavoritesManager (新規)          │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│   Data Layer                        │
│  - CoinGeckoApiClient (拡張)       │
│  - LocalStorageService (拡張)      │
│  - CacheManager (新規)              │
└─────────────────────────────────────┘
```

### 主要コンポーネント

1. **ResponsiveLayoutBuilder**: 画面サイズに応じたレイアウト調整
2. **SafeAreaCalculator**: 円形画面の安全領域計算
3. **CurrencySearchService**: 通貨検索とサジェスト機能
4. **FavoritesManager**: デフォルト通貨とカスタム通貨の統合管理


## コンポーネントとインターフェース

### 1. ResponsiveLayoutBuilder

画面サイズに応じて動的にレイアウトを調整するビルダーウィジェット。

```dart
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext, ScreenSize) builder;
  
  // 画面サイズを検出してビルダーに渡す
  // ScreenSize: small (< 200px), medium (200-300px), large (> 300px)
}
```

**責務:**
- 画面サイズの検出と分類
- フォントサイズ、パディング、マージンの自動調整
- 円形画面の検出と安全領域の計算

### 2. SafeAreaCalculator

円形画面の安全領域を計算するユーティリティクラス。

```dart
class SafeAreaCalculator {
  static EdgeInsets calculateSafeInsets(Size screenSize, bool isCircular);
  static double getMaxContentWidth(Size screenSize, bool isCircular);
  static bool isInSafeArea(Offset position, Size screenSize);
}
```

**責務:**
- 円形画面の可視領域計算
- 安全なパディング値の提供
- 要素配置の妥当性検証

### 3. CurrencySearchService

通貨検索とサジェスト機能を提供するサービスクラス。

```dart
class CurrencySearchService {
  Future<List<CurrencySearchResult>> searchCurrencies(String query);
  Stream<List<CurrencySearchResult>> getSuggestions(String query);
  Future<void> cacheSearchResults(List<CurrencySearchResult> results);
}
```

**責務:**
- CoinGecko APIからの通貨検索
- リアルタイムサジェスト（300ms以内）
- 検索結果のキャッシング
- デバウンス処理（入力の連続キャンセル）


### 4. FavoritesManager

デフォルト通貨とカスタム通貨を統合管理するマネージャークラス。

```dart
class FavoritesManager {
  static const List<String> defaultCurrencies = [
    'BTC', 'ETH', 'ADA', 'BNB', 'XRP', 'SOL', 'DOT', 'DOGE',
    'AVAX', 'MATIC', 'LINK', 'UNI', 'LTC', 'ATOM', 'XLM',
    'ALGO', 'VET', 'ICP', 'FIL', 'TRX'
  ];
  
  Future<List<String>> getFavorites();
  Future<void> addFavorite(String symbol);
  Future<void> removeFavorite(String symbol);
  bool isDefaultCurrency(String symbol);
  bool isCustomCurrency(String symbol);
}
```

**責務:**
- デフォルト通貨とカスタム通貨の統合リスト管理
- ローカルストレージへの永続化
- お気に入りの追加・削除操作

### 5. CoinGeckoApiClient (拡張)

既存のAPIクライアントを拡張し、任意通貨の検索機能を追加。

```dart
class CoinGeckoApiClient {
  // 既存メソッド
  Future<List<CryptoPrice>> fetchPrices(List<String> symbols);
  
  // 新規メソッド
  Future<List<CurrencySearchResult>> searchCoins(String query, {int limit = 10});
  Future<CryptoPrice> fetchPriceBySymbol(String symbol);
  Future<CoinDetails> getCoinDetails(String coinId);
}
```

**責務:**
- CoinGecko API `/search` エンドポイントの呼び出し
- 任意通貨の価格データ取得
- エラーハンドリングとリトライロジック

### 6. OptimizedTextWidget

テキストオーバーフローを防止する最適化されたテキストウィジェット。

```dart
class OptimizedTextWidget extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int maxLines;
  final TextOverflow overflow;
  final bool autoScale; // 自動フォントサイズ調整
  
  // 画面幅に応じて自動的にテキストを調整
}
```

**責務:**
- テキストの自動省略（...）
- 画面幅に応じたフォントサイズ調整
- 複数行テキストの適切な折り返し

### 7. FontSizeManager

ユーザーのフォントサイズ設定を管理するマネージャークラス。

```dart
enum FontSizeOption { small, normal, large, extraLarge }

class FontSizeManager {
  static const double minFontSize = 12.0;
  static const Map<FontSizeOption, double> scales = {
    FontSizeOption.small: 0.9,
    FontSizeOption.normal: 1.0,
    FontSizeOption.large: 1.1,
    FontSizeOption.extraLarge: 1.2,
  };
  
  Future<FontSizeOption> getFontSizeOption();
  Future<void> setFontSizeOption(FontSizeOption option);
  double getScaledFontSize(double baseSize, FontSizeOption option);
  double clampFontSize(double size); // 最小値を下回らないように調整
}
```

**責務:**
- ユーザーのフォントサイズ設定の保存・読み込み
- ベースフォントサイズのスケーリング
- 最小フォントサイズの保証
- 画面サイズに応じた自動調整


## データモデル

### CurrencySearchResult

通貨検索結果を表すモデル。

```dart
class CurrencySearchResult {
  final String id;           // CoinGecko内部ID (例: "bitcoin")
  final String symbol;       // ティッカーシンボル (例: "BTC")
  final String name;         // 通貨名 (例: "Bitcoin")
  final String? iconUrl;     // アイコンURL
  final int marketCapRank;   // 時価総額ランキング
  
  factory CurrencySearchResult.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### FavoritesCurrency

お気に入り通貨を表すモデル。

```dart
class FavoritesCurrency {
  final String symbol;
  final bool isDefault;      // デフォルト通貨かどうか
  final DateTime addedAt;    // 追加日時
  final int displayOrder;    // 表示順序
  
  factory FavoritesCurrency.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### ScreenSize

画面サイズ情報を表すモデル。

```dart
enum ScreenSizeCategory { small, medium, large }

class ScreenSize {
  final double width;
  final double height;
  final bool isCircular;
  final ScreenSizeCategory category;
  final EdgeInsets safeInsets;
  
  // フォントサイズ、パディング、マージンの推奨値を提供
  double get primaryFontSize;
  double get secondaryFontSize;
  double get iconSize;
  EdgeInsets get defaultPadding;
}
```


## 正確性プロパティ

*プロパティとは、システムのすべての有効な実行において真であるべき特性や動作のことです。本質的には、システムが何をすべきかについての形式的な記述です。プロパティは、人間が読める仕様と機械で検証可能な正確性保証の橋渡しとなります。*

### Property 1: テキストオーバーフロー防止

*任意の*テキスト要素と画面サイズに対して、テキストがビューポートの境界を超えてはならない
**Validates: Requirements 1.1, 1.5**

### Property 2: 長いテキストの省略

*任意の*コンテナ幅を超えるテキストに対して、省略記号（...）が適用され、テキストがコンテナ内に収まる
**Validates: Requirements 1.2**

### Property 3: 最小タップ領域の確保

*任意の*タップ可能な要素（ボタン、アイコン）に対して、タップ領域は最小44x44ピクセルである
**Validates: Requirements 3.3, 12.1**

### Property 4: 円形画面の安全領域

*任意の*重要な情報要素に対して、円形画面の場合は画面中央の安全領域内に配置される
**Validates: Requirements 5.2**

### Property 5: レスポンシブレイアウト

*任意の*画面サイズに対して、レイアウトは利用可能な幅と高さに基づいて適切に調整される
**Validates: Requirements 6.1**

### Property 6: 最小フォントサイズ

*任意の*価格表示要素に対して、フォントサイズは最小14spである
**Validates: Requirements 7.1**

### Property 7: 最小パディング

*任意の*リストアイテムに対して、上下のパディングは最小8ピクセルである
**Validates: Requirements 8.1**


### Property 8: 通貨アイコン取得の統一性

*任意の*通貨（デフォルトまたはカスタム）に対して、アイコンは同じAPI（CryptoCompare）から同じ方法で取得される
**Validates: Requirements 15.8**

### Property 9: 価格データ取得の統一性

*任意の*通貨（デフォルトまたはカスタム）に対して、価格データはCoinGecko APIから取得される
**Validates: Requirements 16.7**

### Property 10: 機能の同等性

*任意の*通貨（デフォルトまたはカスタム）に対して、詳細画面、お気に入り追加、アラート設定などすべての機能が利用可能である
**Validates: Requirements 17.10**

### Property 11: サジェスト応答時間

*任意の*検索クエリに対して、サジェスト結果は300ms以内に表示される
**Validates: Requirements 18.2**

### Property 12: 検索結果のキャッシング

*任意の*検索クエリに対して、同じクエリを2回実行した場合、2回目はキャッシュから取得される
**Validates: Requirements 18.7**


## エラーハンドリング

### 1. ネットワークエラー

**シナリオ**: CoinGecko APIまたはCryptoCompare APIへの接続が失敗

**対応:**
- ユーザーに分かりやすいエラーメッセージを表示
- リトライボタンを提供
- キャッシュされたデータがあれば表示
- オフラインモードへの自動切り替え

### 2. 通貨検索エラー

**シナリオ**: 検索クエリに一致する通貨が見つからない

**対応:**
- 「該当する通貨が見つかりません」メッセージを表示
- 検索のヒントを提供（例：「ティッカーシンボルまたは通貨名で検索してください」）
- 人気通貨の候補を表示

### 3. アイコン取得エラー

**シナリオ**: CryptoCompare APIからアイコンが取得できない

**対応:**
- ティッカーシンボルの頭文字を含むプレースホルダーを表示
- 背景色で視覚的に区別
- エラーをログに記録（ユーザーには表示しない）

### 4. レイアウトオーバーフロー

**シナリオ**: テキストや要素が画面外にはみ出す

**対応:**
- 開発モードでコンソールに警告を出力
- 自動的にテキストを省略または折り返し
- デバッグモードでレイアウト境界を表示

### 5. ローカルストレージエラー

**シナリオ**: お気に入りの保存・読み込みが失敗

**対応:**
- デフォルト通貨リストにフォールバック
- エラーメッセージを表示
- 次回起動時に再試行


## テスト戦略

### ユニットテスト

**対象コンポーネント:**
- SafeAreaCalculator: 円形画面の安全領域計算
- FavoritesManager: お気に入りの追加・削除・取得
- CurrencySearchService: 検索クエリの処理とデバウンス
- OptimizedTextWidget: テキストの省略と折り返し

**テストケース例:**
- SafeAreaCalculator.calculateSafeInsets() が円形画面で適切なインセットを返す
- FavoritesManager.addFavorite() がカスタム通貨を正しく保存する
- CurrencySearchService.searchCurrencies() が空のクエリで空リストを返す
- OptimizedTextWidget が長いテキストを省略記号で切り詰める

### プロパティベーステスト

**使用ライブラリ**: `fake` パッケージ（Dart）

**Property 1: テキストオーバーフロー防止**
```dart
// 任意のテキストと画面幅に対して、テキストが画面外にはみ出さない
test('text never overflows viewport', () {
  final faker = Faker();
  for (int i = 0; i < 100; i++) {
    final text = faker.lorem.sentence();
    final width = faker.randomGenerator.decimal(min: 100, max: 400);
    final widget = OptimizedTextWidget(text: text, maxWidth: width);
    // テキストの実際の幅が maxWidth を超えないことを検証
  }
});
```

**Property 3: 最小タップ領域の確保**
```dart
// 任意のボタンに対して、タップ領域が最小44x44ピクセル
test('all buttons have minimum tap target size', () {
  final buttons = [IconButton(...), ElevatedButton(...), TextButton(...)];
  for (final button in buttons) {
    final size = getTapTargetSize(button);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  }
});
```

**Property 8: 通貨アイコン取得の統一性**
```dart
// デフォルト通貨とカスタム通貨で同じアイコン取得方法
test('all currencies use same icon fetching method', () {
  final defaultCurrency = 'BTC';
  final customCurrency = 'SHIB';
  
  final defaultIconUrl = getIconUrl(defaultCurrency);
  final customIconUrl = getIconUrl(customCurrency);
  
  // 両方とも同じAPIドメインを使用
  expect(defaultIconUrl, contains('cryptocompare.com'));
  expect(customIconUrl, contains('cryptocompare.com'));
});
```


**Property 11: サジェスト応答時間**
```dart
// 任意の検索クエリに対して、300ms以内に結果を返す
test('suggestions return within 300ms', () async {
  final faker = Faker();
  for (int i = 0; i < 100; i++) {
    final query = faker.lorem.word();
    final stopwatch = Stopwatch()..start();
    
    await currencySearchService.getSuggestions(query).first;
    
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(300));
  }
});
```

**Property 12: 検索結果のキャッシング**
```dart
// 同じクエリを2回実行した場合、2回目はキャッシュから取得
test('search results are cached', () async {
  final query = 'bitcoin';
  
  // 1回目: APIから取得
  final stopwatch1 = Stopwatch()..start();
  await currencySearchService.searchCurrencies(query);
  stopwatch1.stop();
  final firstCallTime = stopwatch1.elapsedMilliseconds;
  
  // 2回目: キャッシュから取得
  final stopwatch2 = Stopwatch()..start();
  await currencySearchService.searchCurrencies(query);
  stopwatch2.stop();
  final secondCallTime = stopwatch2.elapsedMilliseconds;
  
  // 2回目は1回目より大幅に速い
  expect(secondCallTime, lessThan(firstCallTime / 2));
});
```

### 統合テスト

**シナリオ1: 通貨検索から追加まで**
1. 通貨検索画面を開く
2. 検索フィールドに「ethereum」と入力
3. サジェストリストが表示される
4. 「Ethereum (ETH)」を選択
5. お気に入りリストに追加される
6. 価格一覧画面にETHが表示される

**シナリオ2: 円形画面でのレイアウト**
1. 円形画面サイズ（200x200）でアプリを起動
2. 価格一覧画面が表示される
3. すべてのテキストが画面内に収まっている
4. 設定アイコンが表示されている
5. 更新ボタンが表示されていない

**シナリオ3: カスタム通貨の機能同等性**
1. カスタム通貨「SHIB」を追加
2. 価格一覧でSHIBをタップ
3. 詳細画面が表示される
4. お気に入りに追加できる
5. アラート設定ができる
6. デフォルト通貨と同じ機能が利用可能


### ウィジェットテスト

**対象ウィジェット:**
- CryptoIcon: アイコンの表示とプレースホルダー
- OptimizedTextWidget: テキストの省略と折り返し
- CurrencySearchScreen: 検索UIとサジェスト表示
- PriceListScreen: レイアウトとナビゲーション

**テストケース例:**
- CryptoIcon がアイコン取得失敗時にプレースホルダーを表示
- OptimizedTextWidget が maxLines を超えるテキストを省略
- CurrencySearchScreen が検索結果0件時にメッセージを表示
- PriceListScreen が設定アイコンを表示し、更新ボタンを表示しない

### パフォーマンステスト

**測定項目:**
- レイアウト計算時間: 100ms以内
- 画面再描画フレームレート: 60FPS維持
- サジェスト応答時間: 300ms以内
- アイコン読み込み時間: キャッシュヒット時50ms以内

**テスト方法:**
- Flutter DevTools のパフォーマンスプロファイラを使用
- 実機（スマートウォッチ）でのベンチマーク
- 大量データ（100件以上の通貨）での動作確認

### ビジュアルリグレッションテスト

**対象画面:**
- 価格一覧画面（円形・正方形）
- 価格詳細画面（円形・正方形）
- 通貨検索画面
- 設定画面

**テスト方法:**
- Golden テストを使用してスクリーンショットを比較
- 異なる画面サイズでのスナップショット
- ダークテーマでの表示確認


## 実装の詳細

### 1. テキストオーバーフロー防止

**実装方針:**
- すべてのTextウィジェットに `overflow: TextOverflow.ellipsis` を設定
- `maxLines` プロパティで行数を制限
- `FittedBox` を使用して自動スケーリング（必要に応じて）

**コード例:**
```dart
Text(
  cryptoPrice.name,
  style: TextStyle(fontSize: 16),
  overflow: TextOverflow.ellipsis,
  maxLines: 1,
)
```

### 2. 円形画面の安全領域

**実装方針:**
- `MediaQuery` で画面サイズを取得
- 円形画面の場合、中央70%を安全領域とする
- `SafeArea` ウィジェットと組み合わせて使用

**コード例:**
```dart
class SafeAreaCalculator {
  static EdgeInsets calculateSafeInsets(Size screenSize, bool isCircular) {
    if (!isCircular) {
      return EdgeInsets.all(8.0);
    }
    
    // 円形画面の場合、角を避けるため大きめのインセット
    final radius = screenSize.width / 2;
    final safeRadius = radius * 0.7;
    final inset = radius - safeRadius;
    
    return EdgeInsets.all(inset);
  }
}
```

### 3. 更新ボタンの削除

**実装方針:**
- FloatingActionButton を削除
- プルトゥリフレッシュ機能を強化
- 必要に応じて上部ナビゲーションバーに小さなアイコンを追加

**コード例:**
```dart
RefreshIndicator(
  onRefresh: () async {
    await priceListBloc.refreshPrices();
  },
  child: ListView.builder(...),
)
```

### 4. 通貨検索とサジェスト

**実装方針:**
- `StreamBuilder` でリアルタイムサジェストを実装
- `debounce` で連続入力をキャンセル（300ms）
- `FutureBuilder` で検索結果を表示

**コード例:**
```dart
class CurrencySearchService {
  final _searchController = StreamController<String>();
  
  Stream<List<CurrencySearchResult>> getSuggestions(String query) {
    return _searchController.stream
      .debounceTime(Duration(milliseconds: 300))
      .distinct()
      .switchMap((q) => _performSearch(q));
  }
  
  Future<List<CurrencySearchResult>> _performSearch(String query) async {
    // キャッシュチェック
    if (_cache.containsKey(query)) {
      return _cache[query]!;
    }
    
    // CoinGecko API呼び出し
    final results = await _apiClient.searchCoins(query);
    _cache[query] = results;
    return results;
  }
}
```


### 5. お気に入り管理

**実装方針:**
- `shared_preferences` でローカルストレージに保存
- デフォルト通貨とカスタム通貨を統合リストで管理
- JSON形式でシリアライズ

**コード例:**
```dart
class FavoritesManager {
  static const String _key = 'favorite_currencies';
  static const List<String> defaultCurrencies = [
    'BTC', 'ETH', 'ADA', 'BNB', 'XRP', 'SOL', 'DOT', 'DOGE',
    'AVAX', 'MATIC', 'LINK', 'UNI', 'LTC', 'ATOM', 'XLM',
    'ALGO', 'VET', 'ICP', 'FIL', 'TRX'
  ];
  
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    
    if (json == null) {
      return List.from(defaultCurrencies);
    }
    
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.cast<String>();
  }
  
  Future<void> addFavorite(String symbol) async {
    final favorites = await getFavorites();
    if (!favorites.contains(symbol)) {
      favorites.add(symbol);
      await _saveFavorites(favorites);
    }
  }
  
  Future<void> removeFavorite(String symbol) async {
    final favorites = await getFavorites();
    favorites.remove(symbol);
    await _saveFavorites(favorites);
  }
  
  Future<void> _saveFavorites(List<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(favorites));
  }
}
```

### 6. レスポンシブレイアウト

**実装方針:**
- `LayoutBuilder` で利用可能なサイズを取得
- 画面サイズに応じてフォントサイズ、パディング、アイコンサイズを調整
- `MediaQuery.of(context).size` で画面サイズを取得

**コード例:**
```dart
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext, ScreenSize) builder;
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = ScreenSize.fromConstraints(constraints);
        return builder(context, screenSize);
      },
    );
  }
}

class ScreenSize {
  final double width;
  final double height;
  final ScreenSizeCategory category;
  
  factory ScreenSize.fromConstraints(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    
    ScreenSizeCategory category;
    if (width < 200) {
      category = ScreenSizeCategory.small;
    } else if (width < 300) {
      category = ScreenSizeCategory.medium;
    } else {
      category = ScreenSizeCategory.large;
    }
    
    return ScreenSize(width, height, category);
  }
  
  double get primaryFontSize {
    switch (category) {
      case ScreenSizeCategory.small:
        return 14.0;
      case ScreenSizeCategory.medium:
        return 16.0;
      case ScreenSizeCategory.large:
        return 18.0;
    }
  }
  
  double get iconSize {
    switch (category) {
      case ScreenSizeCategory.small:
        return 28.0;
      case ScreenSizeCategory.medium:
        return 32.0;
      case ScreenSizeCategory.large:
        return 40.0;
    }
  }
}
```

### 7. ユーザーによるフォントサイズ調整

**実装方針:**
- 設定画面でフォントサイズオプションを選択
- `shared_preferences` で設定を保存
- すべてのTextウィジェットでスケーリングを適用
- 最小フォントサイズ（12sp）を保証

**コード例:**
```dart
class FontSizeManager {
  static const String _key = 'font_size_option';
  static const double minFontSize = 12.0;
  
  static const Map<FontSizeOption, double> scales = {
    FontSizeOption.small: 0.9,
    FontSizeOption.normal: 1.0,
    FontSizeOption.large: 1.1,
    FontSizeOption.extraLarge: 1.2,
  };
  
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
  
  Future<void> setFontSizeOption(FontSizeOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, option.toString());
  }
  
  double getScaledFontSize(double baseSize, FontSizeOption option) {
    final scaled = baseSize * scales[option]!;
    return clampFontSize(scaled);
  }
  
  double clampFontSize(double size) {
    return size < minFontSize ? minFontSize : size;
  }
}

// 使用例
class ScaledText extends StatelessWidget {
  final String text;
  final double baseFontSize;
  final TextStyle? style;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FontSizeOption>(
      future: FontSizeManager().getFontSizeOption(),
      builder: (context, snapshot) {
        final option = snapshot.data ?? FontSizeOption.normal;
        final fontSize = FontSizeManager().getScaledFontSize(
          baseFontSize,
          option,
        );
        
        return Text(
          text,
          style: (style ?? TextStyle()).copyWith(fontSize: fontSize),
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
```


## パフォーマンス最適化

### 1. アイコンキャッシング

**戦略:**
- `cached_network_image` パッケージを使用（既存実装）
- メモリキャッシュとディスクキャッシュの両方を活用
- キャッシュサイズの制限（最大200x200ピクセル）

### 2. 検索結果キャッシング

**戦略:**
- インメモリキャッシュ（Map）で検索結果を保存
- TTL（Time To Live）を5分に設定
- LRU（Least Recently Used）アルゴリズムで古いエントリを削除

**実装:**
```dart
class SearchCache {
  final Map<String, CacheEntry> _cache = {};
  final Duration _ttl = Duration(minutes: 5);
  final int _maxSize = 50;
  
  List<CurrencySearchResult>? get(String query) {
    final entry = _cache[query];
    if (entry == null) return null;
    
    if (DateTime.now().difference(entry.timestamp) > _ttl) {
      _cache.remove(query);
      return null;
    }
    
    return entry.results;
  }
  
  void put(String query, List<CurrencySearchResult> results) {
    if (_cache.length >= _maxSize) {
      _evictOldest();
    }
    
    _cache[query] = CacheEntry(results, DateTime.now());
  }
  
  void _evictOldest() {
    String? oldestKey;
    DateTime? oldestTime;
    
    _cache.forEach((key, entry) {
      if (oldestTime == null || entry.timestamp.isBefore(oldestTime!)) {
        oldestKey = key;
        oldestTime = entry.timestamp;
      }
    });
    
    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }
}
```

### 3. レイアウト計算の最適化

**戦略:**
- `const` コンストラクタを可能な限り使用
- 不要な再ビルドを避けるため `Key` を適切に使用
- `ListView.builder` で遅延レンダリング

### 4. API呼び出しの最適化

**戦略:**
- デバウンス処理で連続リクエストを防止
- バッチリクエストで複数通貨の価格を一度に取得
- エラー時のリトライロジック（指数バックオフ）


## セキュリティ考慮事項

### 1. API キーの保護

- CoinGecko API キーは環境変数で管理
- ソースコードにハードコードしない
- バックエンドAPIを経由して取得（フロントエンドに露出しない）

### 2. ローカルストレージのセキュリティ

- お気に入りリストは暗号化せずに保存（機密情報ではない）
- `shared_preferences` の標準的なセキュリティ機能を使用
- ユーザーデータの最小化（必要最小限の情報のみ保存）

### 3. 外部API通信

- HTTPS通信を強制
- SSL証明書の検証
- タイムアウト設定（5秒）でDoS攻撃を防止

### 4. 入力検証

- 検索クエリの長さ制限（最大100文字）
- 特殊文字のエスケープ
- SQLインジェクション対策（該当なし：NoSQL使用）

## 依存関係

### 新規追加パッケージ

```yaml
dependencies:
  # 既存
  cached_network_image: ^3.3.0
  equatable: ^2.0.5
  
  # 新規追加
  rxdart: ^0.27.7              # ストリーム処理とデバウンス
  shared_preferences: ^2.2.2   # ローカルストレージ
  http: ^1.1.0                 # HTTP通信
```

### 既存パッケージの活用

- `cached_network_image`: アイコンキャッシング（既存）
- `equatable`: データモデルの比較（既存）
- Flutter標準ウィジェット: `LayoutBuilder`, `MediaQuery`, `RefreshIndicator`


## マイグレーション戦略

### フェーズ1: レイアウト最適化（優先度：高）

**対象:**
- テキストオーバーフロー防止
- 円形画面対応
- 設定アイコンの可視化
- 更新ボタンの削除

**影響範囲:**
- PriceListScreen
- PriceDetailScreen
- ナビゲーションバー

**リスク:** 低（既存機能への影響は最小限）

### フェーズ2: 通貨アイコン表示（優先度：中）

**対象:**
- CryptoIcon ウィジェットの統合
- アイコンキャッシングの最適化

**影響範囲:**
- PriceListScreen
- CurrencySearchScreen

**リスク:** 低（既存のCryptoIconウィジェットを活用）

### フェーズ3: 通貨検索機能（優先度：中）

**対象:**
- CurrencySearchScreen の新規作成
- CoinGecko API 検索エンドポイントの統合
- サジェスト機能の実装

**影響範囲:**
- 新規画面追加
- FavoritesManager の拡張

**リスク:** 中（新規機能のため、十分なテストが必要）

### フェーズ4: カスタム通貨管理（優先度：低）

**対象:**
- FavoritesManager の完全実装
- ローカルストレージの統合
- デフォルト通貨とカスタム通貨の統一管理

**影響範囲:**
- すべての画面（お気に入り機能を使用する箇所）

**リスク:** 中（既存のお気に入り機能との互換性確保が必要）

### ロールバック計画

各フェーズで問題が発生した場合：
1. 機能フラグで新機能を無効化
2. 前バージョンにロールバック
3. 問題を修正後、再デプロイ


## 今後の拡張性

### 1. 多言語対応

現在は日本語のみだが、将来的に以下の言語をサポート可能：
- 英語
- フランス語
- イタリア語
- ドイツ語

**必要な変更:**
- `flutter_localizations` パッケージの追加
- ARB ファイルでの翻訳管理
- 通貨名の多言語対応

### 2. カスタムテーマ

ユーザーが色やフォントをカスタマイズできる機能：
- ライトテーマ / ダークテーマの切り替え
- アクセントカラーの選択
- フォントサイズの調整

### 3. ユーザーによるフォントサイズ調整（実装予定）

ユーザーが設定画面からフォントサイズを調整できる機能：
- 小（90%）、標準（100%）、大（110%）、特大（120%）の4段階
- すべてのテキストに適用
- 画面からはみ出さないように自動調整
- 最小フォントサイズ（12sp）を下回らない
- 設定はローカルストレージに保存

**実装方針:**
```dart
class FontSizeManager {
  static const double baseSize = 1.0;
  static const Map<FontSizeOption, double> scales = {
    FontSizeOption.small: 0.9,
    FontSizeOption.normal: 1.0,
    FontSizeOption.large: 1.1,
    FontSizeOption.extraLarge: 1.2,
  };
  
  Future<FontSizeOption> getFontSizeOption();
  Future<void> setFontSizeOption(FontSizeOption option);
  double getScaledFontSize(double baseSize, FontSizeOption option);
}
```

### 4. 高度な検索フィルター

通貨検索に以下のフィルターを追加：
- 時価総額範囲
- 24時間変動率範囲
- カテゴリー（DeFi、NFT、Memeなど）

### 5. オフラインモード

ネットワーク接続がない場合でも基本機能を提供：
- キャッシュされた価格データの表示
- お気に入りの管理
- 再接続時の自動同期

### 6. ウィジェット対応

ホーム画面ウィジェットで価格を表示：
- 小サイズ: 1通貨の価格
- 中サイズ: 3通貨の価格
- 大サイズ: 5通貨の価格とミニチャート

## まとめ

このデザイン文書は、スマートウォッチ向けUI最適化の技術的な実装方針を定義しています。主な改善点は以下の通りです：

1. **レイアウト最適化**: テキストオーバーフロー防止、円形画面対応
2. **ナビゲーション改善**: 設定アイコンの可視化、更新ボタンの削除
3. **通貨管理の拡張**: 任意通貨の検索・追加、デフォルトとカスタムの統一管理
4. **パフォーマンス**: キャッシング、デバウンス、レスポンシブレイアウト
5. **テスト**: ユニット、プロパティベース、統合、ウィジェットテスト

実装は4つのフェーズに分けて段階的に進め、各フェーズでテストと検証を行います。
