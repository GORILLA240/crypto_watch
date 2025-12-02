---
inclusion: always
---

# プロジェクト構造とアーキテクチャパターン

## モノレポ構成

Flutterフロントエンド（ルート）とAWSサーバーレスバックエンド（`backend/`）のモノレポ。

## Flutter命名規約とパターン

- ファイル名: `snake_case.dart`
- クラス名: `PascalCase`
- 可能な限り`const`コンストラクタを使用
- ダークテーマ（黒背景）を維持
- Material Designコンポーネントを使用
- 状態管理: `StatefulWidget`

新機能追加時:
- `lib/features/{feature_name}/`に配置（ウィジェット、モデル、サービスを含む）
- テストは`test/features/{feature_name}/`に追加

## Python/Backend命名規約

- ファイル/関数: `snake_case`
- クラス: `PascalCase`
- 定数: `UPPER_SNAKE_CASE`
- 型ヒント必須（MyPy検証）
- データモデルは`@dataclass`を使用
- 行の長さ: 100文字（Black）

## バックエンドディレクトリ構造

- `backend/src/api/` - API Lambda（HTTPハンドラー）
- `backend/src/update/` - 価格更新Lambda（EventBridge）
- `backend/src/shared/` - 共有Lambdaレイヤー（コード重複削減）
- `backend/tests/` - unit/integration/property-based tests
- `backend/scripts/` - デプロイ/APIキー管理
- `backend/docs/` - 運用ドキュメント

## 重要なアーキテクチャパターン

### Lambdaレイヤーパターン
共有コードは`backend/src/shared/`に配置。新機能追加時は適切なモジュールに配置し、両Lambda関数の`requirements.txt`は更新しない（レイヤーに依存）。

### シングルテーブルDynamoDB設計
テーブル: `crypto-watch-data-{environment}`

キーパターン:
- 価格: `PK=PRICE#{symbol}`, `SK=METADATA`
- APIキー: `PK=APIKEY#{keyId}`, `SK=METADATA`
- レート制限: `PK=APIKEY#{keyId}`, `SK=RATELIMIT#{minute}`

新データタイプ追加時:
1. `PK={TYPE}#{id}`, `SK=METADATA`パターンを使用
2. `backend/src/shared/models.py`にデータクラス定義
3. `backend/src/shared/db.py`にアクセスメソッド追加

### 共有モジュールの責務（backend/src/shared/）

- `models.py` - データモデル（`@dataclass`）
- `db.py` - DynamoDB操作とシリアライゼーション
- `auth.py` - 認証/認可/レート制限
- `cache.py` - キャッシュ管理
- `external_api.py` - 外部APIクライアント（リトライロジック）
- `errors.py` - 例外階層と`format_error_response()`
- `utils.py` - ログ、タイムスタンプ、APIキーマスキング

新機能は適切なモジュールに配置。複数責務にまたがる場合は新モジュール作成。常に型ヒントとdocstringを追加。

### エラーハンドリング
`backend/src/shared/errors.py`のカスタム例外を使用:
- 基底: `CryptoWatchError`
- 派生: `AuthenticationError`, `RateLimitError`, `ValidationError`等
- HTTPマッピング: 400（バリデーション）、401（認証）、429（レート制限）、500（内部）、503（外部API）

### テスト要件
新コード追加時は必ず以下を作成:
1. ユニットテスト（`backend/tests/unit/`）
2. プロパティベーステスト（Hypothesis）
3. 統合テスト（`backend/tests/integration/`、moto使用）

`backend/tests/conftest.py`の共有フィクスチャを再利用。カバレッジ目標: 80%以上。

## 環境管理

3環境: `dev`（開発）、`staging`（検証）、`prod`（本番）

リソース命名: すべて`{resource}-{environment}`サフィックス
- DynamoDB: `crypto-watch-data-{env}`
- Lambda: `crypto-watch-api-{env}`, `crypto-watch-update-{env}`
- API Gateway: `crypto-watch-api-{env}`

環境設定: `backend/samconfig-{env}.toml`

新パラメータ追加時は全環境設定ファイルと`backend/template.yaml`を更新。

## デプロイワークフロー（厳守）

1. `dev`でテスト → 2. `staging`で検証 → 3. `prod`へプロモート

```bash
cd backend
make deploy-dev      # または ./scripts/deploy.sh dev
make deploy-staging
make deploy-prod
```

API変更時:
- バックエンドを先にデプロイ（後方互換性維持）
- 破壊的変更は避ける（APIバージョニング未実装）
- ロールバック手順を準備（`backend/docs/ROLLBACK_VERIFICATION.md`）

## 参照ドキュメント

- `backend/README.md` - API仕様とセットアップ
- `backend/docs/API_KEY_MANAGEMENT.md` - APIキー管理
- `backend/docs/STAGING_TO_PROD_PROMOTION.md` - プロモーション手順
