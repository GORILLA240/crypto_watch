# 技術スタック

## フロントエンド

### Flutter
- **SDKバージョン**: 3.10.1+
- **言語**: Dart
- **UIフレームワーク**: Material Design（ダークテーマ）
- **プラットフォーム**: iOS、Android、Web、Windows、macOS、Linux

### 依存関係
- `cupertino_icons: ^1.0.8` - iOSスタイルのアイコン
- `flutter_lints: ^6.0.0` - コード品質のための推奨リント

## バックエンド

### AWSサーバーレスアーキテクチャ
- **ランタイム**: Python 3.11
- **Infrastructure as Code**: AWS SAM（Serverless Application Model）
- **API**: API Gateway経由のREST API
- **コンピュート**: AWS Lambda（2つの関数：APIハンドラー、価格更新）
- **データベース**: シングルテーブル設計のDynamoDB
- **スケジューリング**: EventBridge（5分間隔）
- **モニタリング**: CloudWatch Logs、Metrics、Alarms

### Python依存関係
- `boto3` - AWS SDK
- `requests` - 外部API用HTTPクライアント
- `pytest` - テストフレームワーク
- `hypothesis` - プロパティベーステスト
- `moto` - AWSサービスモック
- `black` - コードフォーマッター
- `flake8` - リンター
- `mypy` - 型チェッカー

### コード品質基準
- **行の長さ**: 100文字
- **フォーマッター**: Black
- **型チェック**: MyPy（有効だが厳密ではない）
- **リント**: Flake8

## 共通コマンド

### Flutter（フロントエンド）

```bash
# 依存関係の取得
flutter pub get

# アプリの実行（開発）
flutter run

# 特定プラットフォーム向けビルド
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
flutter build windows      # Windows

# テストの実行
flutter test

# コード解析
flutter analyze
```

### バックエンド（Python/SAM）

```bash
# 仮想環境のセットアップ
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 依存関係のインストール
make install
# または: pip install -r requirements-dev.txt

# SAMアプリケーションのビルド
make build
# または: sam build

# ローカル実行
make local
# または: sam local start-api

# テスト
make test              # カバレッジ付き全テスト
make test-unit         # ユニットテストのみ
make test-property     # プロパティベーステスト
make test-integration  # 統合テスト

# コード品質
make format            # Blackでフォーマット
make lint              # flake8とmypyの実行

# デプロイ
make deploy-dev        # 開発環境へデプロイ
make deploy-staging    # ステージング環境へデプロイ
make deploy-prod       # 本番環境へデプロイ

# またはデプロイスクリプトを使用:
./scripts/deploy.sh dev

# クリーンアップ
make clean
```

### SAM CLIコマンド

```bash
# テンプレートの検証
sam validate --lint

# ローカルテスト
sam local invoke ApiFunction --event events/api-event.json
sam local invoke PriceUpdateFunction --event events/update-event.json

# ガイド付きデプロイ（初回）
sam build
sam deploy --guided

# 特定環境へのデプロイ
sam deploy --config-env dev
sam deploy --config-env staging
sam deploy --config-env prod
```

### APIキー管理

```bash
# APIキーの作成
python scripts/setup-api-key.py --name "キー名" --environment dev

# APIのテスト
curl -H "X-API-Key: your-key" "https://api-url/prices?symbols=BTC,ETH"
```

## 環境設定

バックエンドは環境固有のSAM設定ファイルを使用：
- `samconfig-dev.toml` - 開発環境
- `samconfig-staging.toml` - ステージング環境
- `samconfig-prod.toml` - 本番環境

主要パラメータ：
- `RateLimitPerMinute` - APIレート制限（デフォルト: 100）
- `CacheTTLSeconds` - キャッシュ期間（デフォルト: 300）
- `SupportedSymbols` - 暗号通貨リスト
- `ExternalApiUrl` - 外部価格データソース
