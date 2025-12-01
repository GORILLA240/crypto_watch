import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/crypto_price.dart';
import '../../domain/repositories/price_repository.dart';
import '../datasources/price_local_datasource.dart';
import '../datasources/price_remote_datasource.dart';

/// 価格データリポジトリの実装
class PriceRepositoryImpl implements PriceRepository {
  final PriceRemoteDataSource remoteDataSource;
  final PriceLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  PriceRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CryptoPrice>>> getPrices(
      List<String> symbols) async {
    // ネットワーク接続をチェック
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      // オンライン: リモートから取得してキャッシュ
      try {
        final prices = await remoteDataSource.getPrices(symbols);
        await localDataSource.cachePrices(prices);
        return Right(prices);
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } on TimeoutException catch (e) {
        return Left(TimeoutFailure(message: e.message));
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } on RateLimitException catch (e) {
        return Left(RateLimitFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on ParseException catch (e) {
        return Left(ParseFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    } else {
      // オフライン: キャッシュから取得
      try {
        final cachedPrices = await localDataSource.getCachedPrices();
        if (cachedPrices.isEmpty) {
          return const Left(
            NetworkFailure(message: 'ネットワーク接続がなく、キャッシュも存在しません'),
          );
        }
        return Right(cachedPrices);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, CryptoPrice>> getPriceBySymbol(String symbol) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final price = await remoteDataSource.getPriceBySymbol(symbol);
        return Right(price);
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } on TimeoutException catch (e) {
        return Left(TimeoutFailure(message: e.message));
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } on RateLimitException catch (e) {
        return Left(RateLimitFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on ParseException catch (e) {
        return Left(ParseFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    } else {
      try {
        final cachedPrices = await localDataSource.getCachedPrices();
        final price = cachedPrices.firstWhere(
          (p) => p.symbol == symbol,
          orElse: () => throw CacheException(
            message: 'シンボル $symbol のキャッシュが見つかりません',
          ),
        );
        return Right(price);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, List<CryptoPrice>>> refreshPrices() async {
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      return const Left(
        NetworkFailure(message: 'ネットワーク接続がありません'),
      );
    }

    try {
      final prices = await remoteDataSource.getAllPrices();
      await localDataSource.cachePrices(prices);
      return Right(prices);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on TimeoutException catch (e) {
      return Left(TimeoutFailure(message: e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
