import 'package:intl/intl.dart';

/// 日付フォーマットユーティリティクラス
class DateFormatter {
  // プライベートコンストラクタ - インスタンス化を防ぐ
  DateFormatter._();

  /// 日付を標準形式でフォーマット（例: 2024年1月1日）
  static String formatDate(DateTime dateTime, {String locale = 'ja_JP'}) {
    final formatter = DateFormat.yMMMd(locale);
    return formatter.format(dateTime);
  }

  /// 時刻を標準形式でフォーマット（例: 14:30）
  static String formatTime(DateTime dateTime, {String locale = 'ja_JP'}) {
    final formatter = DateFormat.Hm(locale);
    return formatter.format(dateTime);
  }

  /// 日付と時刻を標準形式でフォーマット（例: 2024年1月1日 14:30）
  static String formatDateTime(DateTime dateTime, {String locale = 'ja_JP'}) {
    final formatter = DateFormat.yMMMd(locale).add_Hm();
    return formatter.format(dateTime);
  }

  /// 相対時間を表示（例: 3分前、1時間前）
  static String formatRelative(DateTime dateTime, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final difference = currentTime.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}秒前';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks週間前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ヶ月前';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years年前';
    }
  }

  /// ISO 8601形式でフォーマット（例: 2024-01-01T14:30:00.000Z）
  static String formatIso8601(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// ISO 8601形式からDateTimeに変換
  static DateTime parseIso8601(String dateTimeString) {
    return DateTime.parse(dateTimeString);
  }

  /// タイムスタンプ（ミリ秒）からDateTimeに変換
  static DateTime fromMilliseconds(int milliseconds) {
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  /// DateTimeをタイムスタンプ（ミリ秒）に変換
  static int toMilliseconds(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }

  /// タイムスタンプ（秒）からDateTimeに変換
  static DateTime fromSeconds(int seconds) {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  /// DateTimeをタイムスタンプ（秒）に変換
  static int toSeconds(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch ~/ 1000;
  }

  /// 短い日付形式（例: 1/1）
  static String formatShortDate(DateTime dateTime, {String locale = 'ja_JP'}) {
    final formatter = DateFormat.Md(locale);
    return formatter.format(dateTime);
  }

  /// 短い時刻形式（例: 14:30）
  static String formatShortTime(DateTime dateTime) {
    final formatter = DateFormat.Hm();
    return formatter.format(dateTime);
  }

  /// 月と日のみ（例: 1月1日）
  static String formatMonthDay(DateTime dateTime, {String locale = 'ja_JP'}) {
    final formatter = DateFormat.MMMd(locale);
    return formatter.format(dateTime);
  }

  /// 年と月のみ（例: 2024年1月）
  static String formatYearMonth(DateTime dateTime, {String locale = 'ja_JP'}) {
    final formatter = DateFormat.yMMM(locale);
    return formatter.format(dateTime);
  }

  /// 曜日を含む日付（例: 2024年1月1日（月））
  static String formatDateWithWeekday(DateTime dateTime,
      {String locale = 'ja_JP'}) {
    final formatter = DateFormat.yMMMEd(locale);
    return formatter.format(dateTime);
  }

  /// 今日、昨日、それ以前を判定して表示
  static String formatSmart(DateTime dateTime, {String locale = 'ja_JP'}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == today) {
      return '今日 ${formatTime(dateTime, locale: locale)}';
    } else if (dateOnly == yesterday) {
      return '昨日 ${formatTime(dateTime, locale: locale)}';
    } else if (now.difference(dateTime).inDays < 7) {
      return formatDateWithWeekday(dateTime, locale: locale);
    } else {
      return formatDateTime(dateTime, locale: locale);
    }
  }

  /// 期間をフォーマット（例: 2時間30分）
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}日${duration.inHours % 24}時間';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}時間${duration.inMinutes % 60}分';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分${duration.inSeconds % 60}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  /// 2つの日付の差を人間が読みやすい形式で表示
  static String formatDifference(DateTime start, DateTime end) {
    final difference = end.difference(start);
    return formatDuration(difference);
  }

  /// 日付が今日かどうかを判定
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// 日付が昨日かどうかを判定
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  /// 日付が今週かどうかを判定
  static bool isThisWeek(DateTime dateTime) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return dateTime.isAfter(startOfWeek) && dateTime.isBefore(endOfWeek);
  }

  /// 日付が今月かどうかを判定
  static bool isThisMonth(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year && dateTime.month == now.month;
  }

  /// 日付が今年かどうかを判定
  static bool isThisYear(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year;
  }
}
