import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/add_favorite.dart';
import '../../domain/usecases/get_favorites.dart';
import '../../domain/usecases/remove_favorite.dart';
import '../../domain/usecases/reorder_favorites.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

/// お気に入りのBloc
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final GetFavorites getFavorites;
  final AddFavorite addFavorite;
  final RemoveFavorite removeFavorite;
  final ReorderFavorites reorderFavorites;

  FavoritesBloc({
    required this.getFavorites,
    required this.addFavorite,
    required this.removeFavorite,
    required this.reorderFavorites,
  }) : super(const FavoritesInitial()) {
    on<LoadFavoritesEvent>(_onLoadFavorites);
    on<AddFavoriteEvent>(_onAddFavorite);
    on<RemoveFavoriteEvent>(_onRemoveFavorite);
    on<ReorderFavoritesEvent>(_onReorderFavorites);
  }

  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesLoading());

    final result = await getFavorites();

    result.fold(
      (failure) => emit(FavoritesError(message: failure.message)),
      (favorites) => emit(FavoritesLoaded(favorites: favorites)),
    );
  }

  Future<void> _onAddFavorite(
    AddFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    final result = await addFavorite(event.symbol);

    await result.fold(
      (failure) async => emit(FavoritesError(message: failure.message)),
      (_) async {
        // お気に入りを再読み込み
        final favoritesResult = await getFavorites();
        favoritesResult.fold(
          (failure) => emit(FavoritesError(message: failure.message)),
          (favorites) => emit(FavoritesLoaded(favorites: favorites)),
        );
      },
    );
  }

  Future<void> _onRemoveFavorite(
    RemoveFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    final result = await removeFavorite(event.symbol);

    await result.fold(
      (failure) async => emit(FavoritesError(message: failure.message)),
      (_) async {
        // お気に入りを再読み込み
        final favoritesResult = await getFavorites();
        favoritesResult.fold(
          (failure) => emit(FavoritesError(message: failure.message)),
          (favorites) => emit(FavoritesLoaded(favorites: favorites)),
        );
      },
    );
  }

  Future<void> _onReorderFavorites(
    ReorderFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    final result = await reorderFavorites(event.favorites);

    await result.fold(
      (failure) async => emit(FavoritesError(message: failure.message)),
      (_) async {
        // お気に入りを再読み込み
        final favoritesResult = await getFavorites();
        favoritesResult.fold(
          (failure) => emit(FavoritesError(message: failure.message)),
          (favorites) => emit(FavoritesLoaded(favorites: favorites)),
        );
      },
    );
  }
}
