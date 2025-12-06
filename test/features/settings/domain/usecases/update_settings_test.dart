import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:crypto_watch/core/error/failures.dart';
import 'package:crypto_watch/features/settings/domain/entities/app_settings.dart';
import 'package:crypto_watch/features/settings/domain/repositories/settings_repository.dart';
import 'package:crypto_watch/features/settings/domain/usecases/update_settings.dart';

import 'update_settings_test.mocks.dart';

@GenerateMocks([SettingsRepository])
void main() {
  late UpdateSettings usecase;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    usecase = UpdateSettings(mockRepository);
  });

  const tSettings = AppSettings(
    isDarkMode: true,
    notificationsEnabled: true,
    autoRefreshEnabled: true,
    refreshIntervalMinutes: 5,
    defaultCurrency: 'USD',
  );

  test('should update settings through repository', () async {
    // arrange
    when(mockRepository.updateSettings(any))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(tSettings);

    // assert
    expect(result, const Right(null));
    verify(mockRepository.updateSettings(tSettings));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    const tFailure = StorageFailure(message: 'Storage error');
    when(mockRepository.updateSettings(any))
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(tSettings);

    // assert
    expect(result, const Left(tFailure));
    verify(mockRepository.updateSettings(tSettings));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should validate settings values', () {
    // Test valid settings
    const validSettings = AppSettings(
      isDarkMode: true,
      notificationsEnabled: true,
      autoRefreshEnabled: true,
      refreshIntervalMinutes: 5,
      defaultCurrency: 'USD',
    );
    expect(validSettings.refreshIntervalMinutes, greaterThan(0));

    // Test copyWith
    final updatedSettings = validSettings.copyWith(
      refreshIntervalMinutes: 10,
    );
    expect(updatedSettings.refreshIntervalMinutes, 10);
    expect(updatedSettings.isDarkMode, validSettings.isDarkMode);
  });
}
