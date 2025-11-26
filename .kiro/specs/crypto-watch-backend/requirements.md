# 要件定義書

## はじめに

crypto-watch-backendは、Flutterスマートウォッチアプリケーションに暗号通貨価格データを提供するサーバーレスAWSバックエンドサービスです。このシステムは、コンピューティングにAWS Lambda、HTTPエンドポイントにAPI Gateway、データストレージにDynamoDBを使用します。バックエンドは、限られた画面スペース、バッテリー効率、断続的な接続性などのスマートウォッチの制約に最適化されています。

## 用語集

- **Backend Service（バックエンドサービス）**: Lambda関数、API Gateway、DynamoDBで構成されるサーバーレスAWSインフラストラクチャ
- **Crypto Price Data（暗号通貨価格データ）**: 価格、時価総額、変動率を含む現在および過去の暗号通貨価格情報
- **API Gateway**: RESTful APIエンドポイントを作成・管理するAWSサービス
- **Lambda Function（Lambda関数）**: バックエンドロジックを実行するAWSサーバーレスコンピューティングサービス
- **DynamoDB**: 暗号通貨データを保存するAWS NoSQLデータベースサービス
- **Smartwatch Client（スマートウォッチクライアント）**: バックエンドAPIを利用するスマートウォッチデバイス上で動作するFlutterアプリケーション
- **Price Update（価格更新）**: 外部ソースから現在の暗号通貨価格を取得し、DynamoDBに保存するプロセス

## 要件

### 要件1

**ユーザーストーリー:** スマートウォッチユーザーとして、現在の暗号通貨価格を取得したい。そうすることで、手首で投資を監視できる。

#### 受入基準

1. WHEN Smartwatch Clientが現在価格をリクエストする THEN Backend Serviceは2秒以内にリクエストされた暗号通貨の価格データを返す
2. WHEN Backend Serviceが価格データを返す THEN Backend Serviceは各暗号通貨の現在価格、24時間変動率、時価総額を含める
3. WHEN Smartwatch Clientが複数の暗号通貨をリクエストする THEN Backend Serviceは単一のレスポンスでリクエストされたすべての暗号通貨のデータを返す
4. WHEN Backend Serviceがサポートされていない暗号通貨のリクエストを受信する THEN Backend Serviceはその暗号通貨が利用できないことを示すエラーレスポンスを返す
5. THE Backend Serviceは少なくともBitcoin、Ethereum、および時価総額上位20の暗号通貨をサポートする

### 要件2

**ユーザーストーリー:** スマートウォッチユーザーとして、最小限のバッテリー消費で素早くアプリを読み込みたい。そうすることで、デバイスに影響を与えずに頻繁に価格を確認できる。

#### 受入基準

1. WHEN Smartwatch Clientが価格データをリクエストする THEN Backend Serviceはデータが5分未満の場合、キャッシュされたデータを返す
2. WHEN キャッシュされたデータが5分より古い THEN Backend Serviceは外部ソースから新しいデータを取得し、キャッシュを更新する
3. THE Backend Serviceはデータ転送とバッテリー消費を削減するためにレスポンスペイロードサイズを最小化する
4. WHEN Backend Serviceが価格データを更新する THEN Backend Serviceはキャッシュ無効化のためのタイムスタンプを保存する
5. THE Backend Serviceはクライアントが圧縮をサポートしている場合、レスポンスデータを圧縮する

### 要件3

**ユーザーストーリー:** バックエンド管理者として、システムが自動的に暗号通貨価格を取得・更新することを望む。そうすることで、ユーザーは手動介入なしに常に最新のデータを持つことができる。

#### 受入基準

1. THE Backend Serviceは5分ごとに外部APIから更新された暗号通貨価格を取得する
2. WHEN Price Updateプロセスが実行される THEN Backend Serviceは取得したデータをタイムスタンプと共にDynamoDBに保存する
3. WHEN 外部API呼び出しが失敗する THEN Backend Serviceは指数バックオフで最大3回リトライする
4. WHEN すべてのリトライ試行が失敗する THEN Backend Serviceはエラーをログに記録し、キャッシュされたデータの提供を続ける
5. THE Backend Serviceは監視目的で最後に成功した更新のタイムスタンプを追跡する

### 要件4

**ユーザーストーリー:** バックエンド管理者として、APIが安全でレート制限されていることを望む。そうすることで、サービスが利用可能な状態を維持し、コストが管理される。

#### 受入基準

1. THE Backend Serviceはすべてのエンドポイントに対してAPIキー認証を実装する
2. WHEN リクエストに有効なAPIキーがない THEN Backend Serviceは401 Unauthorizedレスポンスでリクエストを拒否する
3. THE Backend ServiceはAPIキーごとに毎分100リクエストのレート制限を実施する
4. WHEN クライアントがレート制限を超える THEN Backend Serviceは429 Too Many Requestsレスポンスを返す
5. THE Backend Serviceは監視とデバッグのためにすべてのAPIリクエストをログに記録する

### 要件5

**ユーザーストーリー:** バックエンド管理者として、システムの健全性とパフォーマンスを監視したい。そうすることで、問題を迅速に特定し解決できる。

#### 受入基準

1. THE Backend ServiceはすべてのLambda関数の呼び出しを実行時間とステータスと共にログに記録する
2. WHEN エラーが発生する THEN Backend Serviceはスタックトレースを含む詳細なエラー情報をログに記録する
3. THE Backend ServiceはAPIリクエスト数、レイテンシ、エラー率のCloudWatchメトリクスを発行する
4. THE Backend ServiceはDynamoDBの読み取りおよび書き込み操作のCloudWatchメトリクスを発行する
5. THE Backend Serviceはシステムステータスを返すヘルスチェックエンドポイントを提供する

### 要件6

**ユーザーストーリー:** 開発者として、バックエンドがエラーを適切に処理することを望む。そうすることで、スマートウォッチアプリがユーザーに意味のあるフィードバックを提供できる。

#### 受入基準

1. WHEN バリデーションエラーが発生する THEN Backend Serviceはエラー詳細を含む400 Bad Requestレスポンスを返す
2. WHEN 内部エラーが発生する THEN Backend Serviceは機密情報を公開せずに500 Internal Server Errorレスポンスを返す
3. WHEN DynamoDB操作が失敗する THEN Backend Serviceは一時的なエラーをリトライし、永続的な失敗には適切なエラーレスポンスを返す
4. WHEN 外部API呼び出しがタイムアウトする THEN Backend Serviceは利用可能な場合はキャッシュされたデータを返し、キャッシュが存在しない場合はエラーレスポンスを返す
5. THE Backend Serviceはすべてのエンドポイントで一貫したエラーレスポンス形式を返す

### 要件7

**ユーザーストーリー:** 開発者として、バックエンドインフラストラクチャを簡単にデプロイ・更新したい。そうすることで、迅速に反復し、サービスを効率的に維持できる。

#### 受入基準

1. THE Backend ServiceはAWS SAMまたはCDKを使用したInfrastructure as Codeで定義される
2. WHEN インフラストラクチャの変更が行われる THEN Backend ServiceはCI/CDパイプラインを通じた自動デプロイをサポートする
3. THE Backend Serviceは開発、ステージング、本番を含む複数のデプロイ環境をサポートする
4. WHEN 更新をデプロイする THEN Backend Serviceはゼロダウンタイムデプロイを実行する
5. THE Backend Serviceは失敗したデプロイのためのロールバック機能を含む
