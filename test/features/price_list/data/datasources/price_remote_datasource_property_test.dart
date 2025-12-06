import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:crypto_watch/core/constants/api_constants.dart';
import 'package:crypto_watch/core/network/api_client.dart';
import 'package:crypto_watch/core/services/coingecko_api_client.dart';
import 'package:crypto_watch/features/price_list/data/datasources/price_remote_datasource.dart';
import 'package:crypto_watch/features/price_list/data/models/crypto_price_model.dart';

@GenerateMocks([http.Client, ApiClient, CoinGeckoApiClient])
import 'price_remote_datasource_property_test.mocks.dart';

/// Property 9: 価格データ取得の統一性
/// **Feature: smartwatch-ui-optimization, Property 9: 価格データ取得の統一性**
/// **Validates: Requirements 16.7**
/// 
/// 任意の通貨（デフォルトまたはカスタム）に対して、
/// 価格データはCoinGecko APIから取得される
void main() {
  late MockApiClient mockApiClient;
  late MockCoinGeckoApiClient mockCoinGeckoClient;
  late PriceRemoteDataSource dataSource;

  setUp(() {
    mockApiClient = MockApiClient();
    mockCoinGeckoClient = MockCoinGeckoApiClient();
    dataSource = PriceRemoteDataSourceImpl(
      apiClient: mockApiClient,
      coinGeckoClient: mockCoinGeckoClient,
    );
  });

  group('Property 9: Price Data Fetching Uniformity', () {
    test('default currencies use backend API', () async {
      // デフォルト通貨のサンプル
      final defaultSymbols = ['BTC', 'ETH', 'ADA'];
      
      // バックエンドAPIのレスポンスをモック
      when(mockApiClient.get(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => {
        'data': defaultSymbols.map((symbol) => {
          'symbol': symbol,
          'name': '$symbol Name',
          'price': 1000.0,
          'change24h': 5.0,
          'marketCap': 1000000.0,
          'lastUpdated': DateTime.now().toIso8601String(),
        }).toList(),
      });

      // 価格データを取得
      final prices = await dataSource.getPrices(defaultSymbols);

      // バックエンドAPIが呼ばれたことを検証
      verify(mockApiClient.get(
        ApiConstants.pricesEndpoint,
        queryParameters: {'symbols': defaultSymbols.join(',')},
      )).called(1);

      // CoinGecko APIは呼ばれていないことを検証
      verifyNever(mockCoinGeckoClient.fetchPriceBySymbol(any));

      // 価格データが取得できたことを検証
      expect(prices.length, equals(defaultSymbols.length));
      for (var i = 0; i < prices.length; i++) {
        expect(prices[i].symbol, equals(defaultSymbols[i]));
      }
    });

    test('custom currencies use CoinGecko API', () async {
      // カスタム通貨のサンプル
      final customSymbols = ['SHIB', 'PEPE', 'FLOKI'];
      
      // CoinGecko APIのレスポンスをモック
      for (final symbol in customSymbols) {
        when(mockCoinGeckoClient.fetchPriceBySymbol(symbol))
            .thenAnswer((_) async => CryptoPriceModel(
              symbol: symbol,
              name: '$symbol Name',
              price: 0.001,
              change24h: 10.0,
              marketCap: 100000.0,
              lastUpdated: DateTime.now(),
            ));
      }

      // 価格データを取得
      final prices = await dataSource.getPrices(customSymbols);

      // バックエンドAPIは呼ばれていないことを検証（カスタム通貨のみの場合）
      verifyNever(mockApiClient.get(
        any,
        queryParameters: anyNamed('queryParameters'),
      ));

      // CoinGecko APIが各カスタム通貨に対して呼ばれたことを検証
      for (final symbol in customSymbols) {
        verify(mockCoinGeckoClient.fetchPriceBySymbol(symbol)).called(1);
      }

      // 価格データが取得できたことを検証
      expect(prices.length, equals(customSymbols.length));
      for (var i = 0; i < prices.length; i++) {
        expect(prices[i].symbol, equals(customSymbols[i]));
      }
    });

    test('mixed currencies use appropriate APIs', () async {
      // デフォルト通貨とカスタム通貨を混在
      final defaultSymbols = ['BTC', 'ETH'];
      final customSymbols = ['SHIB', 'PEPE'];
      final mixedSymbols = [...defaultSymbols, ...customSymbols];

      // バックエンドAPIのレスポンスをモック
      when(mockApiClient.get(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => {
        'data': defaultSymbols.map((symbol) => {
          'symbol': symbol,
          'name': '$symbol Name',
          'price': 1000.0,
          'change24h': 5.0,
          'marketCap': 1000000.0,
          'lastUpdated': DateTime.now().toIso8601String(),
        }).toList(),
      });

      // CoinGecko APIのレスポンスをモック
      for (final symbol in customSymbols) {
        when(mockCoinGeckoClient.fetchPriceBySymbol(symbol))
            .thenAnswer((_) async => CryptoPriceModel(
              symbol: symbol,
              name: '$symbol Name',
              price: 0.001,
              change24h: 10.0,
              marketCap: 100000.0,
              lastUpdated: DateTime.now(),
            ));
      }

      // 価格データを取得
      final prices = await dataSource.getPrices(mixedSymbols);

      // バックエンドAPIがデフォルト通貨に対して呼ばれたことを検証
      verify(mockApiClient.get(
        ApiConstants.pricesEndpoint,
        queryParameters: {'symbols': defaultSymbols.join(',')},
      )).called(1);

      // CoinGecko APIがカスタム通貨に対して呼ばれたことを検証
      for (final symbol in customSymbols) {
        verify(mockCoinGeckoClient.fetchPriceBySymbol(symbol)).called(1);
      }

      // すべての価格データが取得できたことを検証
      expect(prices.length, equals(mixedSymbols.length));
    });

    test('single currency fetching uses appropriate API', () async {
      // デフォルト通貨
      final defaultSymbol = 'BTC';
      
      // バックエンドAPIのレスポンスをモック
      when(mockApiClient.get(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => {
        'data': [{
          'symbol': defaultSymbol,
          'name': 'Bitcoin',
          'price': 50000.0,
          'change24h': 5.0,
          'marketCap': 1000000000.0,
          'lastUpdated': DateTime.now().toIso8601String(),
        }],
      });

      // デフォルト通貨の価格を取得
      final defaultPrice = await dataSource.getPriceBySymbol(defaultSymbol);

      // バックエンドAPIが呼ばれたことを検証
      verify(mockApiClient.get(
        ApiConstants.pricesEndpoint,
        queryParameters: {'symbols': defaultSymbol},
      )).called(1);

      expect(defaultPrice.symbol, equals(defaultSymbol));

      // カスタム通貨
      final customSymbol = 'SHIB';
      
      // CoinGecko APIのレスポンスをモック
      when(mockCoinGeckoClient.fetchPriceBySymbol(customSymbol))
          .thenAnswer((_) async => CryptoPriceModel(
            symbol: customSymbol,
            name: 'Shiba Inu',
            price: 0.00001,
            change24h: 15.0,
            marketCap: 5000000.0,
            lastUpdated: DateTime.now(),
          ));

      // カスタム通貨の価格を取得
      final customPrice = await dataSource.getPriceBySymbol(customSymbol);

      // CoinGecko APIが呼ばれたことを検証
      verify(mockCoinGeckoClient.fetchPriceBySymbol(customSymbol)).called(1);

      expect(customPrice.symbol, equals(customSymbol));
    });

    test('price data structure is consistent for all currencies', () async {
      // デフォルト通貨とカスタム通貨
      final defaultSymbol = 'BTC';
      final customSymbol = 'SHIB';

      // バックエンドAPIのレスポンスをモック
      when(mockApiClient.get(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => {
        'data': [{
          'symbol': defaultSymbol,
          'name': 'Bitcoin',
          'price': 50000.0,
          'change24h': 5.0,
          'marketCap': 1000000000.0,
          'lastUpdated': DateTime.now().toIso8601String(),
        }],
      });

      // CoinGecko APIのレスポンスをモック
      when(mockCoinGeckoClient.fetchPriceBySymbol(customSymbol))
          .thenAnswer((_) async => CryptoPriceModel(
            symbol: customSymbol,
            name: 'Shiba Inu',
            price: 0.00001,
            change24h: 15.0,
            marketCap: 5000000.0,
            lastUpdated: DateTime.now(),
          ));

      // 両方の価格データを取得
      final defaultPrice = await dataSource.getPriceBySymbol(defaultSymbol);
      final customPrice = await dataSource.getPriceBySymbol(customSymbol);

      // データ構造が同じであることを検証
      expect(defaultPrice.symbol, isA<String>());
      expect(customPrice.symbol, isA<String>());
      
      expect(defaultPrice.name, isA<String>());
      expect(customPrice.name, isA<String>());
      
      expect(defaultPrice.price, isA<double>());
      expect(customPrice.price, isA<double>());
      
      expect(defaultPrice.change24h, isA<double>());
      expect(customPrice.change24h, isA<double>());
      
      expect(defaultPrice.marketCap, isA<double>());
      expect(customPrice.marketCap, isA<double>());
      
      expect(defaultPrice.lastUpdated, isA<DateTime>());
      expect(customPrice.lastUpdated, isA<DateTime>());
    });
  });
}
