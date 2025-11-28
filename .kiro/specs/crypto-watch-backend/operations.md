# 運用ドキュメント（Runbook）

このドキュメントは、crypto-watch-backendの運用担当者向けのアラート対応フローとトラブルシューティングガイドです。

## 目次

1. [アラート通知設定](#アラート通知設定)
2. [主要なアラート種別と対応手順](#主要なアラート種別と対応手順)
3. [ロールバック判断基準](#ロールバック判断基準)
4. [よくある問題と対処法](#よくある問題と対処法)
5. [エスカレーションフロー](#エスカレーションフロー)

---

## アラート通知設定

### 通知チャネル

| チャネル | 用途 | 対象アラート |
|---------|------|------------|
| **Slack** | リアルタイム通知 | すべてのアラート |
| **Email** | 記録・エスカレーション | Critical/High severity |
| **SNS Topic** | 統合ポイント | すべてのアラート |

**Slackチャネル:**
- `#crypto-watch-alerts` - すべてのアラート
- `#crypto-watch-deploys` - デプロイ関連
- `#crypto-watch-incidents` - インシデント対応

**将来的な拡張:**
- PagerDuty / Opsgenie などのオンコールツールとの連携
- インシデント対応プロセスが固まった段階で検討

### アラート重要度

| レベル | 説明 | 対応時間 |
|--------|------|---------|
| **Critical** | サービス停止、データ損失の可能性 | 即座（15分以内） |
| **High** | 機能劣化、エラー率上昇 | 1時間以内 |
| **Medium** | パフォーマンス低下、警告 | 営業時間内 |
| **Low** | 情報提供、傾向監視 | 定期レビュー |

---

## 主要なアラート種別と対応手順

### 1. Lambda Error Rate Alarm（Critical）

**アラート内容:**
- Lambda関数のエラー率が5%を超えた状態が2分間継続

**確認するメトリクス:**
```
CloudWatch Metrics:
- AWS/Lambda > Errors (Function: ApiFunction)
- AWS/Lambda > Invocations (Function: ApiFunction)
- AWS/Lambda > Duration (Function: ApiFunction)
```

**確認するログ:**
```
CloudWatch Logs:
- /aws/lambda/crypto-watch-api-function
- フィルタパターン: "ERROR" または "Exception"
```

**初動対応ステップ:**

1. **アラームの確認**
   ```bash
   # CloudWatch Alarmsコンソールで現在の状態を確認
   # または AWS CLI:
   aws cloudwatch describe-alarms --alarm-names LambdaErrorAlarm
   ```

2. **エラーログの確認**
   - CloudWatch Logsで最新のERRORログを確認
   - エラーメッセージとスタックトレースを確認
   - 共通のエラーパターンを特定

3. **エラーの分類**
   - **外部API障害**: 外部暗号通貨APIの問題 → [外部APIエラー対応](#2-外部apiエラー率アラームhigh)へ
   - **DynamoDB障害**: データベース接続エラー → [DynamoDBスロットリング対応](#3-dynamodbスロットリングアラームhigh)へ
   - **コードバグ**: 新しいデプロイ後に発生 → [ロールバック判断](#ロールバック判断基準)へ
   - **タイムアウト**: Lambda実行時間超過 → パフォーマンス調査

4. **影響範囲の確認**
   - エラー率: 全リクエストの何%が失敗しているか
   - 影響期間: いつから発生しているか
   - 影響エンドポイント: 特定のエンドポイントのみか、全体か

5. **対応判断**
   - **デプロイ直後（10分以内）**: 自動ロールバックを待つ、または手動ロールバック
   - **長期的な問題**: 根本原因を調査し、修正をデプロイ
   - **外部要因**: 外部サービスの復旧を待つ、キャッシュで対応

**エスカレーション条件:**
- エラー率が10%を超える
- 15分以上継続
- 自動ロールバックが失敗

---

### 2. 外部APIエラー率アラーム（High）

**アラート内容:**
- 外部暗号通貨APIへの呼び出しが50%以上失敗している状態が10分間継続

**確認するメトリクス:**
```
CloudWatch Metrics:
- Custom/CryptoWatch > ExternalApiErrors
- Custom/CryptoWatch > ExternalApiCalls
- Custom/CryptoWatch > ExternalApiLatency
```

**確認するログ:**
```
CloudWatch Logs:
- /aws/lambda/crypto-watch-price-update-function
- フィルタパターン: "External API" AND "ERROR"
```

**初動対応ステップ:**

1. **外部APIの状態確認**
   - 外部API（CoinGecko等）のステータスページを確認
   - 公式Twitterやステータスダッシュボードをチェック

2. **エラーの詳細確認**
   - HTTPステータスコード: 429（レート制限）、503（サービス停止）、タイムアウト
   - エラーメッセージの内容
   - リトライ回数と結果

3. **対応方針の決定**

   **ケース1: レート制限（429）**
   - 更新頻度を一時的に下げる（5分 → 10分）
   - 外部APIプランのアップグレードを検討

   **ケース2: サービス停止（503）**
   - キャッシュされたデータで対応（最大1時間）
   - 外部APIの復旧を待つ
   - 代替APIプロバイダーへの切り替えを検討（将来的拡張）

   **ケース3: タイムアウト**
   - タイムアウト設定の見直し（現在5秒）
   - ネットワーク問題の調査

4. **ユーザーへの影響確認**
   - キャッシュが有効な間（5分）はユーザーへの影響なし
   - キャッシュ期限切れ後は古いデータが返される
   - ヘルスチェックエンドポイントで警告を表示

5. **通知とコミュニケーション**
   - Slackで状況を共有
   - 長期化する場合はステータスページを更新

**エスカレーション条件:**
- 外部APIが1時間以上停止
- キャッシュデータが古くなりすぎる（1時間以上）

---

### 3. DynamoDBスロットリングアラーム（High）

**アラート内容:**
- DynamoDBのスロットリングイベントが検出された

**確認するメトリクス:**
```
CloudWatch Metrics:
- AWS/DynamoDB > UserErrors (Table: crypto-watch-data)
- AWS/DynamoDB > SystemErrors (Table: crypto-watch-data)
- AWS/DynamoDB > ConsumedReadCapacityUnits
- AWS/DynamoDB > ConsumedWriteCapacityUnits
```

**確認するログ:**
```
CloudWatch Logs:
- /aws/lambda/crypto-watch-api-function
- /aws/lambda/crypto-watch-price-update-function
- フィルタパターン: "ProvisionedThroughputExceededException"
```

**初動対応ステップ:**

1. **スロットリングの原因特定**
   - 読み取りキャパシティ超過 or 書き込みキャパシティ超過
   - 特定のパーティションキーへのアクセス集中（ホットパーティション）
   - 突発的なトラフィック増加

2. **現在のキャパシティ確認**
   ```bash
   aws dynamodb describe-table --table-name crypto-watch-data
   ```
   - BillingMode: PAY_PER_REQUEST（オンデマンド）の場合、自動スケール
   - PROVISIONED の場合、キャパシティユニットを確認

3. **対応方針**

   **短期対応:**
   - Lambda関数のリトライロジックが自動的に対応
   - 一時的なスロットリングは許容範囲

   **中期対応（頻繁に発生する場合）:**
   - DynamoDBのキャパシティモードを確認
   - オンデマンドモードへの切り替えを検討
   - または、プロビジョニングキャパシティの増加

   **長期対応:**
   - アクセスパターンの見直し
   - キャッシュ戦略の改善（DynamoDB DAXの導入）
   - データモデルの最適化（ホットパーティション対策）

4. **影響範囲の確認**
   - エラー率: スロットリングによるエラーの割合
   - 影響期間: 継続時間
   - ユーザー体験: レスポンス遅延の程度

**エスカレーション条件:**
- スロットリングが30分以上継続
- エラー率が5%を超える

---

### 4. API Gateway 5xx Error Rate Alarm（Critical）

**アラート内容:**
- API Gatewayの5xxエラー率が10%を超えた状態が2分間継続

**確認するメトリクス:**
```
CloudWatch Metrics:
- AWS/ApiGateway > 5XXError
- AWS/ApiGateway > Count (総リクエスト数)
- AWS/ApiGateway > Latency
- AWS/ApiGateway > IntegrationLatency
```

**確認するログ:**
```
CloudWatch Logs:
- API Gateway アクセスログ
- /aws/lambda/crypto-watch-api-function
```

**初動対応ステップ:**

1. **エラーの種類を特定**
   - 502 Bad Gateway: Lambda関数のエラー、タイムアウト
   - 503 Service Unavailable: Lambda同時実行数の上限
   - 504 Gateway Timeout: Lambda実行時間が29秒を超過

2. **Lambda関数の状態確認**
   - Lambda Errorsメトリクスを確認
   - Lambda Throttlesメトリクスを確認（同時実行数制限）
   - Lambda Durationメトリクスを確認（タイムアウト）

3. **対応方針**

   **502エラー（Lambda関数エラー）:**
   - [Lambda Error Rate Alarm対応](#1-lambda-error-rate-alarmcritical)を参照

   **503エラー（同時実行数制限）:**
   - Lambda同時実行数の上限を確認
   - 予約済み同時実行数の設定を確認
   - トラフィックパターンの分析

   **504エラー（タイムアウト）:**
   - Lambda関数のタイムアウト設定を確認（現在25秒）
   - 外部API呼び出しの遅延を確認
   - DynamoDBクエリのパフォーマンスを確認

4. **即座の対応**
   - デプロイ直後の場合: ロールバック検討
   - トラフィック急増の場合: Lambda同時実行数の増加
   - 外部要因の場合: 根本原因の解決を待つ

**エスカレーション条件:**
- 5xxエラー率が20%を超える
- 10分以上継続
- ユーザーからの問い合わせが増加

---

### 5. API Latency P95 Alarm（Medium）

**アラート内容:**
- APIレスポンスのP95レイテンシが閾値（例: 2秒）を超えた

**確認するメトリクス:**
```
CloudWatch Metrics:
- AWS/ApiGateway > Latency (p95, p99)
- AWS/Lambda > Duration (p95, p99)
- Custom/CryptoWatch > DynamoDBQueryLatency
- Custom/CryptoWatch > ExternalApiLatency
```

**確認するログ:**
```
CloudWatch Logs:
- /aws/lambda/crypto-watch-api-function
- フィルタパターン: "duration" > 1000 (1秒以上)
```

**初動対応ステップ:**

1. **レイテンシの内訳を分析**
   - Lambda実行時間
   - DynamoDBクエリ時間
   - 外部API呼び出し時間（該当する場合）
   - ネットワーク時間

2. **ボトルネックの特定**
   - DynamoDBクエリが遅い: インデックスの最適化、キャッシュ戦略
   - Lambda実行が遅い: コードの最適化、メモリ増加
   - コールドスタート: Provisioned Concurrencyの検討

3. **対応方針**

   **短期対応:**
   - 一時的な遅延は許容範囲（P95が2秒以内）
   - トレンドを監視

   **中期対応（継続的に遅い場合）:**
   - Lambda関数のメモリを増加（現在512MB）
   - DynamoDB DAXの導入
   - キャッシュTTLの調整

   **長期対応:**
   - アーキテクチャの見直し
   - CloudFrontの導入
   - データモデルの最適化

4. **ユーザーへの影響**
   - P95が2秒以内: 許容範囲
   - P95が3秒以上: ユーザー体験に影響
   - P95が5秒以上: 深刻な問題

**エスカレーション条件:**
- P95レイテンシが5秒を超える
- 1時間以上継続
- ユーザーからの苦情

---

### 6. Lambda Throttle Alarm（High）

**アラート内容:**
- Lambda関数のスロットル（同時実行数制限）が10回以上発生

**確認するメトリクス:**
```
CloudWatch Metrics:
- AWS/Lambda > Throttles
- AWS/Lambda > ConcurrentExecutions
- AWS/Lambda > UnreservedConcurrentExecutions
```

**初動対応ステップ:**

1. **同時実行数の確認**
   ```bash
   aws lambda get-function-concurrency --function-name crypto-watch-api-function
   ```

2. **トラフィックパターンの分析**
   - 突発的なトラフィック増加か
   - 定常的な負荷増加か

3. **対応方針**

   **即座の対応:**
   - 予約済み同時実行数の増加
   - アカウント全体の同時実行数上限の確認

   **中期対応:**
   - Provisioned Concurrencyの設定
   - オートスケーリングの調整

4. **影響範囲**
   - スロットルされたリクエストは503エラーを返す
   - ユーザーはリトライが必要

**エスカレーション条件:**
- スロットルが継続的に発生
- 同時実行数上限の引き上げが必要

---

## ロールバック判断基準

### 自動ロールバック

以下の条件で**自動ロールバック**が実行されます：

| 条件 | 閾値 | 期間 |
|------|------|------|
| Lambda error rate | > 5% | 2分間 |
| API Gateway 5xx rate | > 10% | 2分間 |
| Lambda throttle count | > 10回 | 1分間 |

**自動ロールバックの動作:**
1. CloudWatch AlarmがALARM状態に遷移
2. CodeDeployが自動的にロールバックを開始
3. Lambda Aliasを前バージョンに切り替え（100%のトラフィック）
4. SNS経由でSlack/Emailに通知
5. GitHub Actionsジョブが失敗として記録

### 手動ロールバック

以下の場合は**手動ロールバック**を検討します：

**ケース1: デプロイ直後の問題（10分以内）**
- 自動ロールバックを待つ（2-3分）
- 自動ロールバックが発動しない場合、手動でロールバック

**手動ロールバック手順:**
```bash
# 1. 現在のデプロイIDを確認
aws deploy list-deployments --application-name crypto-watch-backend

# 2. ロールバックを実行
aws deploy stop-deployment --deployment-id <deployment-id> --auto-rollback-enabled

# 3. 前のバージョンに切り替え
aws lambda update-alias \
  --function-name crypto-watch-api-function \
  --name live \
  --function-version <previous-version>
```

**ケース2: 長期的な問題（10分以上経過）**
- 自動ロールバックは発動しない（閾値を超えていない）
- しかし、ユーザー体験が悪化している
- 判断基準:
  - エラー率が3%以上（閾値5%未満だが高い）
  - レイテンシが通常の2倍以上
  - ユーザーからの問い合わせが増加

**ケース3: 機能的な問題**
- エラーは発生していないが、機能が正しく動作していない
- データの不整合が発生
- セキュリティ上の問題が発見された

### ロールバック後の対応

1. **問題の調査**
   - CloudWatch Logsでエラーログを確認
   - X-Ray tracesで処理フローを分析
   - メトリクスで異常なパターンを特定

2. **修正の実装**
   - developブランチで修正を実装
   - ローカルでテスト
   - ステージング環境で検証

3. **再デプロイ**
   - 修正をmainブランチにマージ
   - ステージング環境で最終確認
   - 本番環境に再デプロイ

4. **ポストモーテム**
   - インシデントレポートを作成
   - 根本原因を文書化
   - 再発防止策を検討

---

## よくある問題と対処法

### 問題1: 外部APIのレート制限

**症状:**
- 外部API呼び出しが429エラーを返す
- 価格更新が失敗する

**対処法:**
1. 更新頻度を一時的に下げる（5分 → 10分）
2. 外部APIプランのアップグレードを検討
3. キャッシュTTLを延長（5分 → 10分）

### 問題2: DynamoDBのホットパーティション

**症状:**
- 特定のAPIキーへのアクセスが集中
- スロットリングが頻発

**対処法:**
1. アクセスパターンを分析
2. パーティションキーの設計を見直し
3. DynamoDB DAXの導入を検討

### 問題3: Lambdaコールドスタート

**症状:**
- 初回リクエストが遅い（2-3秒）
- P95レイテンシが高い

**対処法:**
1. Provisioned Concurrencyを設定
2. Lambda関数のメモリを増加
3. 依存関係を最小化

### 問題4: APIキーの漏洩

**症状:**
- 異常なアクセスパターン
- レート制限を頻繁に超過

**対処法:**
1. 該当APIキーを即座に無効化
2. アクセスログを分析
3. 新しいAPIキーを発行
4. セキュリティインシデントとして記録

---

## エスカレーションフロー

### レベル1: 運用担当者（初動対応）

**対応範囲:**
- アラートの確認と初動対応
- ログとメトリクスの確認
- 既知の問題の対処
- 自動ロールバックの監視

**エスカレーション条件:**
- 15分以内に解決できない
- 影響範囲が拡大
- 未知の問題

### レベル2: 開発チーム（技術調査）

**対応範囲:**
- 根本原因の調査
- コード修正の実装
- 手動ロールバックの実行
- 緊急パッチのデプロイ

**エスカレーション条件:**
- 1時間以内に解決できない
- アーキテクチャ変更が必要
- 外部サービスの問題

### レベル3: マネジメント（意思決定）

**対応範囲:**
- サービス停止の判断
- 外部コミュニケーション
- リソース追加の承認
- ポストモーテムのレビュー

---

## 連絡先

| 役割 | 連絡先 | 対応時間 |
|------|--------|---------|
| 運用担当者 | #crypto-watch-alerts | 24/7 |
| 開発チーム | #crypto-watch-dev | 営業時間 |
| オンコール | (設定予定) | 24/7 |

---

## 参考リソース

- [設計書](./design.md)
- [要件定義書](./requirements.md)
- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [AWS CloudWatch ダッシュボード](https://console.aws.amazon.com/cloudwatch/)
- [GitHub Actions ワークフロー](https://github.com/your-org/crypto-watch-backend/actions)
