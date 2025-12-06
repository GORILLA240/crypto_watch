# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Flutterテストスイートの追加
  - ユニットテスト（alerts, favorites, price_list, settings）
  - コアユーティリティテスト（currency_formatter）
  - ネットワークレイヤーテスト（api_client）
- 環境変数管理の改善
  - `.env.example`ファイルの追加
  - API URLとAPIキーの環境変数化
- ドキュメントの整理と拡充
  - `README.md`の全面改訂
  - `docs/SUPPORTED_CURRENCIES.md`の追加
  - `backend/docs/ARCHITECTURE.md`の追加
  - `backend/docs/INDEX.md`の追加
  - 実装履歴ドキュメントを`backend/docs/history/`に移動

### Changed
- エラーコードの統一
  - バックエンドのエラーコード体系に合わせて修正
  - `AUTH_ERROR` → `UNAUTHORIZED`
  - `RATE_LIMIT` → `RATE_LIMIT_EXCEEDED`
  - `SERVER_ERROR` → `INTERNAL_ERROR`
- レスポンス形式の統一
  - バックエンドの標準形式`{"data": [...], "timestamp": "..."}`に統一
  - 不要な後方互換性コードを削減
- 依存性注入の修正
  - `PriceListBloc`を`registerLazySingleton`から`registerFactory`に変更
  - 設定Blocは引き続きシングルトンパターンを使用
- 環境設定の統一
  - dev環境のレート制限とキャッシュTTLを本番環境と同じ値に変更
  - 環境変数名を`LOG_LEVEL`に統一（`LogLevel`パラメータを削除）
- サポート通貨リストの管理改善
  - バックエンドとフロントエンドの同期に関するコメント追加
  - 将来的なAPI経由での動的取得に関するドキュメント追加

### Fixed
- APIクライアントのエラーメッセージパース
  - `message`フィールドから`error`フィールドに変更
  - バックエンドのレスポンス形式と一致

### Documentation
- プロジェクト構造の明確化
- セットアップ手順の詳細化
- API仕様の整理
- アーキテクチャドキュメントの追加
- トラブルシューティングガイドの追加

## [1.0.0] - 2024-12

### Added
- 初回リリース
- 暗号通貨価格追跡機能
- お気に入り管理機能
- 価格アラート機能
- スマートウォッチ対応
- カスタム通貨検索機能
- AWSサーバーレスバックエンド
- DynamoDBによるデータ永続化
- EventBridgeによる定期価格更新
- CloudWatchモニタリング

[Unreleased]: https://github.com/yourusername/crypto-watch/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/crypto-watch/releases/tag/v1.0.0
