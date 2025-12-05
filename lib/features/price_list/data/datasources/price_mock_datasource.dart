import 'dart:math';
import '../models/crypto_price_model.dart';
import 'price_remote_datasource.dart';

/// モックデータを返すデータソース（開発・テスト用）
class PriceMockDataSource implements PriceRemoteDataSource {
  final Random _random = Random();
  final Map<String, CryptoPriceModel> _mockPrices = {};

  PriceMockDataSource() {
    _initializeMockData();
  }

  /// モックデータを初期化
  void _initializeMockData() {
    final cryptoData = {
      'BTC': {'name': 'Bitcoin', 'basePrice': 50000.0},
      'ETH': {'name': 'Ethereum', 'basePrice': 3000.0},
      'XRP': {'name': 'Ripple', 'basePrice': 0.5},
      'BNB': {'name': 'Binance Coin', 'basePrice': 400.0},
      'SOL': {'name': 'Solana', 'basePrice': 100.0},
      'ADA': {'name': 'Cardano', 'basePrice': 0.45},
      'DOT': {'name': 'Polkadot', 'basePrice': 7.0},
      'DOGE': {'name': 'Dogecoin', 'basePrice': 0.08},
      'AVAX': {'name': 'Avalanche', 'basePrice': 35.0},
      'MATIC': {'name': 'Polygon', 'basePrice': 0.8},
      'LINK': {'name': 'Chainlink', 'basePrice': 15.0},
      'UNI': {'name': 'Uniswap', 'basePrice': 6.0},
      'LTC': {'name': 'Litecoin', 'basePrice': 90.0},
      'ATOM': {'name': 'Cosmos', 'basePrice': 10.0},
      'XLM': {'name': 'Stellar', 'basePrice': 0.12},
      'ALGO': {'name': 'Algorand', 'basePrice': 0.18},
      'VET': {'name': 'VeChain', 'basePrice': 0.025},
      'ICP': {'name': 'Internet Computer', 'basePrice': 5.0},
      'FIL': {'name': 'Filecoin', 'basePrice': 4.5},
      'TRX': {'name': 'TRON', 'basePrice': 0.1},
    };

    for (final entry in cryptoData.entries) {
      final symbol = entry.key;
      final data = entry.value;
      final basePrice = data['basePrice'] as double;
      
      // ランダムな変動を追加（±10%）
      final priceVariation = 1.0 + (_random.nextDouble() * 0.2 - 0.1);
      final price = basePrice * priceVariation;
      
      // ランダムな24時間変動率（-10% ~ +10%）
      final change24h = _random.nextDouble() * 20.0 - 10.0;
      
      // ランダムな時価総額
      final marketCap = price * (_random.nextDouble() * 1000000000 + 100000000);

      _mockPrices[symbol] = CryptoPriceModel(
        symbol: symbol,
        name: data['name'] as String,
        price: price,
        change24h: change24h,
        marketCap: marketCap,
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// 価格データを少し変動させる（リフレッシュをシミュレート）
  void _updatePrices() {
    for (final symbol in _mockPrices.keys) {
      final current = _mockPrices[symbol]!;
      
      // 小さな変動を追加（±2%）
      final priceChange = 1.0 + (_random.nextDouble() * 0.04 - 0.02);
      final newPrice = current.price * priceChange;
      
      // 変動率を更新
      final change24h = current.change24h + (_random.nextDouble() * 2.0 - 1.0);
      
      _mockPrices[symbol] = CryptoPriceModel(
        symbol: current.symbol,
        name: current.name,
        price: newPrice,
        change24h: change24h.clamp(-15.0, 15.0), // -15% ~ +15%の範囲に制限
        marketCap: current.marketCap,
        lastUpdated: DateTime.now(),
      );
    }
  }

  @override
  Future<List<CryptoPriceModel>> getPrices(List<String> symbols) async {
    // ネットワーク遅延をシミュレート
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(200)));
    
    // 価格を更新
    _updatePrices();
    
    // リクエストされたシンボルの価格を返す
    final result = <CryptoPriceModel>[];
    for (final symbol in symbols) {
      if (_mockPrices.containsKey(symbol)) {
        result.add(_mockPrices[symbol]!);
      }
    }
    
    return result;
  }

  @override
  Future<List<CryptoPriceModel>> getAllPrices() async {
    // ネットワーク遅延をシミュレート
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(200)));
    
    // 価格を更新
    _updatePrices();
    
    // すべての価格を返す
    return _mockPrices.values.toList();
  }

  @override
  Future<CryptoPriceModel> getPriceBySymbol(String symbol) async {
    // ネットワーク遅延をシミュレート
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(100)));
    
    // 価格を更新
    _updatePrices();
    
    if (!_mockPrices.containsKey(symbol)) {
      throw Exception('シンボル $symbol が見つかりません');
    }
    
    return _mockPrices[symbol]!;
  }
}
