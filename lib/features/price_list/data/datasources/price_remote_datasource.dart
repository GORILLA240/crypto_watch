import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
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

  PriceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CryptoPriceModel>> getPrices(List<String> symbols) async {
    try {
      final symbolsParam = symbols.join(',');
      final response = await apiClient.get(
        ApiConstants.pricesEndpoint,
        queryParameters: {'symbols': symbolsParam},
      );

      return _parsePricesResponse(response);
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
      final response = await apiClient.get(ApiConstants.pricesEndpoint);
      return _parsePricesResponse(response);
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
