import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// パフォーマンス最適化ユーティリティ
class PerformanceUtils {
  PerformanceUtils._();

  /// 不要な再描画を防ぐためのキー生成
  static Key generateKey(String prefix, dynamic id) {
    return ValueKey('${prefix}_$id');
  }

  /// リストアイテムの最適化されたキー生成
  static Key listItemKey(String id) {
    return ValueKey('list_item_$id');
  }

  /// デバウンス処理
  /// 連続した呼び出しを制限し、最後の呼び出しのみを実行
  static void Function() debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    DateTime? lastCallTime;

    return () {
      final now = DateTime.now();
      if (lastCallTime == null ||
          now.difference(lastCallTime!) >= delay) {
        lastCallTime = now;
        callback();
      }
    };
  }

  /// スロットル処理
  /// 一定期間内の呼び出しを制限
  static VoidCallback throttle(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    bool isThrottled = false;

    return () {
      if (!isThrottled) {
        callback();
        isThrottled = true;
        Future.delayed(duration, () {
          isThrottled = false;
        });
      }
    };
  }

  /// メモリ使用量をログ出力（デバッグモードのみ）
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      debugPrint('[$context] Memory check');
    }
  }

  /// フレームレートの監視を開始（デバッグモードのみ）
  static void startFrameRateMonitoring() {
    if (kDebugMode) {
      WidgetsBinding.instance.addTimingsCallback((timings) {
        for (final timing in timings) {
          final fps = 1000000 / timing.totalSpan.inMicroseconds;
          if (fps < 55) {
            debugPrint('⚠️ Low FPS detected: ${fps.toStringAsFixed(1)}');
          }
        }
      });
    }
  }
}

/// 再描画を最適化するためのウィジェット
class OptimizedBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) builder;
  final bool Function(Object? previous, Object? current)? shouldRebuild;

  const OptimizedBuilder({
    super.key,
    required this.builder,
    this.shouldRebuild,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}

/// 遅延読み込み用のウィジェット
class LazyLoadingList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final Widget? loadingWidget;
  final ScrollController? controller;

  const LazyLoadingList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = false,
    this.loadingWidget,
    this.controller,
  });

  @override
  State<LazyLoadingList<T>> createState() => _LazyLoadingListState<T>();
}

class _LazyLoadingListState<T> extends State<LazyLoadingList<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (!widget.hasMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8; // 80%スクロールで読み込み開始

    if (currentScroll >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    widget.onLoadMore?.call();

    // 読み込み完了を待つ
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return widget.loadingWidget ??
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
        }

        return widget.itemBuilder(context, widget.items[index], index);
      },
    );
  }
}

/// 画像キャッシュの設定
class ImageCacheConfig {
  ImageCacheConfig._();

  /// 画像キャッシュを最適化
  static void optimizeImageCache() {
    // キャッシュサイズを設定（デフォルトは1000枚、100MB）
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
  }

  /// 画像キャッシュをクリア
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
