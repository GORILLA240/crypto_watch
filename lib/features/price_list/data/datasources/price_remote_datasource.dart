import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/coingecko_api_client.dart';
import '../models/crypto_price_model.dart';

/// 価格データのリモートデータソース抽象クラス
abstract class PriceRemoteDataSource {
  /// 指定されたシンボルの価格データを取得
  Future<List<CryptoPriceModel>> getPrices(List<String> symbols);

  /// すべてのサポートされているシンボルの価格データを取得
  Future<List<CryptoPriceModel>> getAllPrices();

  /// 単一のシンボルの価格データを取得
  Future<CryptoPriceModel> getPriceBySymbol(String symbol);
}

/// 価格データのリモートデータソース実装
class PriceRemoteDataSourceImpl implements PriceRemoteDataSource {
  final ApiClient apiClient;
  final CoinGeckoApiClient? coinGeckoClient;

  PriceRemoteDataSourceImpl({
    required this.apiClient,
    this.coinGeckoClient,
  });

  @override
  Future<List<CryptoPriceModel>> getPrices(List<String> symbols) async {
    try {
      // デフォルト通貨とカスタム通貨を分離（要件 16.7, 17.10）
      final defaultSymbols = symbols
          .where((s) => ApiConstants.supportedSymbols.contains(s.toUpperCase()))
          .toList();
      final customSymbols = symbols
          .where((s) => !ApiConstants.supportedSymbols.contains(s.toUpperCase()))
          .toList();

      final allPrices = <CryptoPriceModel>[];

      // デフォルト通貨: バックエンドAPIから取得
      if (defaultSymbols.isNotEmpty) {
        final symbolsParam = defaultSymbols.join(',');
        final response = await apiClient.get(
          ApiConstants.pricesEndpoint,
          queryParameters: {'symbols': symbolsParam},
        );
        final prices = _parsePricesResponse(response);
        allPrices.addAll(prices);
      }

      // カスタム通貨: CoinGecko APIから取得（要件 16.7）
      if (customSymbols.isNotEmpty && coinGeckoClient != null) {
        for (final symbol in customSymbols) {
          try {
            final price = await coinGeckoClient!.fetchPriceBySymbol(symbol);
            allPrices.add(price);
          } catch (e) {
            // カスタム通貨の取得に失敗した場合はスキップ
            continue;
          }
        }
      }

      // リクエストされた順序でソート
      final sortedPrices = <CryptoPriceModel>[];
      for (final symbol in symbols) {
        try {
          final price = allPrices.firstWhere(
            (p) => p.symbol.toUpperCase() == symbol.toUpperCase(),
          );
          sortedPrices.add(price);
        } catch (e) {
          // シンボルが見つからない場合はスキップ
          continue;
        }
      }

      // 見つからなかったシンボルがある場合は、残りを追加
      for (final price in allPrices) {
        if (!sortedPrices.any((p) => p.symbol == price.symbol)) {
          sortedPrices.add(price);
        }
      }

      return sortedPrices;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: '価格データの取得に失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<List<CryptoPriceModel>> getAllPrices() async {
    try {
      // デフォルトのシンボルを使用
      final symbolsParam = ApiConstants.defaultSymbols.join(',');
      final response = await apiClient.get(
        ApiConstants.pricesEndpoint,
        queryParameters: {'symbols': symbolsParam},
      );
      
      final prices = _parsePricesResponse(response);
      
      // デフォルトの順序でソート
      final sortedPrices = <CryptoPriceModel>[];
      for (final symbol in ApiConstants.defaultSymbols) {
        try {
          final price = prices.firstWhere((p) => p.symbol == symbol);
          sortedPrices.add(price);
        } catch (e) {
          // シンボルが見つからない場合はスキップ
          continue;
        }
      }
      
      // 見つからなかったシンボルがある場合は、残りを追加
      for (final price in prices) {
        if (!sortedPrices.any((p) => p.symbol == price.symbol)) {
          sortedPrices.add(price);
        }
      }
      
      return sortedPrices;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: '価格データの取得に失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<CryptoPriceModel> getPriceBySymbol(String symbol) async {
    try {
      // デフォルト通貨かカスタム通貨かを判定（要件 16.7, 17.10）
      final isDefaultCurrency = ApiConstants.supportedSymbols
          .contains(symbol.toUpperCase());

      if (isDefaultCurrency) {
        // デフォルト通貨: バックエンドAPIから取得
        final response = await apiClient.get(
          ApiConstants.pricesEndpoint,
          queryParameters: {'symbols': symbol},
        );

        final prices = _parsePricesResponse(response);
        if (prices.isEmpty) {
          throw ServerException(
            message: 'シンボル $symbol の価格データが見つかりません',
          );
        }

        return prices.first;
      } else {
        // カスタム通貨: CoinGecko APIから取得（要件 16.7）
        if (coinGeckoClient == null) {
          throw ServerException(
            message: 'CoinGecko APIクライアントが初期化されていません',
          );
        }
        return await coinGeckoClient!.fetchPriceBySymbol(symbol);
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(
        message: 'シンボル $symbol の価格データの取得に失敗しました',
        originalError: e,
      );
    }
  }

  /// レスポンスから価格データのリストをパース
  List<CryptoPriceModel> _parsePricesResponse(Map<String, dynamic> response) {
    try {
      // レスポンスが直接配列の場合
      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> dataList = response['data'] as List;
        return dataList
            .map((item) => CryptoPriceModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // レスポンスが prices キーを持つ場合
      if (response.containsKey('prices') && response['prices'] is List) {
        final List<dynamic> pricesList = response['prices'] as List;
        return pricesList
            .map((item) => CryptoPriceModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // レスポンスが単一のオブジェクトの場合
      if (response.containsKey('symbol')) {
        return [CryptoPriceModel.fromJson(response)];
      }

      throw ParseException(
        message: 'レスポンスの形式が不正です',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException(
        message: '価格データのパースに失敗しました',
        originalError: e,
      );
    }
  }
}
