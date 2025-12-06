import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:crypto_watch/core/error/failures.dart';
import 'package:crypto_watch/features/price_list/domain/entities/crypto_price.dart';
import 'package:crypto_watch/features/price_list/domain/repositories/price_repository.dart';
import 'package:crypto_watch/features/price_list/domain/usecases/get_prices.dart';

import 'get_prices_test.mocks.dart';

@GenerateMocks([PriceRepository])
void main() {
  late GetPrices usecase;
  late MockPriceRepository mockRepository;

  setUp(() {
    mockRepository = MockPriceRepository();
    usecase = GetPrices(mockRepository);
  });

  final tSymbols = ['BTC', 'ETH'];
  final tPrices = [
    const CryptoPrice(
      symbol: 'BTC',
      name: 'Bitcoin',
      price: 45000.0,
      change24h: 2.5,
      marketCap: 850000000000,
      lastUpdated: '2024-01-15T10:30:00Z',
    ),
    const CryptoPrice(
      symbol: 'ETH',
      name: 'Ethereum',
      price: 3000.0,
      change24h: -1.2,
      marketCap: 360000000000,
      lastUpdated: '2024-01-15T10:30:00Z',
    ),
  ];

  test('should get prices from repository', () async {
    // arrange
    when(mockRepository.getPrices(any))
        .thenAnswer((_) async => Right(tPrices));

    // act
    final result = await usecase(tSymbols);

    // assert
    expect(result, Right(tPrices));
    verify(mockRepository.getPrices(tSymbols));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    const tFailure = NetworkFailure(message: 'Network error');
    when(mockRepository.getPrices(any))
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(tSymbols);

    // assert
    expect(result, const Left(tFailure));
    verify(mockRepository.getPrices(tSymbols));
    verifyNoMoreInteractions(mockRepository);
  });
}
