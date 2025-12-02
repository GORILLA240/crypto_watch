import 'package:flutter/material.dart';
import '../../../../core/routing/app_router.dart';
import '../widgets/price_stats.dart';

/// 価格詳細画面
class PriceDetailPage extends StatefulWidget {
  final String symbol;

  const PriceDetailPage({
    super.key,
    required this.symbol,
  });

  @override
  State<PriceDetailPage> createState() => _PriceDetailPageState();
}

class _PriceDetailPageState extends State<PriceDetailPage> {
  String _selectedPeriod = '24H';

  @override
  Widget build(BuildContext context) {
    // TODO: Implement with Bloc
    // For now, showing placeholder UI
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.symbol,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              AppRouter.navigateTo(context, AppRoutes.favorites);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              AppRouter.navigateTo(context, AppRoutes.alerts);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price display
            const Center(
              child: Column(
                children: [
                  Text(
                    '¥5,000,000',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '+2.5%',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Chart period selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['1H', '24H', '7D'].map((period) {
                final isSelected = _selectedPeriod == period;
                return TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedPeriod = period;
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor:
                        isSelected ? Colors.blue : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    period,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Chart placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'チャートデータを読み込み中...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Stats
            const PriceStats(
              high24h: 5200000,
              low24h: 4800000,
              volume24h: 1000000000,
            ),
          ],
        ),
      ),
    );
  }
}
