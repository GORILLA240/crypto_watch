import 'package:flutter/material.dart';
import '../../domain/entities/crypto_price.dart';
import '../widgets/large_price_display.dart';

/// シングルビュー画面
class SingleViewPage extends StatefulWidget {
  final List<CryptoPrice> prices;
  final int initialIndex;

  const SingleViewPage({
    super.key,
    required this.prices,
    this.initialIndex = 0,
  });

  @override
  State<SingleViewPage> createState() => _SingleViewPageState();
}

class _SingleViewPageState extends State<SingleViewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prices.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Text(
            'データがありません',
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: Show options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Page indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.prices.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.grey[700],
                  ),
                ),
              ),
            ),
          ),
          // PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.prices.length,
              itemBuilder: (context, index) {
                return LargePriceDisplay(
                  price: widget.prices[index],
                );
              },
            ),
          ),
          // Navigation hint
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.grey,
                    size: 32,
                  )
                else
                  const SizedBox(width: 32),
                if (_currentIndex < widget.prices.length - 1)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 32,
                  )
                else
                  const SizedBox(width: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
