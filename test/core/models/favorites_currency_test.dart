import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_watch/core/models/favorites_currency.dart';

void main() {
  group('FavoritesCurrency', () {
    test('fromJson creates valid FavoritesCurrency', () {
      // Arrange
      final json = {
        'symbol': 'BTC',
        'is_default': true,
        'added_at': '2024-01-01T00:00:00.000Z',
        'display_order': 0,
      };

      // Act
      final currency = FavoritesCurrency.fromJson(json);

      // Assert
      expect(currency.symbol, equals('BTC'));
      expect(currency.isDefault, isTrue);
      expect(currency.addedAt, equals(DateTime.parse('2024-01-01T00:00:00.000Z')));
      expect(currency.displayOrder, equals(0));
    });

    test('fromJson handles alternative field names', () {
      // Arrange
      final json = {
        'symbol': 'ETH',
        'is_default': false,
        'addedAt': '2024-01-01T00:00:00.000Z', // alternative field name
        'display_order': 1,
      };

      // Act
      final currency = FavoritesCurrency.fromJson(json);

      // Assert
      expect(currency.symbol, equals('ETH'));
      expect(currency.addedAt, equals(DateTime.parse('2024-01-01T00:00:00.000Z')));
    });

    test('fromJson handles Unix timestamp in seconds', () {
      // Arrange
      final json = {
        'symbol': 'ADA',
        'is_default': true,
        'added_at': 1704067200, // 2024-01-01 00:00:00 UTC in seconds
        'display_order': 2,
      };

      // Act
      final currency = FavoritesCurrency.fromJson(json);

      // Assert
      expect(currency.symbol, equals('ADA'));
      expect(currency.addedAt.year, equals(2024));
      expect(currency.addedAt.month, equals(1));
      expect(currency.addedAt.day, equals(1));
    });

    test('fromJson handles Unix timestamp in milliseconds', () {
      // Arrange
      final json = {
        'symbol': 'BNB',
        'is_default': true,
        'added_at': 1704067200000, // 2024-01-01 00:00:00 UTC in milliseconds
        'display_order': 3,
      };

      // Act
      final currency = FavoritesCurrency.fromJson(json);

      // Assert
      expect(currency.symbol, equals('BNB'));
      expect(currency.addedAt.year, equals(2024));
      expect(currency.addedAt.month, equals(1));
      expect(currency.addedAt.day, equals(1));
    });

    test('fromJson defaults isDefault to false when missing', () {
      // Arrange
      final json = {
        'symbol': 'SHIB',
        'added_at': '2024-01-01T00:00:00.000Z',
        'display_order': 4,
      };

      // Act
      final currency = FavoritesCurrency.fromJson(json);

      // Assert
      expect(currency.isDefault, isFalse);
    });

    test('fromJson defaults displayOrder to 0 when missing', () {
      // Arrange
      final json = {
        'symbol': 'PEPE',
        'is_default': false,
        'added_at': '2024-01-01T00:00:00.000Z',
      };

      // Act
      final currency = FavoritesCurrency.fromJson(json);

      // Assert
      expect(currency.displayOrder, equals(0));
    });

    test('fromJson throws FormatException for invalid data', () {
      // Arrange
      final json = {
        'symbol': 'BTC',
        'is_default': true,
        'added_at': null, // invalid
        'display_order': 0,
      };

      // Act & Assert
      expect(
        () => FavoritesCurrency.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('toJson creates valid JSON', () {
      // Arrange
      final currency = FavoritesCurrency(
        symbol: 'BTC',
        isDefault: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        displayOrder: 0,
      );

      // Act
      final json = currency.toJson();

      // Assert
      expect(json['symbol'], equals('BTC'));
      expect(json['is_default'], isTrue);
      expect(json['added_at'], equals('2024-01-01T00:00:00.000Z'));
      expect(json['display_order'], equals(0));
    });

    test('copyWith creates new instance with updated fields', () {
      // Arrange
      final original = FavoritesCurrency(
        symbol: 'BTC',
        isDefault: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        displayOrder: 0,
      );

      // Act
      final updated = original.copyWith(
        symbol: 'ETH',
        displayOrder: 5,
      );

      // Assert
      expect(updated.symbol, equals('ETH'));
      expect(updated.isDefault, equals(original.isDefault));
      expect(updated.addedAt, equals(original.addedAt));
      expect(updated.displayOrder, equals(5));
    });

    test('copyWith without parameters returns identical instance', () {
      // Arrange
      final original = FavoritesCurrency(
        symbol: 'BTC',
        isDefault: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        displayOrder: 0,
      );

      // Act
      final copy = original.copyWith();

      // Assert
      expect(copy.symbol, equals(original.symbol));
      expect(copy.isDefault, equals(original.isDefault));
      expect(copy.addedAt, equals(original.addedAt));
      expect(copy.displayOrder, equals(original.displayOrder));
    });

    test('equality works correctly', () {
      // Arrange
      final currency1 = FavoritesCurrency(
        symbol: 'BTC',
        isDefault: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        displayOrder: 0,
      );

      final currency2 = FavoritesCurrency(
        symbol: 'BTC',
        isDefault: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        displayOrder: 0,
      );

      final currency3 = FavoritesCurrency(
        symbol: 'ETH',
        isDefault: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        displayOrder: 0,
      );

      // Assert
      expect(currency1, equals(currency2));
      expect(currency1, isNot(equals(currency3)));
    });

    test('toString returns formatted string', () {
      // Arrange
      final currency = FavoritesCurrency(
        symbol: 'BTC',
        isDefault: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        displayOrder: 0,
      );

      // Act
      final string = currency.toString();

      // Assert
      expect(string, contains('BTC'));
      expect(string, contains('true'));
      expect(string, contains('2024-01-01'));
      expect(string, contains('0'));
    });

    test('round-trip JSON serialization preserves data', () {
      // Arrange
      final original = FavoritesCurrency(
        symbol: 'BTC',
        isDefault: true,
        addedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        displayOrder: 0,
      );

      // Act
      final json = original.toJson();
      final restored = FavoritesCurrency.fromJson(json);

      // Assert
      expect(restored, equals(original));
    });
  });
}
