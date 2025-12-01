import 'package:equatable/equatable.dart';
import '../../domain/entities/favorite.dart';

/// お気に入りのイベント
abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

/// お気に入りを読み込む
class LoadFavoritesEvent extends FavoritesEvent {
  const LoadFavoritesEvent();
}

/// お気に入りを追加
class AddFavoriteEvent extends FavoritesEvent {
  final String symbol;

  const AddFavoriteEvent({required this.symbol});

  @override
  List<Object?> get props => [symbol];
}

/// お気に入りを削除
class RemoveFavoriteEvent extends FavoritesEvent {
  final String symbol;

  const RemoveFavoriteEvent({required this.symbol});

  @override
  List<Object?> get props => [symbol];
}

/// お気に入りを並び替え
class ReorderFavoritesEvent extends FavoritesEvent {
  final List<Favorite> favorites;

  const ReorderFavoritesEvent({required this.favorites});

  @override
  List<Object?> get props => [favorites];
}
