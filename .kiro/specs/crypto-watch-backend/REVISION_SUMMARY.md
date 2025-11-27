# 仕様改訂サマリー（第2版）

## 改訂日時
2024-01-15

## 改訂の背景
ユーザーからの質問回答に基づき、以下の3点を明確化：
1. CI/CDツールの選定（GitHub Actions優先）
2. レスポンス最適化の方針（JSONキー名は可読性重視）
3. 自動ロールバックの実装方法（CloudWatch Alarms + CodeDeploy）

---

## 主要な変更点

### 1. CI/CDツールの決定

**採用技術: GitHub Actions**

**理由:**
- リポジトリとセットで管理しやすい
- YAMLでワークフローをコードとして管理
- AWS以外のサービスとの連携も柔軟
- デプロイはGitHub ActionsからAWS SAM/CloudFormationを呼び出す形

**実装方針:**
- テスト → ビルド → デプロイのパイプラインをGitHub Actionsで構築
- SAM CLIを使用してCloudFormationスタックをデプロイ
- CodeDeployを使用してLambda関数のトラフィックシフトとロールバックを実行

**代替案:**
- AWS CodePipelineも選択肢として設計書に記載
- ただし、実装タスクはGitHub Actionsベースで進める

---

### 2. レスポンス最適化の方針確定

**設計方針: JSONキー名は可読性重視**

**決定事項:**
- JSONキーの短縮（`symbol` → `s`など）は**採用しない**
- 人間が読めるキー名を維持（`symbol`, `price`, `change24h`など）

**理由:**
- フィールド数が限定的（6フィールド）であり、キー短縮の効果は小さい
- 可読性の低下によるデバッグ困難さのデメリットが大きい
- gzip圧縮により、繰り返されるキー名は効率的に圧縮される

**ペイロード削減戦略:**
1. **不要フィールドの排除**: 必須6フィールドのみ返す
2. **数値精度の制限**: 価格は小数点2桁、変動率は小数点1桁
3. **gzip圧縮**: Accept-Encodingヘッダーに基づいて圧縮

**期待効果:**
- 非圧縮: 単一暗号通貨で約150バイト
- gzip圧縮: 単一暗号通貨で約50-60バイト（60-70%削減）

---

### 3. 自動ロールバックの具体化

**実装方法: CloudWatch Alarms + CodeDeploy**

**アーキテクチャ:**
```
GitHub Actions
  ↓ (SAM deploy)
CloudFormation
  ↓ (creates)
CodeDeploy
  ↓ (traffic shifting)
Lambda Alias (live)
  ↓ (monitors)
CloudWatch Alarms
  ↓ (triggers rollback)
CodeDeploy (automatic rollback)
```

**トラフィックシフト:**
- Type: Linear10PercentEvery1Minute
- 10分かけて段階的に新バージョンへ移行
- 各ステップでCloudWatch Alarmsを監視

**ロールバックトリガー:**
| メトリクス | 閾値 | 期間 |
|-----------|------|------|
| Lambda Errors | > 5% | 2分間 |
| API Gateway 5xx | > 10% | 2分間 |
| Lambda Throttles | > 10回 | 1分間 |

**ロールバック実行:**
1. CloudWatch AlarmがALARM状態に遷移
2. CodeDeployが自動的にロールバックを開始
3. Lambda Aliasを即座に前バージョンに切り替え（100%のトラフィック）
4. SNS経由でSlack/Email通知を送信
5. インシデントレポートを自動生成

---

## 修正されたドキュメント

### design.md（設計書）

**修正箇所:**
1. **Response Optimization**セクション
   - JSONキー名は可読性重視の方針を明記
   - キー短縮を採用しない理由を追加
   - ペイロード削減戦略を3つに整理

2. **CI/CD Pipeline**セクション
   - GitHub Actionsを主要ツールとして明記
   - 詳細なワークフロー構成を追加
   - AWS CodePipelineは代替案として記載

3. **Deployment Process**セクション
   - GitHub Actionsベースのデプロイフローを詳細化
   - CodeDeployによるトラフィックシフトを説明
   - 自動ロールバックの3フェーズを明記

4. **Infrastructure as Code**セクション
   - SAMテンプレートの具体例を大幅に拡張
   - AutoPublishAliasとDeploymentPreferenceを追加
   - CloudWatch Alarmsの定義を追加

### tasks.md（実装タスクリスト）

**修正箇所:**
1. **タスク8**: レスポンス最適化
   - JSONキー名は可読性重視で維持することを明記
   - コンパクトモード（短縮JSONキー）の実装を削除

2. **タスク11**: AWS SAMテンプレート設定
   - Lambda AutoPublishAliasの設定を追加
   - CodeDeployのDeploymentPreferenceを追加
   - CloudWatch Alarmsの定義を追加

3. **タスク17**: CI/CDパイプライン構築
   - GitHub Actionsベースの詳細な実装内容を追加
   - 各ジョブ（テスト、ビルド、デプロイ）の具体的なステップを明記

4. **タスク18**: ゼロダウンタイムデプロイ
   - CodeDeployの設定内容を具体化
   - トラフィックシフトの詳細を追加

5. **タスク19**: 自動ロールバック
   - CloudWatch Alarmsの具体的な閾値を追加
   - CodeDeployとの連携方法を明記
   - インシデントレポート生成の詳細を追加

### CONTRIBUTING.md（開発ガイドライン）

**修正箇所:**
1. **デプロイメントプロセス**セクション
   - GitHub Actionsを採用した理由を追加
   - 各環境へのデプロイフローを詳細化
   - 自動ロールバックトリガーを明記

### CHANGELOG.md（変更履歴）

**追加内容:**
- 第2版の改訂履歴を追加
- 設計方針の明確化内容を記録

---

## 実装への影響

### 既存タスクへの影響
- **タスク8、11、17-19**が修正されましたが、既存の実装計画との互換性は維持されています
- 修正は主に詳細化と明確化であり、大きな方向転換はありません

### 新規に必要な作業
特になし。既存のタスクリストで実装可能です。

### 推奨される実装順序（変更なし）
1. タスク1-16: コア機能の実装
2. タスク17: CI/CDパイプラインの構築（GitHub Actions）
3. タスク18-19: デプロイメント機能の実装（CodeDeploy + CloudWatch Alarms）
4. タスク20: 昇格フローの整備
5. タスク21: ドキュメント整備

---

## 技術スタック確定

| カテゴリ | 技術 | 備考 |
|---------|------|------|
| CI/CD | GitHub Actions | 主要ツール |
| IaC | AWS SAM | CloudFormationベース |
| デプロイ | CodeDeploy | トラフィックシフトとロールバック |
| 監視 | CloudWatch Alarms | 自動ロールバックトリガー |
| 通知 | SNS + Slack/Email | デプロイ結果とインシデント |
| ランタイム | Python 3.11 | Lambda関数 |
| データベース | DynamoDB | シングルテーブル設計 |
| API | API Gateway | REST API |

---

## 次のステップ

1. ✅ 仕様改訂完了
2. ⏭️ タスク1から順次実装開始
3. ⏭️ 各タスク完了時にCONTRIBUTING.mdのチェックリストを使用
4. ⏭️ タスク17でGitHub Actionsワークフローを構築
5. ⏭️ タスク18-19でCodeDeployとCloudWatch Alarmsを設定
6. ⏭️ ステージング環境で自動ロールバックをテスト
7. ⏭️ 本番環境へのデプロイフローを検証

---

## 質問と回答の記録

### Q1: CI/CDツールの優先順位は？
**A:** GitHub Actionsを優先。理由は管理のしやすさ、柔軟性、コードとしての管理。

### Q2: JSONキーの短縮は実装する？
**A:** 実装しない。可読性重視で、gzip圧縮と不要フィールド削除で最適化。

### Q3: 自動ロールバックの実装方法は？
**A:** CloudWatch Alarms + CodeDeployの組み合わせで問題なし。GitHub ActionsからSAM deployを実行し、CodeDeployがトラフィック制御とロールバックを担当。

---

## 承認

- [x] ユーザー要件を反映
- [x] 設計書を更新
- [x] タスクリストを更新
- [x] ドキュメントを更新
- [x] 整合性を確認

**ステータス: 承認済み - 実装開始可能**
