import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:crypto_watch/core/error/failures.dart';
import 'package:crypto_watch/features/alerts/domain/entities/price_alert.dart';
import 'package:crypto_watch/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:crypto_watch/features/alerts/domain/usecases/create_alert.dart';

import 'create_alert_test.mocks.dart';

@GenerateMocks([AlertsRepository])
void main() {
  late CreateAlert usecase;
  late MockAlertsRepository mockRepository;

  setUp(() {
    mockRepository = MockAlertsRepository();
    usecase = CreateAlert(mockRepository);
  });

  final tAlert = PriceAlert(
    id: '1',
    symbol: 'BTC',
    upperLimit: 50000.0,
    lowerLimit: 40000.0,
    isEnabled: true,
    createdAt: DateTime(2024, 1, 15),
  );

  test('should create alert through repository', () async {
    // arrange
    when(mockRepository.createAlert(any))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(tAlert);

    // assert
    expect(result, const Right(null));
    verify(mockRepository.createAlert(tAlert));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    const tFailure = StorageFailure(message: 'Storage error');
    when(mockRepository.createAlert(any))
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(tAlert);

    // assert
    expect(result, const Left(tFailure));
    verify(mockRepository.createAlert(tAlert));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should validate alert triggers correctly', () {
    // Test upper limit trigger
    final alertUpper = PriceAlert(
      id: '1',
      symbol: 'BTC',
      upperLimit: 50000.0,
      isEnabled: true,
      createdAt: DateTime(2024, 1, 15),
    );
    expect(alertUpper.shouldTrigger(50000.0), true);
    expect(alertUpper.shouldTrigger(50001.0), true);
    expect(alertUpper.shouldTrigger(49999.0), false);

    // Test lower limit trigger
    final alertLower = PriceAlert(
      id: '2',
      symbol: 'BTC',
      lowerLimit: 40000.0,
      isEnabled: true,
      createdAt: DateTime(2024, 1, 15),
    );
    expect(alertLower.shouldTrigger(40000.0), true);
    expect(alertLower.shouldTrigger(39999.0), true);
    expect(alertLower.shouldTrigger(40001.0), false);

    // Test disabled alert
    final alertDisabled = PriceAlert(
      id: '3',
      symbol: 'BTC',
      upperLimit: 50000.0,
      isEnabled: false,
      createdAt: DateTime(2024, 1, 15),
    );
    expect(alertDisabled.shouldTrigger(50001.0), false);
  });
}
