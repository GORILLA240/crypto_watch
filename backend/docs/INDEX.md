# Crypto Watch バックエンド ドキュメント索引

## 主要ドキュメント

### セットアップとデプロイ

- **[README.md](../README.md)** - プロジェクト概要、セットアップ、API仕様
- **[SETUP.md](SETUP.md)** - 詳細なセットアップ手順
- **[STAGING_TO_PROD_PROMOTION.md](STAGING_TO_PROD_PROMOTION.md)** - 本番環境へのプロモーション手順
- **[ROLLBACK_VERIFICATION.md](ROLLBACK_VERIFICATION.md)** - ロールバック手順

### アーキテクチャとデザイン

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - システムアーキテクチャの詳細
- **[STRUCTURE.md](STRUCTURE.md)** - プロジェクト構造とコーディング規約

### 運用ガイド

- **[API_KEY_MANAGEMENT.md](API_KEY_MANAGEMENT.md)** - APIキーの作成と管理

### 開発ガイド

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - コントリビューションガイドライン

## ディレクトリ構造

```
backend/docs/
├── INDEX.md                          # このファイル
├── README.md                         # プロジェクト概要（ルートから参照）
├── ARCHITECTURE.md                   # アーキテクチャ詳細
├── STRUCTURE.md                      # プロジェクト構造
├── SETUP.md                          # セットアップ手順
├── CONTRIBUTING.md                   # コントリビューションガイド
├── API_KEY_MANAGEMENT.md             # APIキー管理
├── STAGING_TO_PROD_PROMOTION.md      # プロモーション手順
├── ROLLBACK_VERIFICATION.md          # ロールバック手順
└── history/                          # 実装履歴
    ├── README.md                     # 履歴ドキュメント索引
    ├── IMPLEMENTATION_COMPLETE.md    # 実装完了レポート
    ├── TASK_*_SUMMARY.md             # タスク実装サマリー
    └── TEST_*_SUMMARY.md             # テスト実装サマリー
```

## クイックリンク

### よく使うコマンド

```bash
# ローカル開発
sam build
sam local start-api

# テスト
pytest tests/ -v --cov=src

# デプロイ
./scripts/deploy.sh dev
./scripts/deploy.sh staging
./scripts/deploy.sh prod

# APIキー作成
python scripts/setup-api-key.py --name "Key Name" --environment dev
```

### API エンドポイント

- `GET /prices?symbols=BTC,ETH` - 複数通貨の価格取得
- `GET /prices/{symbol}` - 単一通貨の価格取得
- `GET /health` - ヘルスチェック

### 環境

- **dev**: 開発環境（ap-northeast-1）
- **staging**: ステージング環境（us-east-1）
- **prod**: 本番環境（ap-northeast-1）

## トラブルシューティング

### よくある問題

1. **デプロイエラー**: `sam build` を実行してから `sam deploy`
2. **APIキーエラー**: `python scripts/setup-api-key.py` でキー作成
3. **テストエラー**: `pip install -r requirements-dev.txt` で依存関係インストール

### ログ確認

```bash
# API Lambda のログ
aws logs tail /aws/lambda/crypto-watch-api-dev --follow

# Update Lambda のログ
aws logs tail /aws/lambda/crypto-watch-update-dev --follow
```

## 関連リソース

- [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
- [Python 3.11](https://www.python.org/downloads/)
- [CoinGecko API](https://www.coingecko.com/en/api)

## 更新履歴

- 2024-12: 初版作成
- ドキュメント整理とアーキテクチャドキュメント追加
