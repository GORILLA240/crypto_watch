import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../error/exceptions.dart';

/// ローカルストレージの抽象インターフェース
abstract class LocalStorage {
  // 文字列の読み書き
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);

  // 整数の読み書き
  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);

  // 真偽値の読み書き
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);

  // 浮動小数点数の読み書き
  Future<double?> getDouble(String key);
  Future<void> setDouble(String key, double value);

  // リストの読み書き
  Future<List<String>?> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);

  // JSONオブジェクトの読み書き
  Future<Map<String, dynamic>?> getJson(String key);
  Future<void> setJson(String key, Map<String, dynamic> value);

  // キーの削除
  Future<void> remove(String key);

  // すべてのキーをクリア
  Future<void> clear();

  // キーの存在確認
  Future<bool> containsKey(String key);
}

/// SharedPreferencesを使用したローカルストレージの実装
class LocalStorageImpl implements LocalStorage {
  final SharedPreferences sharedPreferences;
  final FlutterSecureStorage secureStorage;

  LocalStorageImpl({
    required this.sharedPreferences,
    FlutterSecureStorage? secureStorage,
  }) : secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<String?> getString(String key) async {
    try {
      return sharedPreferences.getString(key);
    } catch (e) {
      throw StorageException(
        message: 'データの読み込みに失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      final success = await sharedPreferences.setString(key, value);
      if (!success) {
        throw StorageException(
          message: 'データの保存に失敗しました: $key',
        );
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'データの保存に失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<int?> getInt(String key) async {
    try {
      return sharedPreferences.getInt(key);
    } catch (e) {
      throw StorageException(
        message: 'データの読み込みに失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    try {
      final success = await sharedPreferences.setInt(key, value);
      if (!success) {
        throw StorageException(
          message: 'データの保存に失敗しました: $key',
        );
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'データの保存に失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    try {
      return sharedPreferences.getBool(key);
    } catch (e) {
      throw StorageException(
        message: 'データの読み込みに失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    try {
      final success = await sharedPreferences.setBool(key, value);
      if (!success) {
        throw StorageException(
          message: 'データの保存に失敗しました: $key',
        );
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'データの保存に失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<double?> getDouble(String key) async {
    try {
      return sharedPreferences.getDouble(key);
    } catch (e) {
      throw StorageException(
        message: 'データの読み込みに失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<void> setDouble(String key, double value) async {
    try {
      final success = await sharedPreferences.setDouble(key, value);
      if (!success) {
        throw StorageException(
          message: 'データの保存に失敗しました: $key',
        );
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'データの保存に失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    try {
      return sharedPreferences.getStringList(key);
    } catch (e) {
      throw StorageException(
        message: 'データの読み込みに失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    try {
      final success = await sharedPreferences.setStringList(key, value);
      if (!success) {
        throw StorageException(
          message: 'データの保存に失敗しました: $key',
        );
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'データの保存に失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final jsonString = sharedPreferences.getString(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw StorageException(
        message: 'JSONデータの読み込みに失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      final success = await sharedPreferences.setString(key, jsonString);
      if (!success) {
        throw StorageException(
          message: 'JSONデータの保存に失敗しました: $key',
        );
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        message: 'JSONデータの保存に失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await sharedPreferences.remove(key);
    } catch (e) {
      throw StorageException(
        message: 'データの削除に失敗しました: $key',
        originalError: e,
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      await sharedPreferences.clear();
    } catch (e) {
      throw StorageException(
        message: 'ストレージのクリアに失敗しました',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return sharedPreferences.containsKey(key);
    } catch (e) {
      throw StorageException(
        message: 'キーの確認に失敗しました: $key',
        originalError: e,
      );
    }
  }

  /// セキュアストレージに文字列を保存
  Future<void> setSecureString(String key, String value) async {
    try {
      await secureStorage.write(key: key, value: value);
    } catch (e) {
      throw StorageException(
        message: 'セキュアデータの保存に失敗しました: $key',
        originalError: e,
      );
    }
  }

  /// セキュアストレージから文字列を読み込み
  Future<String?> getSecureString(String key) async {
    try {
      return await secureStorage.read(key: key);
    } catch (e) {
      throw StorageException(
        message: 'セキュアデータの読み込みに失敗しました: $key',
        originalError: e,
      );
    }
  }

  /// セキュアストレージからキーを削除
  Future<void> removeSecure(String key) async {
    try {
      await secureStorage.delete(key: key);
    } catch (e) {
      throw StorageException(
        message: 'セキュアデータの削除に失敗しました: $key',
        originalError: e,
      );
    }
  }

  /// セキュアストレージをクリア
  Future<void> clearSecure() async {
    try {
      await secureStorage.deleteAll();
    } catch (e) {
      throw StorageException(
        message: 'セキュアストレージのクリアに失敗しました',
        originalError: e,
      );
    }
  }
}
