# 開発ガイドライン

このドキュメントは、crypto-watch-backendプロジェクトに貢献する開発者向けのガイドラインです。

## テストポリシー

### 実装完了の定義

機能実装が完了しても、対応するテストが書かれるまでは「完了」とみなしません。すべてのプルリクエストは、新規コードに対するテストを含む必要があります。

### テスト作成のタイミング

| テストタイプ | 作成タイミング |
|------------|--------------|
| **ユニットテスト** | 各関数/メソッドの実装直後 |
| **プロパティテスト** | コンポーネント全体の実装完了後 |
| **統合テスト** | 複数コンポーネントの統合完了後 |

### テスト作成順序ガイドライン

```
1. 実装タスク完了
   ↓
2. ユニットテスト作成（エッジケース、エラーケース）
   ↓
3. プロパティテスト作成（設計書のプロパティに対応）
   ↓
4. ローカルでテスト実行・修正
   ↓
5. 統合テスト作成（該当する場合）
   ↓
6. コミット・プッシュ
```

### テストカバレッジ目標

- **ユニットテスト**: 最低80%のコードカバレッジ
- **プロパティテスト**: 設計書の全プロパティをカバー
- **統合テスト**: 主要なユーザーフローをカバー

### テスト実行タイミング

- **ローカル**: コミット前に全テストを実行
  ```bash
  python -m pytest tests/
  ```
- **CI/CD**: プッシュ時に自動実行
- **デプロイ前**: 全テストが合格していることを確認

### テストの命名規則

- **ユニットテスト**: `test_<function_name>_<scenario>`
  ```python
  def test_format_price_rounds_to_two_decimals():
      ...
  ```

- **プロパティテスト**: `test_property_<number>_<description>` + コメントで設計書参照
  ```python
  # Feature: crypto-watch-backend, Property 1: Complete response data structure
  def test_property_1_response_includes_all_fields():
      ...
  ```

- **統合テスト**: `test_integration_<flow_name>`
  ```python
  def test_integration_price_retrieval_flow():
      ...
  ```

### テスト失敗時の対応

1. テストが失敗した場合、**実装を修正**してテストを合格させる
2. テストが不適切な場合のみ、テストを修正する
3. テストをスキップ/無効化することは**原則禁止**

### タスク完了チェックリスト

各タスクを完了する際は、以下のチェックリストを使用してください：

```
タスクX: [タスク名]
□ 機能実装完了
□ ユニットテスト作成
□ プロパティテスト作成（該当する場合）
□ すべてのテストが合格
□ コードカバレッジ目標達成
□ コードレビュー完了
□ ドキュメント更新（必要な場合）
✓ タスク完了
```

## コーディング規約

### Python スタイルガイド

- PEP 8に準拠
- 型ヒントを使用（Python 3.11+）
- Docstringはすべての公開関数に記述

```python
def format_price(price: float) -> str:
    """
    価格を小数点以下2桁にフォーマットします。
    
    Args:
        price: フォーマットする価格
        
    Returns:
        フォーマットされた価格文字列
    """
    return f"{price:.2f}"
```

### エラーハンドリング

- カスタム例外クラスを使用
- エラーメッセージは明確で具体的に
- スタックトレースを適切にログ記録

```python
class InvalidSymbolError(ValueError):
    """サポートされていない暗号通貨シンボルのエラー"""
    pass
```

### ログ記録

- 構造化JSONログを使用
- ログレベルを適切に設定（DEBUG/INFO/WARNING/ERROR）
- 機密情報（APIキー等）をログに含めない

```python
import logging
import json

logger = logging.getLogger(__name__)

logger.info(json.dumps({
    "event": "price_update",
    "symbol": "BTC",
    "price": 45000.50,
    "timestamp": "2024-01-15T10:30:00Z"
}))
```

## プルリクエストプロセス

1. **ブランチ作成**: `feature/<task-number>-<description>` または `fix/<issue-number>-<description>`
2. **実装とテスト**: 上記のテストポリシーに従う
3. **コミット**: 明確なコミットメッセージを記述
   ```
   feat: Add response compression for smartwatch optimization
   
   - Implement gzip compression detection
   - Add Content-Encoding header
   - Reduce payload size by ~60%
   
   Closes #123
   ```
4. **プッシュとPR作成**: テンプレートに従ってPRを作成
5. **コードレビュー**: レビュアーのフィードバックに対応
6. **マージ**: すべてのチェックが合格後にマージ

## デプロイメントプロセス

### CI/CDツール

本プロジェクトは**GitHub Actions**をCI/CDツールとして採用しています。

**採用理由:**
- リポジトリとセットで管理しやすい
- YAMLでワークフローをコードとして管理
- AWS以外のサービスとの連携も柔軟
- デプロイはGitHub ActionsからAWS SAM/CloudFormationを呼び出す形

### 開発環境

- `develop` ブランチへのプッシュで自動デプロイ
- GitHub Actionsがテスト → ビルド → デプロイを実行
- スモークテストが自動実行
- 失敗時はSlack通知

### ステージング環境

- `main` ブランチへのマージで自動デプロイ
- GitHub Actionsが全テストを実行
- 統合テストとロードテストが自動実行
- 検証チェックリストを確認
- 本番デプロイの承認待ち状態に

### 本番環境

**デプロイフロー:**
1. ステージング環境での検証完了後、GitHub Actionsの`production`環境で手動承認
2. SAM deployがCodeDeployを使用してデプロイ開始
3. ゼロダウンタイムデプロイ（トラフィックシフト）:
   - Linear10PercentEvery1Minute
   - 10分かけて段階的に新バージョンへ移行
4. CloudWatch Alarmsがメトリクスを監視:
   - Lambda Errors
   - API Gateway 5xx
   - Lambda Throttles
5. 異常検知時はCodeDeployが自動ロールバック
6. デプロイ成功/失敗をSlack通知

**自動ロールバックトリガー:**
- Lambda error rate > 5% for 2 minutes
- API Gateway 5xx rate > 10% for 2 minutes
- Lambda throttle count > 10 in 1 minute

**ロールバック後の対応:**
1. CloudWatch Logsで問題の原因を調査
2. 修正をdevelopブランチで実装・テスト
3. ステージング環境で検証
4. 再度本番デプロイを試行

## トラブルシューティング

### テストが失敗する場合

1. ローカルで再現できるか確認
2. エラーメッセージとスタックトレースを確認
3. 関連するログを確認
4. 必要に応じてデバッガーを使用

### デプロイが失敗する場合

1. CloudFormationスタックのイベントを確認
2. Lambda関数のログを確認
3. IAM権限を確認
4. 必要に応じてロールバック

## 参考資料

- [要件定義書](./requirements.md)
- [設計書](./design.md)
- [実装タスク](./tasks.md)
- [AWS SAM ドキュメント](https://docs.aws.amazon.com/serverless-application-model/)
- [Python Hypothesis ドキュメント](https://hypothesis.readthedocs.io/)
