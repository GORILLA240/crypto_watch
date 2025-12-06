# Crypto Watch

暗号通貨価格監視アプリケーション - スマートウォッチ最適化

## アーキテクチャ

- **フロントエンド**: Flutter（iOS、Android、Web、デスクトップ対応）
- **バックエンド**: AWS Serverless（API Gateway + Lambda + DynamoDB）

## セットアップ

### 1. 依存関係のインストール

```bash
flutter pub get
```

### 2. 環境変数の設定

`.env.example`をコピーして`.env`を作成し、必要な値を設定してください：

```bash
cp .env.example .env
```

必要な環境変数：
- `API_BASE_URL`: バックエンドAPI Gateway URL
- `API_KEY`: バックエンドAPIキー
- `USE_MOCK_DATA`: モックデータ使用フラグ（開発時は`true`）

### 3. バックエンドのデプロイ

バックエンドのセットアップとデプロイについては `backend/README.md` を参照してください。

### 4. アプリの実行

#### 開発モード（モックデータ使用）

```bash
flutter run --dart-define=USE_MOCK_DATA=true
```

#### 本番モード（実際のAPI使用）

```bash
flutter run \
  --dart-define=API_BASE_URL=https://your-api-url.com/dev \
  --dart-define=API_KEY=your-api-key \
  --dart-define=USE_MOCK_DATA=false
```

## ビルド

### Android

```bash
flutter build apk \
  --dart-define=API_BASE_URL=https://your-api-url.com/prod \
  --dart-define=API_KEY=your-api-key
```

### iOS

```bash
flutter build ios \
  --dart-define=API_BASE_URL=https://your-api-url.com/prod \
  --dart-define=API_KEY=your-api-key
```

### Web

```bash
flutter build web \
  --dart-define=API_BASE_URL=https://your-api-url.com/prod \
  --dart-define=API_KEY=your-api-key
```

## テスト

```bash
# ユニットテストの実行
flutter test

# カバレッジ付きテスト
flutter test --coverage

# コード解析
flutter analyze
```

## プロジェクト構造

```
lib/
├── core/                    # コア機能（ネットワーク、ストレージ、テーマ等）
│   ├── constants/          # 定数定義
│   ├── error/              # エラーハンドリング
│   ├── network/            # APIクライアント
│   ├── routing/            # ルーティング
│   ├── services/           # サービス層
│   ├── storage/            # ローカルストレージ
│   ├── theme/              # テーマ設定
│   ├── utils/              # ユーティリティ
│   └── widgets/            # 共通ウィジェット
├── features/               # 機能別モジュール
│   ├── alerts/            # 価格アラート機能
│   ├── currency_search/   # 通貨検索機能
│   ├── favorites/         # お気に入り管理
│   ├── price_detail/      # 価格詳細表示
│   ├── price_list/        # 価格一覧表示
│   └── settings/          # 設定画面
├── injection_container.dart # 依存性注入
└── main.dart               # エントリーポイント

test/                       # テストコード
├── core/                  # コア機能のテスト
└── features/              # 機能別テスト
```

## 主要機能

### 価格追跡
- 20種類以上の主要暗号通貨をサポート
- リアルタイム価格更新（5分間隔）
- 24時間変動率表示
- 時価総額表示

### お気に入り管理
- カスタム通貨の追加（CoinGecko API経由）
- ドラッグ&ドロップで並び替え
- ローカルストレージに保存

### 価格アラート
- 上限・下限価格の設定
- プッシュ通知
- アラート履歴管理

### スマートウォッチ対応
- コンプリケーション表示
- 最適化されたUI/UX
- 低帯域幅対応

## 技術スタック

- **Flutter**: 3.10.1+
- **状態管理**: flutter_bloc
- **依存性注入**: get_it
- **ネットワーク**: http
- **ローカルストレージ**: shared_preferences, flutter_secure_storage
- **関数型プログラミング**: dartz

## ライセンス

MIT

## 関連ドキュメント

- [バックエンドREADME](backend/README.md)
- [API仕様](backend/README.md#api-endpoints)
- [デプロイガイド](backend/docs/STAGING_TO_PROD_PROMOTION.md)
