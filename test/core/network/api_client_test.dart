import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:crypto_watch/core/constants/api_constants.dart';
import 'package:crypto_watch/core/error/exceptions.dart';
import 'package:crypto_watch/core/network/api_client.dart';

import 'api_client_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late ApiClient apiClient;
  late MockClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockClient();
    apiClient = ApiClient(
      client: mockHttpClient,
      baseUrl: 'https://test-api.com',
      apiKey: 'test-key',
    );
  });

  group('GET requests', () {
    test('should perform GET request with correct headers', () async {
      // arrange
      final uri = Uri.parse('https://test-api.com/prices?symbols=BTC');
      when(mockHttpClient.get(uri, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                jsonEncode({'data': []}),
                200,
              ));

      // act
      await apiClient.get('/prices', queryParameters: {'symbols': 'BTC'});

      // assert
      verify(mockHttpClient.get(
        uri,
        headers: {
          ApiConstants.apiKeyHeader: 'test-key',
          ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
          ApiConstants.acceptEncodingHeader: ApiConstants.acceptEncodingGzip,
        },
      ));
    });

    test('should return parsed response on success', () async {
      // arrange
      final responseData = {
        'data': [
          {'symbol': 'BTC', 'price': 45000.0}
        ]
      };
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                jsonEncode(responseData),
                200,
              ));

      // act
      final result = await apiClient.get('/prices');

      // assert
      expect(result, responseData);
    });

    test('should throw AuthenticationException on 401', () async {
      // arrange
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                jsonEncode({'error': 'Unauthorized', 'code': 'UNAUTHORIZED'}),
                401,
              ));

      // act & assert
      expect(
        () => apiClient.get('/prices'),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('should throw RateLimitException on 429', () async {
      // arrange
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                jsonEncode({
                  'error': 'Rate limit exceeded',
                  'code': 'RATE_LIMIT_EXCEEDED'
                }),
                429,
              ));

      // act & assert
      expect(
        () => apiClient.get('/prices'),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('should throw ServerException on 500', () async {
      // arrange
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                jsonEncode({
                  'error': 'Internal server error',
                  'code': 'INTERNAL_ERROR'
                }),
                500,
              ));

      // act & assert
      expect(
        () => apiClient.get('/prices'),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw ValidationException on 400', () async {
      // arrange
      when(mockHttpClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                jsonEncode({
                  'error': 'Invalid parameters',
                  'code': 'VALIDATION_ERROR'
                }),
                400,
              ));

      // act & assert
      expect(
        () => apiClient.get('/prices'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('POST requests', () {
    test('should perform POST request with body', () async {
      // arrange
      final uri = Uri.parse('https://test-api.com/endpoint');
      final body = {'key': 'value'};
      when(mockHttpClient.post(
        uri,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'success': true}),
            200,
          ));

      // act
      await apiClient.post('/endpoint', body: body);

      // assert
      verify(mockHttpClient.post(
        uri,
        headers: anyNamed('headers'),
        body: jsonEncode(body),
      ));
    });
  });

  tearDown(() {
    apiClient.dispose();
  });
}
