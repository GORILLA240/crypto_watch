import 'package:flutter/material.dart';

void main() {
  runApp(const CryptoWatchApp());
}

class CryptoWatchApp extends StatelessWidget {
  const CryptoWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Watch',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const PriceHomePage(),
    );
  }
}

class PriceHomePage extends StatefulWidget {
  const PriceHomePage({super.key});

  @override
  State<PriceHomePage> createState() => _PriceHomePageState();
}

class _PriceHomePageState extends State<PriceHomePage> {
  double? price;

  Future<void> fetchPrice() async {
    // TODO: 後でAPI呼び出しに差し替える
    setState(() {
      price = 1234567.0; // 仮の数字
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crypto Watch')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              price == null ? 'Press the button!' : 'BTC/JPY: ¥${price!.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchPrice,
              child: const Text('Get Price'),
            ),
          ],
        ),
      ),
    );
  }
}
