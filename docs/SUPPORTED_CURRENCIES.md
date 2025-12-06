# サポート通貨リスト管理

## 概要

Crypto Watchでサポートされる暗号通貨のリストは、以下の3箇所で管理されています：

1. **バックエンド（真実の源）**: `backend/template.yaml` - `SupportedSymbols`パラメータ
2. **バックエンドコード**: `backend/src/api/handler.py` - `SUPPORTED_SYMBOLS`定数
3. **フロントエンド**: `lib/core/constants/api_constants.dart` - `supportedSymbols`定数

## 現在のサポート通貨（20種類）

| シンボル | 名称 | CoinGecko ID |
|---------|------|--------------|
| BTC | Bitcoin | bitcoin |
| ETH | Ethereum | ethereum |
| ADA | Cardano | cardano |
| BNB | Binance Coin | binancecoin |
| XRP | XRP | ripple |
| SOL | Solana | solana |
| DOT | Polkadot | polkadot |
| DOGE | Dogecoin | dogecoin |
| AVAX | Avalanche | avalanche-2 |
| MATIC | Polygon | matic-network |
| LINK | Chainlink | chainlink |
| UNI | Uniswap | uniswap |
| LTC | Litecoin | litecoin |
| ATOM | Cosmos | cosmos |
| XLM | Stellar | stellar |
| ALGO | Algorand | algorand |
| VET | VeChain | vechain |
| ICP | Internet Computer | internet-computer |
| FIL | Filecoin | filecoin |
| TRX | TRON | tron |

## 新しい通貨の追加手順

### 1. バックエンドの更新

#### a. template.yamlの更新

```yaml
SupportedSymbols:
  Type: String
  Default: BTC,ETH,ADA,BNB,XRP,SOL,DOT,DOGE,AVAX,MATIC,LINK,UNI,LTC,ATOM,XLM,ALGO,VET,ICP,FIL,TRX,NEW_SYMBOL
```

#### b. handler.pyの更新

```python
SUPPORTED_SYMBOLS = {
    'BTC', 'ETH', 'ADA', 'BNB', 'XRP', 'SOL', 'DOT', 'DOGE', 
    'AVAX', 'MATIC', 'LINK', 'UNI', 'LTC', 'ATOM', 'XLM', 
    'ALGO', 'VET', 'ICP', 'FIL', 'TRX', 'NEW_SYMBOL'
}
```

#### c. external_api.pyの更新

```python
SYMBOL_MAPPING = {
    # ... existing mappings ...
    'NEW_SYMBOL': 'coingecko-id',
}

NAME_MAPPING = {
    # ... existing mappings ...
    'NEW_SYMBOL': 'Full Name',
}
```

### 2. フロントエンドの更新

#### lib/core/constants/api_constants.dartの更新

```dart
static const List<String> supportedSymbols = [
  'BTC', 'ETH', 'ADA', 'BNB', 'XRP', 'SOL', 'DOT', 'DOGE',
  'AVAX', 'MATIC', 'LINK', 'UNI', 'LTC', 'ATOM', 'XLM',
  'ALGO', 'VET', 'ICP', 'FIL', 'TRX', 'NEW_SYMBOL',
];
```

### 3. テストの更新

#### バックエンドテスト

- `backend/tests/unit/test_shared.py`: テストケースに新しいシンボルを追加
- `backend/tests/integration/test_e2e.py`: 統合テストに新しいシンボルを追加

#### フロントエンドテスト

- 該当するテストファイルに新しいシンボルのテストケースを追加

### 4. ドキュメントの更新

- `backend/README.md`: サポート通貨リストを更新
- このファイル（`docs/SUPPORTED_CURRENCIES.md`）: テーブルを更新

### 5. デプロイ

```bash
# バックエンドのデプロイ
cd backend
make deploy-dev
make deploy-staging
make deploy-prod

# フロントエンドのビルド
cd ..
flutter build apk --dart-define=API_BASE_URL=... --dart-define=API_KEY=...
```

## 将来の改善案

### APIから動的に取得

現在は静的リストですが、将来的には以下のような実装を推奨します：

1. バックエンドに `/supported-symbols` エンドポイントを追加
2. フロントエンドは起動時にこのエンドポイントを呼び出し
3. 取得したリストをキャッシュして使用

これにより、フロントエンドの更新なしに新しい通貨を追加できます。

### 実装例

#### バックエンド

```python
def get_supported_symbols(event, context):
    symbols = os.environ.get('SUPPORTED_SYMBOLS', '').split(',')
    return {
        'statusCode': 200,
        'body': json.dumps({
            'symbols': symbols,
            'timestamp': get_current_timestamp_iso()
        })
    }
```

#### フロントエンド

```dart
class CurrencyService {
  Future<List<String>> fetchSupportedSymbols() async {
    final response = await apiClient.get('/supported-symbols');
    final symbols = (response['symbols'] as List).cast<String>();
    await localStorage.saveSupportedSymbols(symbols);
    return symbols;
  }
}
```

## 注意事項

- 新しい通貨を追加する際は、CoinGecko APIでサポートされているか確認してください
- シンボルは大文字で統一してください
- バックエンドとフロントエンドの同期を忘れずに行ってください
- 本番環境へのデプロイ前に、dev環境とstaging環境で十分にテストしてください
