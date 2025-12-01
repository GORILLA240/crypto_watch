import 'package:equatable/equatable.dart';
import '../../domain/entities/favorite.dart';

/// お気に入りの状態
abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

/// 初期状態
class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

/// 読み込み中
class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

/// 読み込み完了
class FavoritesLoaded extends FavoritesState {
  final List<Favorite> favorites;

  const FavoritesLoaded({required this.favorites});

  @override
  List<Object?> get props => [favorites];
}

/// エラー
class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError({required this.message});

  @override
  List<Object?> get props => [message];
}
