# Crypto Watch バックエンドアーキテクチャ

## 概要

Crypto Watchバックエンドは、AWS Serverless Application Model (SAM)を使用したサーバーレスアーキテクチャです。

## アーキテクチャ図

```
┌─────────────┐
│   Client    │
│  (Flutter)  │
└──────┬──────┘
       │ HTTPS
       ▼
┌─────────────────────────────────────────┐
│         API Gateway                      │
│  - REST API                              │
│  - API Key認証                           │
│  - CORS設定                              │
│  - レート制限                            │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│      Lambda: API Function                │
│  - 価格データ取得                        │
│  - 認証・認可                            │
│  - キャッシュ管理                        │
│  - レスポンス最適化                      │
└──────┬──────────────────────────────────┘
       │
       ├──────────────┐
       ▼              ▼
┌─────────────┐  ┌──────────────┐
│  DynamoDB   │  │ External API │
│  - 価格     │  │ (CoinGecko)  │
│  - APIキー  │  └──────────────┘
│  - レート   │
│    制限     │
└─────────────┘
       ▲
       │
┌──────┴──────────────────────────────────┐
│   Lambda: Price Update Function          │
│  - 定期的な価格更新（5分間隔）           │
│  - 外部API呼び出し                       │
│  - リトライロジック                      │
└──────▲──────────────────────────────────┘
       │
┌──────┴──────────────────────────────────┐
│         EventBridge                      │
│  - スケジュール実行（rate(5 minutes)）  │
└─────────────────────────────────────────┘
```

## コンポーネント

### 1. API Gateway

**役割**: HTTPSエンドポイントの提供とリクエストルーティング

**機能**:
- REST APIエンドポイント
- CORS設定（クロスオリジンリクエスト対応）
- API Gateway レベルのスロットリング
- カスタムゲートウェイレスポンス（401, 429エラー）

**エンドポイント**:
- `GET /prices?symbols=BTC,ETH` - 複数通貨の価格取得
- `GET /prices/{symbol}` - 単一通貨の価格取得
- `GET /health` - ヘルスチェック（認証不要）

### 2. Lambda: API Function

**役割**: APIリクエストの処理とビジネスロジックの実行

**責務**:
- リクエストパラメータのバリデーション
- API Key認証とレート制限チェック
- キャッシュ状態の確認
- 新鮮なデータはキャッシュから返却
- 古いデータは外部APIから取得してキャッシュ更新
- レスポンスの最適化（gzip圧縮）

**環境変数**:
- `DYNAMODB_TABLE_NAME`: DynamoDBテーブル名
- `RATE_LIMIT_PER_MINUTE`: レート制限（デフォルト: 100）
- `CACHE_TTL_SECONDS`: キャッシュTTL（デフォルト: 300秒）
- `ENVIRONMENT`: 環境名（dev/staging/prod）
- `LOG_LEVEL`: ログレベル（INFO）

**タイムアウト**: 25秒
**メモリ**: 512MB

### 3. Lambda: Price Update Function

**役割**: 定期的な価格データの更新

**責務**:
- EventBridgeからのスケジュール実行（5分間隔）
- 外部API（CoinGecko）から価格データ取得
- エクスポネンシャルバックオフによるリトライ
- DynamoDBへの価格データ保存

**環境変数**:
- `DYNAMODB_TABLE_NAME`: DynamoDBテーブル名
- `EXTERNAL_API_URL`: 外部API URL
- `EXTERNAL_API_KEY`: 外部APIキー（オプション）
- `SUPPORTED_SYMBOLS`: サポート通貨リスト
- `ENVIRONMENT`: 環境名
- `LOG_LEVEL`: ログレベル

**タイムアウト**: 60秒
**メモリ**: 512MB

### 4. Lambda Layer: Shared

**役割**: 共通コードの共有

**含まれるモジュール**:
- `models.py`: データモデル（CryptoPrice, APIKey, RateLimit）
- `db.py`: DynamoDB操作
- `auth.py`: 認証・認可・レート制限
- `cache.py`: キャッシュ管理ロジック
- `external_api.py`: 外部APIクライアント
- `errors.py`: カスタム例外とエラーレスポンス
- `utils.py`: ユーティリティ関数
- `metrics.py`: メトリクス記録
- `response_optimizer.py`: レスポンス最適化
- `transformers.py`: データ変換

### 5. DynamoDB

**役割**: データストレージ

**テーブル設計**: シングルテーブルデザイン

**パーティションキー (PK)** と **ソートキー (SK)**:

| データタイプ | PK | SK | 属性 |
|-------------|----|----|------|
| 価格データ | `PRICE#{symbol}` | `METADATA` | symbol, name, price, change24h, marketCap, lastUpdated, ttl |
| APIキー | `APIKEY#{keyId}` | `METADATA` | keyId, name, createdAt, enabled, lastUsedAt |
| レート制限 | `APIKEY#{keyId}` | `RATELIMIT#{minute}` | requestCount, ttl |

**GSI (Global Secondary Index)**:
- GSI1: 将来の拡張用（現在未使用）

**TTL設定**:
- 有効化: `ttl`属性
- 価格データ: 1時間後に自動削除
- レート制限: 1時間後に自動削除

**キャパシティモード**: オンデマンド（自動スケーリング）

### 6. EventBridge

**役割**: 定期実行のスケジューリング

**ルール**:
- スケジュール: `rate(5 minutes)`
- ターゲット: Price Update Lambda Function
- 有効化: true

### 7. CloudWatch

**役割**: ロギングとモニタリング

**ログ**:
- `/aws/lambda/crypto-watch-api-{env}`
- `/aws/lambda/crypto-watch-update-{env}`
- 保持期間: dev=30日, staging=60日, prod=90日

**メトリクス**:
- Lambda実行時間
- Lambda エラー率
- Lambda スロットル数
- API Gateway 5xxエラー
- DynamoDB読み書き操作

**アラーム（本番環境のみ）**:
- Lambda エラー率 > 5/分
- API Gateway 5xxエラー率 > 10%
- Lambda スロットル数 > 10/分

## データフロー

### 価格取得フロー

```
1. クライアント → API Gateway
   GET /prices?symbols=BTC,ETH
   Header: X-API-Key: xxx

2. API Gateway → API Lambda
   イベント: {path, queryStringParameters, headers}

3. API Lambda:
   a. API Key検証
   b. レート制限チェック
   c. キャッシュ確認
      - 新鮮（5分以内）→ キャッシュから返却
      - 古い → 外部APIから取得

4. 外部API呼び出し（必要な場合）:
   a. CoinGecko API呼び出し
   b. リトライロジック（最大3回）
   c. DynamoDBにキャッシュ保存

5. レスポンス最適化:
   a. JSON整形
   b. gzip圧縮（Accept-Encoding: gzip の場合）

6. API Lambda → API Gateway → クライアント
   Response: {data: [...], timestamp: "..."}
```

### 価格更新フロー

```
1. EventBridge（5分間隔）
   → Price Update Lambda

2. Price Update Lambda:
   a. サポート通貨リスト取得
   b. 外部API呼び出し（全通貨）
   c. リトライロジック
   d. DynamoDBに一括保存

3. CloudWatch Logs
   実行結果をログ記録
```

## セキュリティ

### 認証・認可

- **API Key認証**: すべてのエンドポイント（/health除く）
- **ヘッダー**: `X-API-Key`
- **検証**: DynamoDBでキー存在確認と有効化状態チェック

### レート制限

- **制限**: 100リクエスト/分/APIキー（設定可能）
- **ウィンドウ**: ローリング1分間
- **実装**: DynamoDBで分単位のカウンター管理
- **レスポンス**: 429 Too Many Requests

### データ保護

- **転送中**: HTTPS（TLS 1.2+）
- **保存時**: DynamoDB暗号化（AWS管理キー）
- **APIキー**: マスキングしてログ出力

## スケーラビリティ

### 自動スケーリング

- **Lambda**: 同時実行数に応じて自動スケール
- **DynamoDB**: オンデマンドキャパシティで自動スケール
- **API Gateway**: 自動スケール（デフォルト10,000 RPS）

### パフォーマンス最適化

- **キャッシュ**: 5分間のTTLで外部API呼び出しを削減
- **バッチ処理**: DynamoDB batch_write_itemで効率化
- **圧縮**: gzipでレスポンスサイズを削減（~70%）
- **コールドスタート**: Lambda Layerで共通コード共有

## 可用性

### 冗長性

- **Lambda**: マルチAZ自動配置
- **DynamoDB**: マルチAZ自動レプリケーション
- **API Gateway**: マルチAZ自動配置

### エラーハンドリング

- **外部API障害**: キャッシュフォールバック
- **DynamoDB障害**: エラーレスポンス（503）
- **Lambda障害**: 自動リトライ（非同期実行）

### モニタリング

- **CloudWatch Alarms**: 本番環境で自動アラート
- **ログ**: 構造化ログでトラブルシューティング
- **メトリクス**: カスタムメトリクスで詳細監視

## コスト最適化

### 無料枠活用

- **Lambda**: 100万リクエスト/月
- **DynamoDB**: 25GB ストレージ、25 RCU/WCU
- **API Gateway**: 100万リクエスト/月（初年度）

### コスト削減策

- **キャッシュ**: 外部API呼び出しを削減
- **オンデマンド**: 使用量に応じた課金
- **ログ保持期間**: 環境別に最適化
- **TTL**: 古いデータを自動削除

## 環境分離

### 3環境構成

- **dev**: 開発・テスト環境
- **staging**: 検証環境（本番同等）
- **prod**: 本番環境

### リソース命名

- DynamoDB: `crypto-watch-data-{env}`
- Lambda: `crypto-watch-api-{env}`, `crypto-watch-update-{env}`
- API Gateway: `crypto-watch-api-{env}`

### 設定管理

- 環境別SAM設定: `samconfig-{env}.toml`
- パラメータオーバーライド
- タグ付けによる管理

## 参考資料

- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
