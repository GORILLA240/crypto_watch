import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// 通貨フォーマットユーティリティクラス
class CurrencyFormatter {
  // プライベートコンストラクタ - インスタンス化を防ぐ
  CurrencyFormatter._();

  /// 価格を指定された通貨でフォーマット
  static String format(
    double price, {
    String currency = AppConstants.defaultCurrency,
    int? decimalDigits,
  }) {
    // 通貨記号を取得
    final symbol = AppConstants.currencySymbols[currency] ?? '';

    // 小数点以下の桁数を決定
    final digits = decimalDigits ?? _getDefaultDecimalDigits(price, currency);

    // フォーマッターを作成
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: digits,
      locale: _getLocale(currency),
    );

    return formatter.format(price);
  }

  /// 変動率をフォーマット（パーセント表示）
  static String formatChangePercent(double changePercent) {
    final sign = changePercent >= 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(2)}%';
  }

  /// 変動額をフォーマット
  static String formatChangeAmount(
    double changeAmount, {
    String currency = AppConstants.defaultCurrency,
  }) {
    final sign = changeAmount >= 0 ? '+' : '';
    final formatted = format(changeAmount.abs(), currency: currency);
    return '$sign$formatted';
  }

  /// 時価総額をフォーマット（短縮形）
  static String formatMarketCap(
    double marketCap, {
    String currency = AppConstants.defaultCurrency,
  }) {
    final symbol = AppConstants.currencySymbols[currency] ?? '';

    if (marketCap >= 1e12) {
      // 1兆以上
      return '$symbol${(marketCap / 1e12).toStringAsFixed(2)}T';
    } else if (marketCap >= 1e9) {
      // 10億以上
      return '$symbol${(marketCap / 1e9).toStringAsFixed(2)}B';
    } else if (marketCap >= 1e6) {
      // 100万以上
      return '$symbol${(marketCap / 1e6).toStringAsFixed(2)}M';
    } else if (marketCap >= 1e3) {
      // 1000以上
      return '$symbol${(marketCap / 1e3).toStringAsFixed(2)}K';
    } else {
      return format(marketCap, currency: currency);
    }
  }

  /// 出来高をフォーマット（短縮形）
  static String formatVolume(double volume) {
    if (volume >= 1e12) {
      return '${(volume / 1e12).toStringAsFixed(2)}T';
    } else if (volume >= 1e9) {
      return '${(volume / 1e9).toStringAsFixed(2)}B';
    } else if (volume >= 1e6) {
      return '${(volume / 1e6).toStringAsFixed(2)}M';
    } else if (volume >= 1e3) {
      return '${(volume / 1e3).toStringAsFixed(2)}K';
    } else {
      return volume.toStringAsFixed(2);
    }
  }

  /// 通貨間の変換
  /// 注意: バックエンドAPIから返される価格はUSD建てと仮定
  static double convert(
    double amount, {
    required String fromCurrency,
    required String toCurrency,
    double? btcPrice,
  }) {
    // 同じ通貨の場合は変換不要
    if (fromCurrency == toCurrency) {
      return amount;
    }

    // BTCへの変換またはBTCからの変換
    if (fromCurrency == 'BTC') {
      // BTCから他の通貨へ
      if (btcPrice == null) {
        throw ArgumentError('BTC価格が必要です');
      }
      final usdAmount = amount * btcPrice;
      return _convertFromUsd(usdAmount, toCurrency);
    } else if (toCurrency == 'BTC') {
      // 他の通貨からBTCへ
      if (btcPrice == null) {
        throw ArgumentError('BTC価格が必要です');
      }
      final usdAmount = _convertToUsd(amount, fromCurrency);
      return usdAmount / btcPrice;
    }

    // 法定通貨間の変換（USDを基準通貨として使用）
    final usdAmount = _convertToUsd(amount, fromCurrency);
    return _convertFromUsd(usdAmount, toCurrency);
  }

  /// 指定通貨からUSDに変換
  static double _convertToUsd(double amount, String currency) {
    switch (currency) {
      case 'USD':
        return amount;
      case 'JPY':
        return amount / 150.0; // 1 USD = 150 JPY（仮の為替レート）
      case 'EUR':
        return amount / 0.92; // 1 USD = 0.92 EUR（仮の為替レート）
      default:
        throw ArgumentError('サポートされていない通貨: $currency');
    }
  }

  /// USDから指定通貨に変換
  static double _convertFromUsd(double usdAmount, String currency) {
    switch (currency) {
      case 'USD':
        return usdAmount;
      case 'JPY':
        return usdAmount * 150.0; // 1 USD = 150 JPY（仮の為替レート）
      case 'EUR':
        return usdAmount * 0.92; // 1 USD = 0.92 EUR（仮の為替レート）
      default:
        throw ArgumentError('サポートされていない通貨: $currency');
    }
  }

  /// デフォルトの小数点以下桁数を取得
  static int _getDefaultDecimalDigits(double price, String currency) {
    // BTCの場合は8桁
    if (currency == 'BTC') {
      return 8;
    }

    // 価格に応じて桁数を調整
    if (price >= 1000) {
      return 0; // 1000以上は整数表示
    } else if (price >= 1) {
      return 2; // 1以上は小数点2桁
    } else if (price >= 0.01) {
      return 4; // 0.01以上は小数点4桁
    } else {
      return 8; // それ以下は小数点8桁
    }
  }

  /// ロケールを取得
  static String _getLocale(String currency) {
    switch (currency) {
      case 'JPY':
        return 'ja_JP';
      case 'USD':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      default:
        return 'en_US';
    }
  }

  /// 数値を読みやすい形式にフォーマット（カンマ区切り）
  static String formatNumber(double number, {int decimalDigits = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimalDigits}');
    return formatter.format(number);
  }

  /// コンパクトな数値フォーマット（K, M, B, T）
  static String formatCompact(double number) {
    if (number >= 1e12) {
      return '${(number / 1e12).toStringAsFixed(1)}T';
    } else if (number >= 1e9) {
      return '${(number / 1e9).toStringAsFixed(1)}B';
    } else if (number >= 1e6) {
      return '${(number / 1e6).toStringAsFixed(1)}M';
    } else if (number >= 1e3) {
      return '${(number / 1e3).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(1);
    }
  }
}
