import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Core
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/services/coingecko_api_client.dart';
import 'core/storage/local_storage.dart';

// Features - Price List
import 'features/price_list/data/datasources/price_local_datasource.dart';
import 'features/price_list/data/datasources/price_remote_datasource.dart';
import 'features/price_list/data/datasources/price_mock_datasource.dart';
import 'features/price_list/data/repositories/price_repository_impl.dart';
import 'features/price_list/domain/repositories/price_repository.dart';
import 'features/price_list/domain/usecases/get_prices.dart';
import 'features/price_list/domain/usecases/refresh_prices.dart';
import 'features/price_list/presentation/bloc/price_list_bloc.dart';

// Features - Favorites
import 'features/favorites/data/datasources/favorites_local_datasource.dart';
import 'features/favorites/data/repositories/favorites_repository_impl.dart';
import 'features/favorites/domain/repositories/favorites_repository.dart';
import 'features/favorites/domain/usecases/add_favorite.dart';
import 'features/favorites/domain/usecases/get_favorites.dart';
import 'features/favorites/domain/usecases/remove_favorite.dart';
import 'features/favorites/domain/usecases/reorder_favorites.dart';
import 'features/favorites/presentation/bloc/favorites_bloc.dart';

// Features - Alerts
import 'features/alerts/data/datasources/alerts_local_datasource.dart';
import 'features/alerts/data/repositories/alerts_repository_impl.dart';
import 'features/alerts/domain/repositories/alerts_repository.dart';
import 'features/alerts/domain/usecases/check_alerts.dart';
import 'features/alerts/domain/usecases/create_alert.dart';
import 'features/alerts/domain/usecases/delete_alert.dart';
import 'features/alerts/presentation/bloc/alerts_bloc.dart';

// Features - Settings
import 'features/settings/data/datasources/settings_local_datasource.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/domain/usecases/get_settings.dart';
import 'features/settings/domain/usecases/update_settings.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

final sl = GetIt.instance;

/// 依存性注入の初期化
Future<void> init() async {
  //! Features - Price List
  // Bloc - Factoryパターンで毎回新しいインスタンスを作成
  sl.registerFactory(
    () => PriceListBloc(
      getPrices: sl(),
      refreshPrices: sl(),
      getFavorites: sl(),
      addFavorite: sl(),
      removeFavorite: sl(),
      localStorage: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPrices(sl()));
  sl.registerLazySingleton(() => RefreshPrices(sl()));

  // Repository
  sl.registerLazySingleton<PriceRepository>(
    () => PriceRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  // モックモードの判定（環境変数 USE_MOCK_DATA=true または APIキーが空の場合）
  const useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);
  
  sl.registerLazySingleton<PriceRemoteDataSource>(
    () => useMockData 
        ? PriceMockDataSource()
        : PriceRemoteDataSourceImpl(
            apiClient: sl(),
            coinGeckoClient: sl(),
          ),
  );
  sl.registerLazySingleton<PriceLocalDataSource>(
    () => PriceLocalDataSourceImpl(localStorage: sl()),
  );

  //! Features - Favorites
  // Bloc
  sl.registerFactory(
    () => FavoritesBloc(
      getFavorites: sl(),
      addFavorite: sl(),
      removeFavorite: sl(),
      reorderFavorites: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetFavorites(sl()));
  sl.registerLazySingleton(() => AddFavorite(sl()));
  sl.registerLazySingleton(() => RemoveFavorite(sl()));
  sl.registerLazySingleton(() => ReorderFavorites(sl()));

  // Repository
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<FavoritesLocalDataSource>(
    () => FavoritesLocalDataSourceImpl(localStorage: sl()),
  );

  //! Features - Alerts
  // Bloc
  sl.registerFactory(
    () => AlertsBloc(
      checkAlerts: sl(),
      createAlert: sl(),
      deleteAlert: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => CheckAlerts(sl()));
  sl.registerLazySingleton(() => CreateAlert(sl()));
  sl.registerLazySingleton(() => DeleteAlert(sl()));

  // Repository
  sl.registerLazySingleton<AlertsRepository>(
    () => AlertsRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AlertsLocalDataSource>(
    () => AlertsLocalDataSourceImpl(localStorage: sl()),
  );

  //! Features - Settings
  // Bloc - Singletonパターン（設定は全体で1つのインスタンスを共有）
  sl.registerLazySingleton(
    () => SettingsBloc(
      getSettings: sl(),
      updateSettings: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => UpdateSettings(sl()));

  // Repository
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(localStorage: sl()),
  );

  //! Core
  // Network
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );
  sl.registerLazySingleton(() => ApiClient(client: sl()));
  sl.registerLazySingleton(() => CoinGeckoApiClient(client: sl()));

  // Storage
  sl.registerLazySingleton<LocalStorage>(
    () => LocalStorageImpl(sharedPreferences: sl()),
  );

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => Connectivity());
}
