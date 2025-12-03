# 設計書

## 概要

価格一覧画面の改善により、ユーザーがより多くの情報を効率的に確認し、お気に入り管理をより直感的に行えるようにします。この設計は、既存のCrypto Watch Flutterアプリケーションのクリーンアーキテクチャパターンに従い、以下の主要機能を追加します：

- 通貨アイコンの表示
- 表示密度の調整（標準/コンパクト/最大）
- 長押しによるお気に入り追加/削除
- ドラッグ&ドロップによる並び替え
- お気に入り状態の視覚的表示

## アーキテクチャ

### レイヤー構成

既存のクリーンアーキテクチャパターンを維持：

```
presentation/ (UI層)
  ├── widgets/
  │   ├── price_list_item.dart (拡張)
  │   ├── crypto_icon.dart (新規)
  │   └── reorderable_price_list.dart (新規)
  ├── bloc/
  │   └── price_list_bloc.dart (拡張)
  └── pages/
      └── price_list_page.dart (拡張)

domain/ (ビジネスロジック層)
  ├── entities/
  │   └── display_density.dart (新規)
  └── usecases/
      └── (既存のusecasesを使用)

data/ (データ層)
  └── datasources/
      └── (既存のdatasourcesを使用)

core/
  ├── storage/
  │   └── local_storage.dart (既存)
  └── constants/
      └── storage_keys.dart (拡張)
```

### 依存関係

既存の依存関係に加えて：
- `cached_network_image`: 通貨アイコンのキャッシング
- 既存の`flutter_bloc`: 状態管理
- 既存の`shared_preferences`: ローカルストレージ

## コンポーネントとインターフェース

### 1. 表示密度エンティティ

```dart
enum DisplayDensity {
  standard,  // 3-5銘柄/画面
  compact,   // 6-8銘柄/画面
  maximum,   // 9-12銘柄/画面
}

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
}
```

### 2. 拡張されたPriceListItem

```dart
class PriceListItem extends StatelessWidget {
  final CryptoPrice price;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isFavorite;
  final DisplayDensity density;
  final String displayCurrency;
  final bool isReorderMode;
  
  // アイコンURL生成ロジック
  String _getIconUrl(String symbol) {
    return 'https://cryptoicons.org/api/icon/${symbol.toLowerCase()}/200';
  }
}
```

### 3. CryptoIcon ウィジェット

```dart
class CryptoIcon extends StatelessWidget {
  final String symbol;
  final double size;
  
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _getIconUrl(symbol),
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildPlaceholder(),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
  
  Widget _buildPlaceholder() {
    // ティッカーシンボルの頭文字を表示
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          symbol[0],
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
```

### 4. ReorderablePriceList ウィジェット

```dart
class ReorderablePriceList extends StatelessWidget {
  final List<CryptoPrice> prices;
  final List<String> favoriteSymbols;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(CryptoPrice) onTap;
  final Function(CryptoPrice) onLongPress;
  final DisplayDensity density;
  
  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: prices.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final price = prices[index];
        final isFavorite = favoriteSymbols.contains(price.symbol);
        
        return PriceListItem(
          key: ValueKey(price.symbol),
          price: price,
          isFavorite: isFavorite,
          density: density,
          onTap: () => onTap(price),
          onLongPress: () => onLongPress(price),
        );
      },
    );
  }
}
```

### 5. 拡張されたPriceListBloc

既存のBlocに新しいイベントと状態を追加：

```dart
// 新しいイベント
class ToggleReorderModeEvent extends PriceListEvent {}
class ReorderPricesEvent extends PriceListEvent {
  final int oldIndex;
  final int newIndex;
}

// 新しい状態プロパティ
class PriceListLoaded extends PriceListState {
  final List<CryptoPrice> prices;
  final bool isReorderMode;  // 新規
  final List<String> customOrder;  // 新規
}
```

### 6. 設定の拡張

既存のSettingsエンティティに表示密度を追加：

```dart
class Settings {
  final DisplayCurrency displayCurrency;
  final DisplayDensity displayDensity;  // 新規
  // ... 既存のフィールド
}
```

## データモデル

### ストレージキー

```dart
class StorageKeys {
  static const String displayDensity = 'display_density';
  static const String priceListOrder = 'price_list_order';
  // 既存: favorites, settings, etc.
}
```

### データ永続化

1. **表示密度**: `SharedPreferences`に文字列として保存
2. **並び順**: シンボルのリストをJSON配列として保存
3. **お気に入り**: 既存のFavoritesLocalDataSourceを使用

## 正確性プロパティ

*プロパティとは、システムのすべての有効な実行において真であるべき特性または動作のことです。本質的には、システムが何をすべきかについての形式的な記述です。プロパティは、人間が読める仕様と機械で検証可能な正確性保証との橋渡しとなります。*

### プロパティ1: アイコン表示の一貫性

*すべての*価格リストアイテムについて、通貨アイコンが表示されるか、アイコンが利用できない場合はプレースホルダーが表示される必要があります。

**検証: 要件 1.1, 1.2, 1.6**

### プロパティ2: 表示密度の制約

*すべての*表示密度設定について、画面に表示される銘柄数は指定された範囲内（標準: 3-5、コンパクト: 6-8、最大: 9-12）である必要があります。

**検証: 要件 2.3, 2.4, 2.5**

### プロパティ3: お気に入り状態の同期

*すべての*お気に入り追加/削除操作について、UIの表示状態とローカルストレージの状態が一致している必要があります。

**検証: 要件 3.5, 3.7, 3.8**

### プロパティ4: 並び替えの永続性

*すべての*並び替え操作について、アプリを再起動した後も同じ順序が維持される必要があります。

**検証: 要件 8.5, 8.6, 9.3**

### プロパティ5: 長押し操作の応答性

*すべての*長押し操作について、500ms以内に触覚フィードバックが提供される必要があります。

**検証: 要件 3.1, 6.3**

### プロパティ6: 表示要素の最小サイズ

*すべての*表示密度について、タップ可能な要素は最小44x44ポイントのタップ領域を維持する必要があります。

**検証: 要件 7.4**

### プロパティ7: アイコンキャッシュの効率性

*すべての*通貨アイコンについて、一度読み込まれたアイコンは再度ネットワークから取得されることなくキャッシュから表示される必要があります。

**検証: 要件 1.7, 6.2**

### プロパティ8: 並び替え中の操作制限

*すべての*並び替えモード中の操作について、通常のタップ操作（詳細画面への遷移）は無効化される必要があります。

**検証: 要件 8.7, 8.8**

### プロパティ9: ストレージ操作のエラーハンドリング

*すべての*ストレージ操作の失敗について、システムはデフォルト値を使用して動作を継続する必要があります。

**検証: 要件 9.5**

### プロパティ10: 表示密度変更時のレイアウト調整

*すべての*表示密度変更について、アイテムの高さ、アイコンサイズ、フォントサイズが適切に調整される必要があります。

**検証: 要件 2.6, 2.8, 5.1, 5.2, 5.3**

## エラーハンドリング

### エラーケース

1. **アイコン読み込み失敗**
   - プレースホルダーを表示
   - エラーログを記録
   - ユーザーには通知しない（非クリティカル）

2. **ストレージ操作失敗**
   - デフォルト値を使用
   - エラーメッセージを表示（クリティカルな場合）
   - 操作を再試行可能にする

3. **並び替え操作失敗**
   - 元の順序に戻す
   - エラーメッセージを表示
   - ユーザーに再試行を促す

4. **お気に入り操作失敗**
   - UI状態を元に戻す
   - エラーメッセージを表示
   - 自動的に再試行

### エラーリカバリー戦略

```dart
class ErrorRecoveryStrategy {
  // アイコン読み込みエラー: プレースホルダー表示
  static Widget handleIconError(String symbol, double size) {
    return CryptoIconPlaceholder(symbol: symbol, size: size);
  }
  
  // ストレージエラー: デフォルト値使用
  static DisplayDensity handleDensityLoadError() {
    return DisplayDensity.standard;
  }
  
  // 並び替えエラー: ロールバック
  static List<String> handleReorderError(List<String> originalOrder) {
    return List.from(originalOrder);
  }
}
```

## テスト戦略

### ユニットテスト

1. **DisplayDensityConfig**
   - 各密度設定の値が正しいことを確認
   - 密度に応じた計算が正しいことを確認

2. **CryptoIcon**
   - アイコンURL生成ロジック
   - プレースホルダー表示ロジック

3. **PriceListBloc**
   - 並び替えイベントの処理
   - 並び替えモードの切り替え
   - カスタム順序の保存と読み込み

4. **LocalStorage**
   - 表示密度の保存と読み込み
   - 並び順の保存と読み込み

### プロパティベーステスト

このプロジェクトではDart/Flutter用のプロパティベーステストライブラリとして**test**パッケージと**faker**パッケージを使用します。

各プロパティベーステストは最低100回の反復を実行するように設定します。

1. **プロパティ1: アイコン表示の一貫性**
   ```dart
   // **Feature: price-list-improvements, Property 1: アイコン表示の一貫性**
   test('すべての価格アイテムにアイコンまたはプレースホルダーが表示される', () {
     // ランダムな通貨リストを生成
     // 各アイテムにアイコンまたはプレースホルダーが存在することを確認
   });
   ```

2. **プロパティ2: 表示密度の制約**
   ```dart
   // **Feature: price-list-improvements, Property 2: 表示密度の制約**
   test('表示密度に応じて正しい範囲の銘柄数が表示される', () {
     // 各表示密度について
     // 画面サイズとアイテム高さから計算される銘柄数が範囲内であることを確認
   });
   ```

3. **プロパティ3: お気に入り状態の同期**
   ```dart
   // **Feature: price-list-improvements, Property 3: お気に入り状態の同期**
   test('お気に入り操作後、UIとストレージの状態が一致する', () {
     // ランダムなお気に入り追加/削除操作を実行
     // UIの表示状態とストレージの状態が一致することを確認
   });
   ```

4. **プロパティ4: 並び替えの永続性**
   ```dart
   // **Feature: price-list-improvements, Property 4: 並び替えの永続性**
   test('並び替え後、再起動しても順序が維持される', () {
     // ランダムな並び替え操作を実行
     // ストレージに保存
     // 読み込み後、同じ順序であることを確認
   });
   ```

5. **プロパティ7: アイコンキャッシュの効率性**
   ```dart
   // **Feature: price-list-improvements, Property 7: アイコンキャッシュの効率性**
   test('アイコンが一度読み込まれたらキャッシュから取得される', () {
     // ランダムな通貨シンボルを生成
     // 初回読み込み後、2回目はキャッシュから取得されることを確認
   });
   ```

6. **プロパティ10: 表示密度変更時のレイアウト調整**
   ```dart
   // **Feature: price-list-improvements, Property 10: 表示密度変更時のレイアウト調整**
   test('表示密度変更時、すべての要素が適切にスケールされる', () {
     // 各表示密度について
     // アイテム高さ、アイコンサイズ、フォントサイズが期待値と一致することを確認
   });
   ```

### ウィジェットテスト

1. **PriceListItem**
   - 各表示密度での表示確認
   - お気に入りアイコンの表示/非表示
   - 長押し操作の動作確認

2. **CryptoIcon**
   - アイコン表示の確認
   - プレースホルダー表示の確認
   - 異なるサイズでの表示確認

3. **ReorderablePriceList**
   - ドラッグ&ドロップ操作の確認
   - 並び替えモードの切り替え確認

### 統合テスト

1. **価格一覧画面の完全なフロー**
   - 表示密度の変更
   - お気に入りの追加/削除
   - 並び替え操作
   - アプリ再起動後の状態確認

2. **パフォーマンステスト**
   - 最大表示密度での60FPS維持
   - スクロールパフォーマンス
   - 長押し操作の応答時間

## 実装の詳細

### 表示密度の実装

```dart
class DisplayDensityHelper {
  static DisplayDensityConfig getConfig(DisplayDensity density) {
    switch (density) {
      case DisplayDensity.standard:
        return const DisplayDensityConfig(
          density: DisplayDensity.standard,
          itemHeight: 80.0,
          iconSize: 40.0,
          fontSize: 18.0,
          padding: 16.0,
        );
      case DisplayDensity.compact:
        return const DisplayDensityConfig(
          density: DisplayDensity.compact,
          itemHeight: 60.0,
          iconSize: 32.0,
          fontSize: 16.0,
          padding: 12.0,
        );
      case DisplayDensity.maximum:
        return const DisplayDensityConfig(
          density: DisplayDensity.maximum,
          itemHeight: 48.0,
          iconSize: 32.0,
          fontSize: 14.0,
          padding: 8.0,
        );
    }
  }
  
  static int calculateVisibleItems(
    double screenHeight,
    DisplayDensity density,
  ) {
    final config = getConfig(density);
    final appBarHeight = 56.0;
    final availableHeight = screenHeight - appBarHeight;
    return (availableHeight / config.itemHeight).floor();
  }
}
```

### 長押し操作の実装

```dart
class PriceListItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isReorderMode ? null : onTap,
      onLongPress: () {
        HapticFeedback.mediumImpact();  // 触覚フィードバック
        _showContextMenu(context);
      },
      child: _buildContent(),
    );
  }
  
  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isFavorite ? Icons.star : Icons.star_border),
              title: Text(
                isFavorite ? 'お気に入りから削除' : 'お気に入りに追加',
              ),
              onTap: () {
                Navigator.pop(context);
                onLongPress?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### 並び替えの実装

```dart
class PriceListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PriceListBloc, PriceListState>(
      builder: (context, state) {
        if (state is PriceListLoaded) {
          final orderedPrices = _applyCustomOrder(
            state.prices,
            state.customOrder,
          );
          
          return ReorderableListView.builder(
            itemCount: orderedPrices.length,
            onReorder: (oldIndex, newIndex) {
              context.read<PriceListBloc>().add(
                ReorderPricesEvent(
                  oldIndex: oldIndex,
                  newIndex: newIndex,
                ),
              );
            },
            itemBuilder: (context, index) {
              return PriceListItem(
                key: ValueKey(orderedPrices[index].symbol),
                price: orderedPrices[index],
                // ...
              );
            },
          );
        }
        // ...
      },
    );
  }
  
  List<CryptoPrice> _applyCustomOrder(
    List<CryptoPrice> prices,
    List<String> customOrder,
  ) {
    if (customOrder.isEmpty) return prices;
    
    final priceMap = {for (var p in prices) p.symbol: p};
    final ordered = <CryptoPrice>[];
    
    // カスタム順序に従って並べる
    for (final symbol in customOrder) {
      if (priceMap.containsKey(symbol)) {
        ordered.add(priceMap[symbol]!);
        priceMap.remove(symbol);
      }
    }
    
    // 残りを追加
    ordered.addAll(priceMap.values);
    
    return ordered;
  }
}
```

### アイコンキャッシング

```dart
class CryptoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _getIconUrl(symbol),
      placeholder: (context, url) => _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      width: size,
      height: size,
      fit: BoxFit.cover,
      memCacheWidth: (size * 2).toInt(),  // Retina対応
      memCacheHeight: (size * 2).toInt(),
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
  
  String _getIconUrl(String symbol) {
    // 複数のアイコンプロバイダーをフォールバック
    return 'https://cryptoicons.org/api/icon/${symbol.toLowerCase()}/200';
  }
}
```

## パフォーマンス最適化

### リストのパフォーマンス

1. **itemExtent の使用**
   ```dart
   ListView.builder(
     itemExtent: config.itemHeight,  // 固定高さを指定
     // ...
   );
   ```

2. **キーの適切な使用**
   ```dart
   PriceListItem(
     key: ValueKey(price.symbol),  // 一意のキー
     // ...
   );
   ```

3. **不要な再構築の防止**
   ```dart
   class PriceListItem extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       // const コンストラクタを可能な限り使用
       return const SizedBox(...);
     }
   }
   ```

### アイコンキャッシング

1. **メモリキャッシュ**: `CachedNetworkImage`のメモリキャッシュを使用
2. **ディスクキャッシュ**: 自動的にディスクにキャッシュ
3. **プリロード**: 画面外のアイコンを事前読み込み

### 状態管理の最適化

1. **Blocの適切な使用**: 必要な部分のみ再構築
2. **Equatableの使用**: 状態の比較を効率化
3. **debounce**: 連続した操作を制限

## アクセシビリティ

### セマンティックラベル

```dart
Semantics(
  label: '${price.name}, 価格 ${formattedPrice}, '
         '24時間変動 ${formattedChange}, '
         '${isFavorite ? "お気に入り登録済み" : ""}',
  button: true,
  child: PriceListItem(...),
)
```

### 最小タップ領域

すべてのタップ可能な要素は44x44ポイント以上を確保：

```dart
class PriceListItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 44.0,  // 最小タップ領域
      ),
      child: _buildContent(),
    );
  }
}
```

### 代替操作方法

長押し操作の代替として、スワイプアクションも提供：

```dart
Dismissible(
  key: ValueKey(price.symbol),
  confirmDismiss: (direction) async {
    if (direction == DismissDirection.endToStart) {
      // お気に入り追加/削除
      return false;  // 実際には削除しない
    }
    return false;
  },
  background: Container(
    color: Colors.blue,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 16),
    child: const Icon(Icons.star, color: Colors.white),
  ),
  child: PriceListItem(...),
)
```

## セキュリティ考慮事項

1. **アイコンURL**: HTTPSのみを使用
2. **入力検証**: シンボル名の検証
3. **ストレージ**: 機密情報は含まれないため、SharedPreferencesで十分

## 今後の拡張性

1. **カスタムアイコン**: ユーザーが独自のアイコンをアップロード
2. **テーマ**: アイコンの色やスタイルをカスタマイズ
3. **グループ化**: 通貨をカテゴリーごとにグループ化
4. **フィルタリング**: 表示する通貨をフィルタリング
5. **検索**: 通貨名やシンボルで検索
