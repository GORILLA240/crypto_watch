import 'package:flutter/material.dart';
import '../../domain/entities/favorite.dart';

/// 並び替え可能なお気に入りリストウィジェット
class ReorderableFavoriteList extends StatelessWidget {
  final List<Favorite> favorites;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(String symbol) onRemove;
  final Function(String symbol) onTap;

  const ReorderableFavoriteList({
    super.key,
    required this.favorites,
    required this.onReorder,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return const Center(
        child: Text(
          '銘柄を追加してください',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 18,
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      itemCount: favorites.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return Dismissible(
          key: Key(favorite.symbol),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 32,
            ),
          ),
          onDismissed: (_) => onRemove(favorite.symbol),
          child: ListTile(
            key: Key(favorite.symbol),
            leading: const Icon(
              Icons.drag_handle,
              color: Colors.grey,
            ),
            title: Text(
              favorite.symbol,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
              ),
              onPressed: () => onTap(favorite.symbol),
            ),
            onTap: () => onTap(favorite.symbol),
          ),
        );
      },
    );
  }
}
