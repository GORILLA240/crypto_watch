# プロジェクト構造

## リポジトリレイアウト

Flutterフロントエンドとサーバーレスバックエンドの両方を含むモノレポです。

```
crypto_watch/
├── lib/                    # Flutterアプリケーションソース
├── backend/                # AWSサーバーレスバックエンド
├── test/                   # Flutterテスト
├── android/                # Androidプラットフォームファイル
├── ios/                    # iOSプラットフォームファイル
├── web/                    # Webプラットフォームファイル
├── windows/                # Windowsプラットフォームファイル
├── linux/                  # Linuxプラットフォームファイル
├── macos/                  # macOSプラットフォームファイル
├── pubspec.yaml            # Flutter依存関係
└── analysis_options.yaml   # Dart解析設定
```

## Flutterフロントエンド構造

```
lib/
└── main.dart              # アプリケーションエントリーポイント
```

**現在の状態**: プレースホルダーUIを持つ最小限の実装。以下を含む：
- `CryptoWatchApp` - ダークテーマのルートウィジェット
- `PriceHomePage` - 価格表示のメイン画面（現在はモックデータを表示）
- TODO: モックデータを実際のAPI呼び出しに置き換える

**規約**:
- 可能な限り`const`コンストラクタを使用
- 黒背景のダークテーマ
- Material Designコンポーネント
- `StatefulWidget`による状態管理（今後進化する可能性あり）

## バックエンド構造

```
backend/
├── src/
│   ├── api/                    # API Lambda関数
│   │   ├── handler.py         # HTTPリクエストハンドラー
│   │   └── requirements.txt   # 関数固有の依存関係
│   │
│   ├── update/                 # 価格更新Lambda関数
│   │   ├── handler.py         # スケジュール更新ハンドラー
│   │   └── requirements.txt   # 関数固有の依存関係
│   │
│   └── shared/                 # 共有Lambdaレイヤー
│       ├── __init__.py
│       ├── auth.py            # APIキー検証、レート制限
│       ├── cache.py           # キャッシュ鮮度ロジック
│       ├── db.py              # DynamoDB操作
│       ├── errors.py          # カスタム例外、エラーフォーマット
│       ├── external_api.py    # リトライ付き外部APIクライアント
│       ├── models.py          # データモデル（CryptoPrice、APIKeyなど）
│       └── utils.py           # ログ、タイムスタンプ、ユーティリティ
│
├── tests/
│   ├── unit/                   # ユニットテスト
│   │   ├── test_api.py
│   │   ├── test_update.py
│   │   └── test_shared.py
│   ├── integration/            # 統合テスト
│   │   └── test_e2e.py
│   └── conftest.py            # Pytestフィクスチャ
│
├── scripts/
│   ├── deploy.sh              # 自動デプロイ
│   └── setup-api-key.py       # APIキー管理
│
├── events/                     # ローカルテスト用サンプルイベント
│   ├── api-event.json
│   └── update-event.json
│
├── docs/                       # ドキュメント
│   ├── API_KEY_MANAGEMENT.md
│   ├── ROLLBACK_VERIFICATION.md
│   └── STAGING_TO_PROD_PROMOTION.md
│
├── template.yaml               # AWS SAM CloudFormationテンプレート
├── samconfig-dev.toml         # 開発環境設定
├── samconfig-staging.toml     # ステージング環境設定
├── samconfig-prod.toml        # 本番環境設定
├── requirements-dev.txt       # 開発依存関係
├── pyproject.toml             # Pythonプロジェクト設定（Black、MyPy）
├── pytest.ini                 # Pytest設定
├── .flake8                    # Flake8リンター設定
├── Makefile                   # 共通開発コマンド
└── README.md                  # 包括的なドキュメント
```

## バックエンドアーキテクチャパターン

### Lambdaレイヤーパターン
- 共有コードは`src/shared/`に配置し、Lambdaレイヤーとしてデプロイ
- 両方のLambda関数がこのレイヤーからインポート
- コードの重複とデプロイサイズを削減

### シングルテーブルDynamoDB設計
- すべてのデータタイプを1つのテーブルに: `crypto-watch-data-{environment}`
- プライマリキー: `PK`（パーティションキー）、`SK`（ソートキー）
- GSI1: `GSI1PK`、`GSI1SK` 代替アクセスパターン用

**アイテムタイプ**:
1. **価格データ**: `PK=PRICE#{symbol}`, `SK=METADATA`
2. **APIキー**: `PK=APIKEY#{keyId}`, `SK=METADATA`
3. **レート制限**: `PK=APIKEY#{keyId}`, `SK=RATELIMIT#{minute}`

### エラーハンドリングパターン
- `errors.py`のカスタム例外
- エラーコード付きの一貫したエラーレスポンス形式
- HTTPステータスコード: 400、401、429、500、503

### テスト戦略
- 個別モジュールのユニットテスト
- Hypothesisを使用したプロパティベーステスト
- モックAWSサービス（moto）を使用した統合テスト
- 再利用可能なテストセットアップ用の`conftest.py`のPytestフィクスチャ

## ファイル命名規則

### Flutter
- ファイルはスネークケース: `main.dart`、`price_home_page.dart`
- クラスはパスカルケース: `CryptoWatchApp`、`PriceHomePage`

### Pythonバックエンド
- ファイルと関数はスネークケース: `handler.py`、`external_api.py`
- クラスはパスカルケース: `CryptoPrice`、`APIKey`
- 定数はUPPER_SNAKE_CASE: `RATE_LIMIT_PER_MINUTE`

## モジュール構成

### バックエンド共有モジュール

**models.py**: `@dataclass`を使用したデータクラス
- `CryptoPrice` - 価格データ構造
- `APIKey` - APIキーメタデータ
- `RateLimit` - レート制限状態

**db.py**: DynamoDB操作
- `get_item()`、`put_item()`、`query()`、`update_item()`
- シリアライゼーション/デシリアライゼーションを処理

**auth.py**: 認証と認可
- `validate_api_key()` - APIキーの有効性チェック
- `check_rate_limit()` - レート制限の適用
- `update_rate_limit()` - リクエスト数の追跡

**cache.py**: キャッシュ管理
- `is_cache_fresh()` - キャッシュデータの有効性チェック
- `calculate_ttl()` - 有効期限の計算

**external_api.py**: 外部APIクライアント
- 指数バックオフ付きリトライロジック
- API障害のエラーハンドリング
- レスポンスのパースと検証

**errors.py**: 例外階層
- `CryptoWatchError` - 基底例外
- `AuthenticationError`、`RateLimitError`、`ValidationError`など
- `format_error_response()` - 一貫したエラーフォーマット

**utils.py**: 汎用ユーティリティ
- ログ設定
- タイムスタンプ処理
- ログ用APIキーマスキング

## 環境固有リソース

リソースは環境ごとに名前空間化：
- DynamoDBテーブル: `crypto-watch-data-{environment}`
- Lambda関数: `crypto-watch-api-{environment}`、`crypto-watch-update-{environment}`
- API Gateway: `crypto-watch-api-{environment}`
- CloudWatch Log Groups: `/aws/lambda/crypto-watch-api-{environment}`

## ドキュメントファイル

バックエンドには実装を文書化する広範なタスクサマリーが含まれています：
- `TASK_*_SUMMARY.md` - 個別タスク完了レポート
- `IMPLEMENTATION_COMPLETE.md` - 全体的な実装ステータス
- `STRUCTURE.md` - 詳細な構造ドキュメント
- `SETUP.md` - セットアップ手順
