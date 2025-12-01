# 設計書

## 概要

Crypto Watch Flutterフロントエンドは、クリーンアーキテクチャの原則に基づいて設計されたモバイルアプリケーションです。レイヤー分離、依存性注入、状態管理を適切に実装し、保守性とテスト容易性を確保します。

## アーキテクチャ

### レイヤー構造

```
lib/
├── main.dart                          # アプリケーションエントリーポイント
├── core/                              # コア機能
│   ├── constants/                     # 定数定義
│   │   ├── api_constants.dart        # API関連定数
│   │   └── app_constants.dart        # アプリ定数
│   ├── error/                         # エラーハンドリング
│   │   ├── exceptions.dart           # カスタム例外
│   │   └── failures.dart             # 失敗クラス
│   ├── network/                       # ネットワーク層
│   │   ├── api_client.dart           # HTTPクライアント
│   │   └── network_info.dart         # ネットワーク状態チェック
│   ├── storage/                       # ローカルストレージ
│   │   └── local_storage.dart        # SharedPreferencesラッパー
│   └── utils/                         # ユーティリティ
│       ├── currency_formatter.dart   # 通貨フォーマット
│       └── date_formatter.dart       # 日付フォーマット
│
├── features/                          # 機能別モジュール
│   ├── price_list/                   # 価格一覧機能
│   │   ├── data/                     # データ層
│   │   │   ├── models/
│   │   │   │   └── crypto_price_model.dart
│   │   │   ├── datasources/
│   │   │   │   ├── price_remote_datasource.dart
│   │   │   │   └── price_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── price_repository_impl.dart
│   │   ├── domain/                   # ドメイン層
│   │   │   ├── entities/
│   │   │   │   └── crypto_price.dart
│   │   │   ├── repositories/
│   │   │   │   └── price_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_prices.dart
│   │   │       └── refresh_prices.dart
│   │   └── presentation/             # プレゼンテーション層
│   │       ├── bloc/
│   │       │   ├── price_list_bloc.dart
│   │       │   ├── price_list_event.dart
│   │       │   └── price_list_state.dart
│   │       ├── pages/
│   │       │   └── price_list_page.dart
│   │       └── widgets/
│   │           ├── price_list_item.dart
│   │           └── loading_indicator.dart
│   │
│   ├── price_detail/                 # 価格詳細機能
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── price_detail_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── detail_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── detail_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── price_detail.dart
│   │   │   ├── repositories/
│   │   │   │   └── detail_repository.dart
│   │   │   └── usecases/
│   │   │       └── get_price_detail.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── price_detail_bloc.dart
│   │       │   ├── price_detail_event.dart
│   │       │   └── price_detail_state.dart
│   │       ├── pages/
│   │       │   └── price_detail_page.dart
│   │       └── widgets/
│   │           ├── mini_chart.dart
│   │           └── price_stats.dart
│   │
│   ├── favorites/                    # お気に入り機能
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── favorite_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── favorites_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── favorites_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── favorite.dart
│   │   │   ├── repositories/
│   │   │   │   └── favorites_repository.dart
│   │   │   └── usecases/
│   │   │       ├── add_favorite.dart
│   │   │       ├── remove_favorite.dart
│   │   │       ├── get_favorites.dart
│   │   │       └── reorder_favorites.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── favorites_bloc.dart
│   │       │   ├── favorites_event.dart
│   │       │   └── favorites_state.dart
│   │       └── widgets/
│   │           └── reorderable_favorite_list.dart
│   │
│   ├── settings/                     # 設定機能
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── settings_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── settings_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── settings_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── app_settings.dart
│   │   │   ├── repositories/
│   │   │   │   └── settings_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_settings.dart
│   │   │       └── update_settings.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── settings_bloc.dart
│   │       │   ├── settings_event.dart
│   │       │   └── settings_state.dart
│   │       ├── pages/
│   │       │   └── settings_page.dart
│   │       └── widgets/
│   │           └── currency_selector.dart
│   │
│   ├── alerts/                       # アラート機能
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── alert_model.dart
│   │   │   ├── datasources/
│   │   │   │   └── alerts_local_datasource.dart
│   │   │   └── repositories/
│   │   │       └── alerts_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── price_alert.dart
│   │   │   ├── repositories/
│   │   │   │   └── alerts_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_alert.dart
│   │   │       ├── delete_alert.dart
│   │   │       └── check_alerts.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── alerts_bloc.dart
│   │       │   ├── alerts_event.dart
│   │       │   └── alerts_state.dart
│   │       └── widgets/
│   │           └── alert_form.dart
│   │
│   └── single_view/                  # シングルビュー機能
│       ├── presentation/
│       │   ├── bloc/
│       │   │   ├── single_view_bloc.dart
│       │   │   ├── single_view_event.dart
│       │   │   └── single_view_state.dart
│       │   ├── pages/
│       │   │   └── single_view_page.dart
│       │   └── widgets/
│       │       └── large_price_display.dart
│       │
└── injection_container.dart          # 依存性注入設定
```

## コンポーネントとインターフェース

### データモデル

#### CryptoPrice Entity
```dart
class CryptoPrice {
  final String symbol;
  final String name;
  final double price;
  final double change24h;
  final double marketCap;
  final DateTime lastUpdated;
}
```

#### PriceDetail Entity
```dart
class PriceDetail extends CryptoPrice {
  final double high24h;
  final double low24h;
  final double volume24h;
  final List<ChartDataPoint> chart1h;
  final List<ChartDataPoint> chart24h;
  final List<ChartDataPoint> chart7d;
}
```

#### Favorite Entity
```dart
class Favorite {
  final String symbol;
  final int order;
  final DateTime addedAt;
}
```

#### PriceAlert Entity
```dart
class PriceAlert {
  final String id;
  final String symbol;
  final double? upperLimit;
  final double? lowerLimit;
  final bool isEnabled;
  final DateTime createdAt;
}
```

#### AppSettings Entity
```dart
class AppSettings {
  final Currency displayCurrency; // JPY, USD, EUR, BTC
  final bool autoRefreshEnabled;
  final int refreshIntervalSeconds;
  final bool notificationsEnabled;
}
```

### リポジトリインターフェース

#### PriceRepository
```dart
abstract class PriceRepository {
  Future<Either<Failure, List<CryptoPrice>>> getPrices(List<String> symbols);
  Future<Either<Failure, CryptoPrice>> getPriceBySymbol(String symbol);
  Future<Either<Failure, List<CryptoPrice>>> refreshPrices();
}
```

#### FavoritesRepository
```dart
abstract class FavoritesRepository {
  Future<Either<Failure, List<Favorite>>> getFavorites();
  Future<Either<Failure, void>> addFavorite(String symbol);
  Future<Either<Failure, void>> removeFavorite(String symbol);
  Future<Either<Failure, void>> reorderFavorites(List<Favorite> favorites);
}
```

#### AlertsRepository
```dart
abstract class AlertsRepository {
  Future<Either<Failure, List<PriceAlert>>> getAlerts();
  Future<Either<Failure, void>> createAlert(PriceAlert alert);
  Future<Either<Failure, void>> deleteAlert(String alertId);
  Future<Either<Failure, void>> updateAlert(PriceAlert alert);
}
```

#### SettingsRepository
```dart
abstract class SettingsRepository {
  Future<Either<Failure, AppSettings>> getSettings();
  Future<Either<Failure, void>> updateSettings(AppSettings settings);
}
```

### ユースケース

各ユースケースは単一責任の原則に従い、1つの操作のみを実行します。

#### GetPrices UseCase
```dart
class GetPrices {
  final PriceRepository repository;
  
  Future<Either<Failure, List<CryptoPrice>>> call(List<String> symbols);
}
```

#### RefreshPrices UseCase
```dart
class RefreshPrices {
  final PriceRepository repository;
  
  Future<Either<Failure, List<CryptoPrice>>> call();
}
```

## データフロー

### 価格データ取得フロー

```
User Action (Pull to Refresh)
    ↓
PriceListBloc (RefreshPricesEvent)
    ↓
RefreshPrices UseCase
    ↓
PriceRepository
    ↓
PriceRemoteDataSource (API Call)
    ↓
ApiClient (HTTP Request)
    ↓
Backend API
    ↓
Response → Model → Entity
    ↓
PriceListBloc (PriceLoadedState)
    ↓
UI Update
```

### お気に入り管理フロー

```
User Action (Add to Favorites)
    ↓
FavoritesBloc (AddFavoriteEvent)
    ↓
AddFavorite UseCase
    ↓
FavoritesRepository
    ↓
FavoritesLocalDataSource (SharedPreferences)
    ↓
Save to Local Storage
    ↓
FavoritesBloc (FavoritesUpdatedState)
    ↓
UI Update
```

## エラーハンドリング

### 例外階層

```dart
// 基底例外
abstract class AppException implements Exception {
  final String message;
}

// ネットワーク例外
class NetworkException extends AppException {}
class TimeoutException extends AppException {}

// API例外
class ApiException extends AppException {
  final int statusCode;
}
class AuthenticationException extends ApiException {}
class RateLimitException extends ApiException {}

// データ例外
class ParseException extends AppException {}
class CacheException extends AppException {}
```

### Failure クラス

```dart
abstract class Failure {
  final String message;
}

class NetworkFailure extends Failure {}
class ServerFailure extends Failure {}
class CacheFailure extends Failure {}
class ValidationFailure extends Failure {}
```

## 正確性プロパティ

*プロパティとは、システムのすべての有効な実行において真であるべき特性または動作です。プロパティは、人間が読める仕様と機械検証可能な正確性保証の橋渡しとなります。*

### プロパティ1: 価格データの一貫性

*任意の*価格データリストに対して、すべてのアイテムは有効なシンボル、正の価格値、有効なタイムスタンプを持つべきである

**検証: 要件1.1, 1.2**

### プロパティ2: お気に入りの順序保持

*任意の*お気に入りリストに対して、並び替え操作後に保存し再読み込みした場合、順序は保持されるべきである

**検証: 要件11.3, 11.4**

### プロパティ3: リフレッシュの冪等性

*任意の*状態において、連続したリフレッシュ操作は重複リクエストを生成せず、最後のリクエストの結果のみが反映されるべきである

**検証: 要件2.5**

### プロパティ4: 通貨変換の可逆性

*任意の*価格値に対して、通貨AからBに変換し、再びAに戻した場合、元の値（許容誤差内）に戻るべきである

**検証: 要件15.3, 15.5**

### プロパティ5: アラート発火の正確性

*任意の*アラート設定に対して、価格が上限を超えるか下限を下回った場合にのみ、通知が発火されるべきである

**検証: 要件16.3**

### プロパティ6: 自動更新の停止と再開

*任意の*アプリ状態において、バックグラウンド移行時に自動更新が停止し、フォアグラウンド復帰時に再開されるべきである

**検証: 要件3.2, 3.3**

### プロパティ7: エラー後の回復

*任意の*エラー状態から、再試行操作により正常状態に復帰できるべきである

**検証: 要件4.5**

### プロパティ8: ローカルストレージの永続性

*任意の*お気に入りまたは設定データに対して、アプリ再起動後も同じデータが読み込まれるべきである

**検証: 要件11.4, 15.4**

### プロパティ9: UI応答性の維持

*任意の*データ取得操作中において、UIは60FPSを維持し、ユーザー操作に応答し続けるべきである

**検証: 要件5.5, 10.1**

### プロパティ10: 変動率の色表示の一貫性

*任意の*価格データに対して、正の変動率は緑、負の変動率は赤で表示されるべきである

**検証: 要件1.3, 1.4**

## テスト戦略

### ユニットテスト

- **データモデル**: JSON シリアライゼーション/デシリアライゼーション
- **ユースケース**: ビジネスロジックの検証
- **リポジトリ**: データソースとの統合
- **Bloc**: 状態遷移の検証

### ウィジェットテスト

- **個別ウィジェット**: レンダリングと相互作用
- **画面全体**: ナビゲーションとレイアウト

### 統合テスト

- **エンドツーエンド**: 実際のユーザーフローのシミュレーション
- **API統合**: モックサーバーとの通信

### プロパティベーステスト

プロパティベーステストには**test**パッケージの**check**機能を使用します。

- **プロパティ1-10**: 各正確性プロパティに対応するテスト
- 各テストは最低100回の反復を実行
- ランダムな入力データを生成してプロパティを検証

## 状態管理

### Bloc パターン

**flutter_bloc**パッケージを使用して状態管理を実装します。

#### PriceListBloc の状態遷移

```
Initial → Loading → Loaded
                  → Error
                  
Loaded → Refreshing → Loaded
                    → Error
```

#### イベント

- `LoadPricesEvent`: 初回データ読み込み
- `RefreshPricesEvent`: データ更新
- `AutoRefreshEvent`: 自動更新トリガー

#### 状態

- `PriceListInitial`: 初期状態
- `PriceListLoading`: データ読み込み中
- `PriceListLoaded`: データ読み込み完了
- `PriceListRefreshing`: 更新中
- `PriceListError`: エラー発生

## UI設計

### テーマ

```dart
ThemeData darkTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: Colors.black,
  primaryColor: Colors.white,
  colorScheme: ColorScheme.dark(
    primary: Colors.white,
    secondary: Colors.grey[800]!,
    error: Colors.red[400]!,
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
    bodyLarge: TextStyle(fontSize: 20),
    bodyMedium: TextStyle(fontSize: 16),
  ),
);
```

### カラーパレット

- **背景**: 黒 (#000000)
- **テキスト**: 白 (#FFFFFF)
- **上昇**: 緑 (#4CAF50)
- **下落**: 赤 (#F44336)
- **アクセント**: グレー (#757575)

### レイアウト原則

1. **大きなタップ領域**: 最小48x48dp
2. **十分な余白**: 各要素間に16dp以上
3. **大きなフォント**: 本文は最低16sp
4. **明確な階層**: サイズと色で情報の重要度を表現
5. **シンプルさ**: 1画面に3〜5要素まで

## パフォーマンス最適化

### 最適化戦略

1. **遅延読み込み**: ListView.builderを使用
2. **メモ化**: 計算結果のキャッシュ
3. **画像最適化**: CachedNetworkImageの使用
4. **状態の最小化**: 必要な部分のみ再描画
5. **非同期処理**: Isolateの活用（重い計算）

### メモリ管理

- **Bloc の dispose**: 画面離脱時にリソース解放
- **タイマーのキャンセル**: 自動更新タイマーの適切な管理
- **キャッシュサイズ制限**: 画像キャッシュの上限設定

## セキュリティ

### APIキー管理

- **環境変数**: `--dart-define`でAPIキーを注入
- **難読化**: ProGuard/R8での難読化
- **ログマスキング**: APIキーをログに出力しない

### データ保護

- **暗号化**: flutter_secure_storageで機密データを暗号化
- **証明書ピンニング**: SSL証明書の検証

## 依存関係

### 主要パッケージ

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 状態管理
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # ネットワーク
  http: ^1.1.0
  connectivity_plus: ^5.0.1
  
  # ローカルストレージ
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # 関数型プログラミング
  dartz: ^0.10.1
  
  # 依存性注入
  get_it: ^7.6.4
  
  # UI
  cached_network_image: ^3.3.0
  fl_chart: ^0.65.0
  
  # ユーティリティ
  intl: ^0.18.1
  uuid: ^4.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  mockito: ^5.4.3
  build_runner: ^2.4.6
  bloc_test: ^9.1.5
```

## 次のステップ

設計書の承認後、以下のタスクリストに基づいて実装を進めます：

1. プロジェクト構造のセットアップ
2. コア機能の実装（API クライアント、エラーハンドリング）
3. データ層の実装（モデル、データソース、リポジトリ）
4. ドメイン層の実装（エンティティ、ユースケース）
5. プレゼンテーション層の実装（Bloc、UI）
6. テストの実装
7. 統合とデバッグ
