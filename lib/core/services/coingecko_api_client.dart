import 'dart:convert';
import 'package:http/http.dart' as http;
import '../error/exceptions.dart';
import '../models/currency_search_result.dart';
import '../../features/price_list/data/models/crypto_price_model.dart';

/// CoinGecko APIクライアント
/// 通貨検索と価格データ取得を担当
class CoinGeckoApiClient {
  final http.Client client;
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  static const Duration _timeout = Duration(seconds: 10);

  CoinGeckoApiClient({http.Client? client}) : client = client ?? http.Client();

  /// 通貨を検索
  /// [query] 検索クエリ（通貨名またはシンボル）
  /// [limit] 最大結果数（デフォルト: 10）
  Future<List<CurrencySearchResult>> searchCoins(
    String query, {
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {'query': query},
      );

      final response = await client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final coins = data['coins'] as List<dynamic>?;

        if (coins == null || coins.isEmpty) {
          return [];
        }

        // 結果を制限して返す
        return coins
            .take(limit)
            .map((coin) => CurrencySearchResult.fromJson(coin as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 429) {
        throw RateLimitException(
          message: 'CoinGecko APIのレート制限に達しました',
        );
      } else {
        throw ServerException(
          message: 'CoinGecko APIエラー: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on RateLimitException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: '通貨検索に失敗しました',
        originalError: e,
      );
    }
  }

  /// シンボルで価格データを取得
  /// [symbol] 通貨シンボル（例: "BTC"）
  Future<CryptoPriceModel> fetchPriceBySymbol(String symbol) async {
    try {
      // CoinGecko APIでは、シンボルではなくIDで検索する必要がある
      // まず検索してIDを取得
      final searchResults = await searchCoins(symbol, limit: 1);
      
      if (searchResults.isEmpty) {
        throw ServerException(
          message: 'シンボル $symbol が見つかりません',
        );
      }

      final coinId = searchResults.first.id;
      return await getCoinDetails(coinId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(
        message: 'シンボル $symbol の価格データ取得に失敗しました',
        originalError: e,
      );
    }
  }

  /// コインの詳細情報を取得
  /// [coinId] CoinGeckoのコインID（例: "bitcoin"）
  Future<CryptoPriceModel> getCoinDetails(String coinId) async {
    try {
      final uri = Uri.parse('$_baseUrl/coins/$coinId').replace(
        queryParameters: {
          'localization': 'false',
          'tickers': 'false',
          'market_data': 'true',
          'community_data': 'false',
          'developer_data': 'false',
          'sparkline': 'false',
        },
      );

      final response = await client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return _parseCoinDetails(data);
      } else if (response.statusCode == 429) {
        throw RateLimitException(
          message: 'CoinGecko APIのレート制限に達しました',
        );
      } else {
        throw ServerException(
          message: 'CoinGecko APIエラー: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on RateLimitException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'コイン詳細の取得に失敗しました',
        originalError: e,
      );
    }
  }

  /// CoinGecko APIのレスポンスをCryptoPriceModelに変換
  CryptoPriceModel _parseCoinDetails(Map<String, dynamic> data) {
    try {
      final symbol = (data['symbol'] as String).toUpperCase();
      final name = data['name'] as String;
      final marketData = data['market_data'] as Map<String, dynamic>;
      
      final currentPrice = marketData['current_price'] as Map<String, dynamic>;
      final priceUsd = (currentPrice['usd'] as num).toDouble();
      
      final priceChange24h = marketData['price_change_percentage_24h'] as num?;
      final change24h = priceChange24h?.toDouble() ?? 0.0;
      
      final marketCapData = marketData['market_cap'] as Map<String, dynamic>?;
      final marketCap = marketCapData != null 
          ? (marketCapData['usd'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      return CryptoPriceModel(
        symbol: symbol,
        name: name,
        price: priceUsd,
        change24h: change24h,
        marketCap: marketCap,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw ParseException(
        message: 'コイン詳細のパースに失敗しました',
        originalError: e,
      );
    }
  }

  /// クライアントをクローズ
  void dispose() {
    client.close();
  }
}
