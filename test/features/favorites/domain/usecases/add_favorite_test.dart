import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:crypto_watch/core/error/failures.dart';
import 'package:crypto_watch/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:crypto_watch/features/favorites/domain/usecases/add_favorite.dart';

import 'add_favorite_test.mocks.dart';

@GenerateMocks([FavoritesRepository])
void main() {
  late AddFavorite usecase;
  late MockFavoritesRepository mockRepository;

  setUp(() {
    mockRepository = MockFavoritesRepository();
    usecase = AddFavorite(mockRepository);
  });

  const tSymbol = 'BTC';

  test('should add favorite through repository', () async {
    // arrange
    when(mockRepository.addFavorite(any))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(tSymbol);

    // assert
    expect(result, const Right(null));
    verify(mockRepository.addFavorite(tSymbol));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    const tFailure = StorageFailure(message: 'Storage error');
    when(mockRepository.addFavorite(any))
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(tSymbol);

    // assert
    expect(result, const Left(tFailure));
    verify(mockRepository.addFavorite(tSymbol));
    verifyNoMoreInteractions(mockRepository);
  });
}
