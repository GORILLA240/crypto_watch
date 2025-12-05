# 実装タスクリスト

- [ ] 1. 基盤コンポーネントの実装
  - SafeAreaCalculator、ScreenSize、ResponsiveLayoutBuilderなどの基盤クラスを実装
  - _Requirements: 5.1, 5.2, 6.1_

- [ ] 1.1 SafeAreaCalculatorの実装
  - 円形画面の安全領域を計算するユーティリティクラスを作成
  - calculateSafeInsets、getMaxContentWidth、isInSafeAreaメソッドを実装
  - _Requirements: 5.1, 5.2_

- [ ] 1.2 ScreenSizeモデルの実装
  - 画面サイズ情報を表すモデルクラスを作成
  - 画面サイズカテゴリー（small/medium/large）の判定ロジックを実装
  - フォントサイズ、パディング、アイコンサイズの推奨値を提供
  - _Requirements: 6.1, 7.1_

- [ ] 1.3 ResponsiveLayoutBuilderの実装
  - 画面サイズに応じて動的にレイアウトを調整するビルダーウィジェットを作成
  - LayoutBuilderを使用して利用可能なサイズを取得
  - _Requirements: 6.1_

- [ ] 1.4 基盤コンポーネントのユニットテスト
  - SafeAreaCalculatorのテスト（円形・正方形画面）
  - ScreenSizeのテスト（カテゴリー判定）
  - _Requirements: 5.1, 6.1_

- [ ] 2. テキストオーバーフロー防止の実装
  - OptimizedTextWidgetを実装し、既存のTextウィジェットを置き換え
  - _Requirements: 1.1, 1.2, 1.5_

- [ ] 2.1 OptimizedTextWidgetの実装
  - テキストオーバーフローを防止する最適化されたウィジェットを作成
  - overflow: TextOverflow.ellipsis、maxLinesの設定
  - 自動フォントサイズ調整機能（autoScale）
  - _Requirements: 1.1, 1.2_

- [ ] 2.2 価格一覧画面のテキスト置き換え
  - PriceListScreenの既存Textウィジェットを OptimizedTextWidgetに置き換え
  - 通貨名、価格、変動率のテキスト表示を最適化
  - _Requirements: 1.1, 1.5_

- [ ] 2.3 価格詳細画面のテキスト置き換え
  - PriceDetailScreenの既存Textウィジェットを OptimizedTextWidgetに置き換え
  - 24時間高値、安値、出来高のテキスト表示を最適化
  - _Requirements: 2.1, 2.2_


- [ ] 2.4 テキストオーバーフロー防止のプロパティテスト
  - **Property 1: テキストオーバーフロー防止**
  - **Validates: Requirements 1.1, 1.5**

- [ ] 2.5 テキスト省略のプロパティテスト
  - **Property 2: 長いテキストの省略**
  - **Validates: Requirements 1.2**

- [ ] 3. レイアウトとナビゲーションの最適化
  - 設定アイコンの可視化、更新ボタンの削除、パディング・マージンの調整
  - _Requirements: 3.1, 4.1, 8.1, 8.2_

- [ ] 3.1 価格一覧画面のナビゲーションバー改善
  - 設定アイコンを右上に配置し、常に可視状態にする
  - タップ領域を44x44ピクセル以上確保
  - _Requirements: 3.1, 3.3, 3.5_

- [ ] 3.2 更新ボタンの削除
  - 画面右下の大きなFloatingActionButtonを削除
  - RefreshIndicatorでプルトゥリフレッシュ機能を強化
  - _Requirements: 4.1, 4.2_

- [ ] 3.3 パディングとマージンの調整
  - リストアイテムの上下パディングを8ピクセル以上に設定
  - 左右パディングを12ピクセル以上に設定
  - 画面端から8ピクセル以上の余白を確保
  - _Requirements: 8.1, 8.2, 8.5_

- [ ] 3.4 円形画面対応のレイアウト調整
  - SafeAreaCalculatorを使用して安全領域を計算
  - 重要な情報を画面中央の安全領域内に配置
  - _Requirements: 5.1, 5.2, 5.5_

- [ ] 3.5 最小タップ領域のプロパティテスト
  - **Property 3: 最小タップ領域の確保**
  - **Validates: Requirements 3.3, 12.1**

- [ ] 3.6 円形画面安全領域のプロパティテスト
  - **Property 4: 円形画面の安全領域**
  - **Validates: Requirements 5.2**

- [ ] 3.7 最小パディングのプロパティテスト
  - **Property 7: 最小パディング**
  - **Validates: Requirements 8.1**

- [ ] 4. チェックポイント - レイアウト最適化の確認
  - すべてのテストが通ることを確認し、ユーザーに質問があれば尋ねる


- [ ] 5. 通貨アイコン表示の統合
  - 既存のCryptoIconウィジェットを価格一覧画面に統合
  - _Requirements: 15.1, 15.2, 15.3_

- [ ] 5.1 価格一覧画面へのアイコン追加
  - CryptoIconウィジェットをリストアイテムの左端に配置
  - アイコンサイズを32x32ピクセルに設定
  - アイコンとテキストの間隔を8ピクセル確保
  - _Requirements: 15.1, 15.2, 15.6, 15.7_

- [ ] 5.2 アイコンプレースホルダーの確認
  - アイコン取得失敗時にティッカーシンボルの頭文字を表示
  - 円形の枠内に表示
  - _Requirements: 15.3, 15.4_

- [ ] 5.3 アイコン表示のウィジェットテスト
  - CryptoIconがアイコンを正しく表示することを確認
  - プレースホルダーが正しく表示されることを確認
  - _Requirements: 15.1, 15.4_

- [ ] 6. お気に入り管理機能の実装
  - FavoritesManagerを実装し、デフォルト通貨とカスタム通貨を統合管理
  - _Requirements: 17.1, 17.2, 17.3_

- [ ] 6.1 FavoritesManagerの実装
  - デフォルト通貨20種類の定義
  - getFavorites、addFavorite、removeFavoriteメソッドの実装
  - shared_preferencesでローカルストレージに保存
  - _Requirements: 17.1, 17.2, 17.6_

- [ ] 6.2 FavoritesCurrencyモデルの実装
  - symbol、isDefault、addedAt、displayOrderフィールドを持つモデルクラス
  - fromJson、toJsonメソッドの実装
  - _Requirements: 17.2_

- [ ] 6.3 FavoritesManagerのユニットテスト
  - お気に入りの追加・削除・取得のテスト
  - デフォルト通貨の初期化テスト
  - ローカルストレージの永続化テスト
  - _Requirements: 17.1, 17.2, 17.6_

- [ ] 7. 通貨検索機能の実装
  - CurrencySearchServiceとCurrencySearchScreenを実装
  - _Requirements: 16.1, 16.2, 16.4_

- [ ] 7.1 CurrencySearchResultモデルの実装
  - id、symbol、name、iconUrl、marketCapRankフィールドを持つモデルクラス
  - fromJson、toJsonメソッドの実装
  - _Requirements: 16.3_


- [ ] 7.2 CoinGeckoApiClientの拡張
  - searchCoinsメソッドの実装（/search エンドポイント）
  - fetchPriceBySymbolメソッドの実装
  - getCoinDetailsメソッドの実装
  - _Requirements: 16.4, 16.7_

- [ ] 7.3 CurrencySearchServiceの実装
  - searchCurrenciesメソッドの実装
  - getSuggestionsメソッドの実装（Streamベース）
  - デバウンス処理（300ms）の実装
  - 検索結果のキャッシング機能
  - _Requirements: 16.2, 18.1, 18.2, 18.3, 18.7_

- [ ] 7.4 SearchCacheの実装
  - インメモリキャッシュ（Map）の実装
  - TTL（5分）の設定
  - LRUアルゴリズムでの古いエントリ削除
  - _Requirements: 18.7_

- [ ] 7.5 CurrencySearchScreenの実装
  - 検索フィールドの実装
  - リアルタイムサジェストの表示
  - 検索結果リスト（最大10件）の表示
  - 通貨選択時のお気に入り追加
  - _Requirements: 16.1, 16.2, 16.3, 16.5, 16.6_

- [ ] 7.6 サジェスト結果のUI実装
  - 通貨名、ティッカーシンボル、アイコンを含むリストアイテム
  - 入力文字列のハイライト表示
  - 人気順または時価総額順でソート
  - _Requirements: 16.3, 18.4, 18.6_

- [ ] 7.7 通貨検索のユニットテスト
  - CurrencySearchServiceの検索機能テスト
  - デバウンス処理のテスト
  - キャッシング機能のテスト
  - _Requirements: 16.4, 18.3, 18.7_

- [ ] 7.8 サジェスト応答時間のプロパティテスト
  - **Property 11: サジェスト応答時間**
  - **Validates: Requirements 18.2**

- [ ] 7.9 検索結果キャッシングのプロパティテスト
  - **Property 12: 検索結果のキャッシング**
  - **Validates: Requirements 18.7**

- [ ] 8. カスタム通貨の統合
  - カスタム通貨とデフォルト通貨の統一的な扱いを実装
  - _Requirements: 17.3, 17.8, 17.9, 17.10_


- [ ] 8.1 カスタム通貨の価格データ取得
  - CoinGeckoApiClientを使用してカスタム通貨の価格を取得
  - デフォルト通貨と同じAPIエンドポイントを使用
  - _Requirements: 16.7, 17.10_

- [ ] 8.2 カスタム通貨のアイコン取得
  - CryptoIconウィジェットでカスタム通貨のアイコンを取得
  - CryptoCompare APIを使用（デフォルト通貨と同じ）
  - _Requirements: 15.8, 16.8, 17.8_

- [ ] 8.3 カスタム通貨の詳細画面対応
  - 価格詳細画面でカスタム通貨を表示
  - デフォルト通貨と同じレイアウトとスタイルを適用
  - _Requirements: 17.9, 17.10_

- [ ] 8.4 カスタム通貨のお気に入り・アラート機能
  - カスタム通貨でもお気に入り追加、アラート設定が可能
  - デフォルト通貨と同じ機能を提供
  - _Requirements: 17.10_

- [ ] 8.5 通貨アイコン取得統一性のプロパティテスト
  - **Property 8: 通貨アイコン取得の統一性**
  - **Validates: Requirements 15.8**

- [ ] 8.6 価格データ取得統一性のプロパティテスト
  - **Property 9: 価格データ取得の統一性**
  - **Validates: Requirements 16.7**

- [ ] 8.7 機能同等性のプロパティテスト
  - **Property 10: 機能の同等性**
  - **Validates: Requirements 17.10**

- [ ] 9. ユーザーによるフォントサイズ調整機能
  - FontSizeManagerを実装し、設定画面でフォントサイズを調整可能にする
  - _Requirements: 19.1, 19.2, 19.3_

- [ ] 9.1 FontSizeManagerの実装
  - FontSizeOptionの定義（small/normal/large/extraLarge）
  - getFontSizeOption、setFontSizeOptionメソッドの実装
  - getScaledFontSize、clampFontSizeメソッドの実装
  - shared_preferencesで設定を保存
  - _Requirements: 19.2, 19.6, 19.8, 19.9, 19.10, 19.11_

- [ ] 9.2 ScaledTextウィジェットの実装
  - FontSizeManagerを使用してフォントサイズをスケーリング
  - 最小フォントサイズ（12sp）を保証
  - すべてのTextウィジェットで使用可能
  - _Requirements: 19.3, 19.5_


- [ ] 9.3 設定画面へのフォントサイズ設定追加
  - フォントサイズ選択UI（小・標準・大・特大）の実装
  - 選択時のプレビュー表示
  - 設定変更時のレイアウト再計算
  - _Requirements: 19.1, 19.2, 19.7_

- [ ] 9.4 既存画面へのScaledText適用
  - 価格一覧画面、価格詳細画面、通貨検索画面のTextウィジェットを置き換え
  - テキストが画面外にはみ出さないように自動調整
  - _Requirements: 19.3, 19.4_

- [ ] 9.5 FontSizeManagerのユニットテスト
  - フォントサイズのスケーリングテスト
  - 最小フォントサイズの保証テスト
  - 設定の保存・読み込みテスト
  - _Requirements: 19.5, 19.6_

- [ ] 9.6 最小フォントサイズのプロパティテスト
  - **Property 6: 最小フォントサイズ**
  - **Validates: Requirements 7.1, 19.5**

- [ ] 10. エラーハンドリングの実装
  - ネットワークエラー、検索エラー、アイコン取得エラーの処理
  - _Requirements: 16.9, 16.10_

- [ ] 10.1 ネットワークエラーハンドリング
  - CoinGecko APIとCryptoCompare APIの接続失敗時の処理
  - ユーザーに分かりやすいエラーメッセージを表示
  - リトライボタンの提供
  - _Requirements: 16.10_

- [ ] 10.2 通貨検索エラーハンドリング
  - 検索結果0件時のメッセージ表示
  - 検索のヒント提供
  - 人気通貨の候補表示
  - _Requirements: 16.9_

- [ ] 10.3 アイコン取得エラーハンドリング
  - CryptoIconウィジェットでのエラー処理確認
  - プレースホルダー表示の確認
  - _Requirements: 15.4, 15.9_

- [ ] 10.4 エラーハンドリングのユニットテスト
  - ネットワークエラー時の動作テスト
  - 検索結果0件時の動作テスト
  - アイコン取得失敗時の動作テスト
  - _Requirements: 16.9, 16.10_

- [ ] 11. 最終チェックポイント - すべてのテストが通ることを確認
  - すべてのテストが通ることを確認し、ユーザーに質問があれば尋ねる

