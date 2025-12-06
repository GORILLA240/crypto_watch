import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/currency_search_result.dart';
import '../../../../core/services/coingecko_api_client.dart';
import '../../../../core/services/currency_search_service.dart';
import '../../../../core/services/favorites_manager.dart';
import '../../../../core/widgets/crypto_icon.dart';
import '../../../../core/widgets/optimized_text_widget.dart';
import '../../../../core/error/exceptions.dart';

/// 通貨検索画面
/// ユーザーが任意の暗号通貨を検索して追加できる
class CurrencySearchPage extends StatefulWidget {
  const CurrencySearchPage({super.key});

  @override
  State<CurrencySearchPage> createState() => _CurrencySearchPageState();
}

class _CurrencySearchPageState extends State<CurrencySearchPage> {
  late final CurrencySearchService _searchService;
  late final FavoritesManager _favoritesManager;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<CurrencySearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;
  String? _errorType; // 'network', 'empty', 'rate_limit', 'server'
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// サービスを初期化
  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _searchService = CurrencySearchService(
      apiClient: CoinGeckoApiClient(),
    );
    _favoritesManager = FavoritesManager(prefs);

    setState(() {
      _isInitialized = true;
    });

    // 検索フィールドの変更を監視
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchService.dispose();
    super.dispose();
  }

  /// 検索フィールドの変更時に呼ばれる
  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // 2文字未満の場合は検索しない（要件 18.1）
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
        _isSearching = false;
      });
      return;
    }

    // 検索を実行
    _performSearch(query);
  }

  /// 検索を実行
  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _errorType = null;
    });

    try {
      // デバウンス処理を含む検索（要件 18.3）
      await Future.delayed(const Duration(milliseconds: 300));

      // 検索クエリが変更されていないか確認
      if (_searchController.text.trim() != query) {
        return;
      }

      // 検索を実行（要件 16.4, 16.5）
      final results = await _searchService.searchCurrencies(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
        // 検索結果が0件の場合（要件 16.9）
        if (results.isEmpty) {
          _errorMessage = '該当する通貨が見つかりません';
          _errorType = 'empty';
        }
      });
    } on NetworkException {
      // ネットワークエラー（要件 16.10）
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = 'ネットワーク接続を確認してください';
        _errorType = 'network';
      });
    } on RateLimitException {
      // レート制限エラー（要件 16.10）
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = 'リクエスト制限に達しました。しばらくお待ちください';
        _errorType = 'rate_limit';
      });
    } on ServerException {
      // サーバーエラー（要件 16.10）
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = 'サーバーエラーが発生しました。しばらくしてから再度お試しください';
        _errorType = 'server';
      });
    } catch (e) {
      // その他のエラー（要件 16.10）
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = '検索中にエラーが発生しました。もう一度お試しください';
        _errorType = 'network';
      });
    }
  }

  /// 通貨を選択してお気に入りに追加
  Future<void> _onCurrencySelected(CurrencySearchResult currency) async {
    try {
      // お気に入りに追加（要件 16.6）
      await _favoritesManager.addFavorite(currency.symbol);

      if (!mounted) return;

      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${currency.symbol} をお気に入りに追加しました'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      // 画面を閉じる
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      // エラーメッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('お気に入りへの追加に失敗しました'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '通貨を検索',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          iconSize: 20,
          padding: const EdgeInsets.all(8),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        // サジェスト外をタップしたら検索フィールドのフォーカスを外す（要件 18.8）
        onTap: () {
          _searchFocusNode.unfocus();
        },
        child: Column(
          children: [
            // 検索フィールド（要件 16.1）
            _buildSearchField(),
            const SizedBox(height: 8),
            // 検索結果リスト
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  /// 検索フィールドを構築
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'ティッカーシンボルまたは通貨名',
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    // 検索フィールドをクリア（要件 18.5）
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _errorMessage = null;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        autofocus: true,
      ),
    );
  }

  /// 検索結果リストを構築
  Widget _buildSearchResults() {
    // ローディング中
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // エラーメッセージ表示（要件 16.9, 16.10）
    if (_errorMessage != null) {
      return _buildErrorMessage();
    }

    // 検索結果が空の場合
    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    // 検索結果リスト（要件 16.5）
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final currency = _searchResults[index];
        return _buildSearchResultItem(currency);
      },
    );
  }

  /// 検索結果アイテムを構築
  Widget _buildSearchResultItem(CurrencySearchResult currency) {
    final query = _searchController.text.trim().toLowerCase();

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: () => _onCurrencySelected(currency),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 通貨アイコン（要件 16.3）
              CryptoIcon(
                symbol: currency.symbol,
                size: 32,
              ),
              const SizedBox(width: 12),
              // 通貨情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 通貨名（要件 16.3, 18.4 - ハイライト表示）
                    _buildHighlightedText(
                      text: currency.name,
                      query: query,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      highlightColor: Colors.yellow,
                    ),
                    const SizedBox(height: 4),
                    // ティッカーシンボル（要件 16.3, 18.4 - ハイライト表示）
                    _buildHighlightedText(
                      text: currency.symbol,
                      query: query,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      highlightColor: Colors.yellow,
                    ),
                  ],
                ),
              ),
              // 時価総額ランキング（要件 18.6）
              if (currency.marketCapRank < 999999)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: OptimizedTextWidget(
                    '#${currency.marketCapRank}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                  ),
                ),
              const SizedBox(width: 8),
              // 追加アイコン
              const Icon(
                Icons.add_circle_outline,
                color: Colors.green,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 入力文字列をハイライト表示するテキストウィジェットを構築
  /// 要件 18.4: 入力文字列に一致する部分をハイライト
  Widget _buildHighlightedText({
    required String text,
    required String query,
    required TextStyle style,
    required Color highlightColor,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(query, start);
      if (index == -1) {
        // 残りのテキストを追加
        spans.add(TextSpan(
          text: text.substring(start),
          style: style,
        ));
        break;
      }

      // マッチ前のテキストを追加
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }

      // マッチしたテキストをハイライト表示
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: style.copyWith(
          backgroundColor: highlightColor,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// エラーメッセージを構築
  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _errorType == 'network' ? Icons.wifi_off : Icons.error_outline,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 16),
            OptimizedTextWidget(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              maxLines: 3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // 検索のヒント（要件 16.9）
            if (_errorType == 'empty')
              OptimizedTextWidget(
                'ティッカーシンボルまたは通貨名で検索してください',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            // リトライボタン（要件 16.10）
            if (_errorType == 'network' || _errorType == 'server')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    final query = _searchController.text.trim();
                    if (query.length >= 2) {
                      _performSearch(query);
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            // 人気通貨の候補（要件 16.9）
            if (_errorType == 'empty') ...[
              const SizedBox(height: 24),
              OptimizedTextWidget(
                '人気の通貨',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 12),
              _buildPopularCurrencies(),
            ],
          ],
        ),
      ),
    );
  }

  /// 人気通貨の候補を構築（要件 16.9）
  Widget _buildPopularCurrencies() {
    final popularCurrencies = [
      'Bitcoin',
      'Ethereum',
      'Cardano',
      'Solana',
      'Polkadot',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: popularCurrencies.map((currency) {
        return ActionChip(
          label: Text(
            currency,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          backgroundColor: Colors.grey[800],
          onPressed: () {
            _searchController.text = currency;
            _performSearch(currency);
          },
        );
      }).toList(),
    );
  }

  /// 空の状態を構築
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              color: Colors.grey[600],
              size: 64,
            ),
            const SizedBox(height: 16),
            OptimizedTextWidget(
              '通貨を検索',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 8),
            OptimizedTextWidget(
              'ティッカーシンボルまたは通貨名を\n2文字以上入力してください',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
