import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_tailors/data/models/tailor_model.dart';

void main() {
  group('TailorModel Extended Tests', () {
    const testId = '123e4567-e89b-12d3-a456-426614174000';
    const testName = 'John Doe';
    const testNoTelp = '081234567890';
    const testAddress = 'Jl. Test No. 1';
    const testTailorImages = 'https://example.com/image.jpg';
    final testCreatedAt = DateTime(2024, 1, 1);
    const testTotalStock = 100.0;
    const testBalance = 5000.0;

    late TailorModel testTailor;

    setUp(() {
      testTailor = TailorModel(
        id: testId,
        name: testName,
        noTelp: testNoTelp,
        address: testAddress,
        createdAt: testCreatedAt,
        tailorImages: testTailorImages,
        totalStock: testTotalStock,
        balance: testBalance,
      );
    });

    group('Constructor with all fields', () {
      test('should create TailorModel with all fields', () {
        expect(testTailor.id, testId);
        expect(testTailor.name, testName);
        expect(testTailor.noTelp, testNoTelp);
        expect(testTailor.address, testAddress);
        expect(testTailor.createdAt, testCreatedAt);
        expect(testTailor.tailorImages, testTailorImages);
        expect(testTailor.totalStock, testTotalStock);
        expect(testTailor.balance, testBalance);
      });

      test('should create TailorModel with defaults', () {
        final tailor = TailorModel(
          id: testId,
          name: testName,
          noTelp: testNoTelp,
          address: testAddress,
          createdAt: testCreatedAt,
        );

        expect(tailor.id, testId);
        expect(tailor.tailorImages, isNull);
        expect(tailor.totalStock, 0);
        expect(tailor.balance, 0);
      });
    });

    group('fromJson with all fields', () {
      test('should parse complete JSON correctly', () {
        final json = {
          'id': testId,
          'name': testName,
          'no_telp': testNoTelp,
          'address': testAddress,
          'tailor_images': testTailorImages,
          'created_at': '2024-01-01T00:00:00.000Z',
          'total_stock': testTotalStock,
          'balance': testBalance,
        };

        final tailor = TailorModel.fromJson(json);

        expect(tailor.id, testId);
        expect(tailor.name, testName);
        expect(tailor.noTelp, testNoTelp);
        expect(tailor.address, testAddress);
        expect(tailor.tailorImages, testTailorImages);
        expect(tailor.totalStock, testTotalStock);
        expect(tailor.balance, testBalance);
      });

      test('should parse numeric values as doubles', () {
        final json = {
          'id': testId,
          'name': testName,
          'no_telp': testNoTelp,
          'address': testAddress,
          'created_at': '2024-01-01T00:00:00.000Z',
          'total_stock': 100,
          'balance': 5000,
        };

        final tailor = TailorModel.fromJson(json);

        expect(tailor.totalStock, 100.0);
        expect(tailor.balance, 5000.0);
      });

      test('should parse string numeric values', () {
        final json = {
          'id': testId,
          'name': testName,
          'no_telp': testNoTelp,
          'address': testAddress,
          'created_at': '2024-01-01T00:00:00.000Z',
          'total_stock': '50.5',
          'balance': '2500.75',
        };

        final tailor = TailorModel.fromJson(json);

        expect(tailor.totalStock, 50.5);
        expect(tailor.balance, 2500.75);
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': testId,
          'name': testName,
          'no_telp': testNoTelp,
          'address': testAddress,
          'created_at': '2024-01-01T00:00:00.000Z',
        };

        final tailor = TailorModel.fromJson(json);

        expect(tailor.tailorImages, isNull);
        expect(tailor.totalStock, 0);
        expect(tailor.balance, 0);
      });

      test('should handle null values gracefully', () {
        final json = {
          'id': null,
          'name': null,
          'no_telp': null,
          'address': null,
          'created_at': null,
          'tailor_images': null,
          'total_stock': null,
          'balance': null,
        };

        final tailor = TailorModel.fromJson(json);

        expect(tailor.id, '');
        expect(tailor.name, '');
        expect(tailor.noTelp, '');
        expect(tailor.address, '');
        expect(tailor.tailorImages, isNull);
        expect(tailor.totalStock, 0);
        expect(tailor.balance, 0);
      });

      test('should use current time if created_at is null', () {
        final before = DateTime.now();
        final json = {
          'id': testId,
          'name': testName,
          'no_telp': testNoTelp,
          'address': testAddress,
          'created_at': null,
        };

        final tailor = TailorModel.fromJson(json);
        final after = DateTime.now();

        expect(tailor.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(tailor.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
      });

      test('should parse ISO 8601 dates correctly', () {
        final json = {
          'id': testId,
          'name': testName,
          'no_telp': testNoTelp,
          'address': testAddress,
          'created_at': '2024-06-15T14:30:00.000Z',
        };

        final tailor = TailorModel.fromJson(json);

        expect(tailor.createdAt.year, 2024);
        expect(tailor.createdAt.month, 6);
        expect(tailor.createdAt.day, 15);
      });

      test('should handle invalid numeric values with zero', () {
        final json = {
          'id': testId,
          'name': testName,
          'no_telp': testNoTelp,
          'address': testAddress,
          'created_at': '2024-01-01T00:00:00.000Z',
          'total_stock': 'invalid',
          'balance': 'not_a_number',
        };

        final tailor = TailorModel.fromJson(json);

        expect(tailor.totalStock, 0);
        expect(tailor.balance, 0);
      });
    });

    group('toJson', () {
      test('should convert to JSON correctly', () {
        final json = testTailor.toJson();

        expect(json['id'], testId);
        expect(json['name'], testName);
        expect(json['no_telp'], testNoTelp);
        expect(json['address'], testAddress);
        expect(json['tailor_images'], testTailorImages);
        expect(json.containsKey('total_stock'), isFalse);
        expect(json.containsKey('balance'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
      });

      test('should handle null tailorImages in toJson', () {
        final tailor = TailorModel(
          id: testId,
          name: testName,
          noTelp: testNoTelp,
          address: testAddress,
          createdAt: testCreatedAt,
        );

        final json = tailor.toJson();

        expect(json['tailor_images'], isNull);
      });

      test('should not include database-managed fields', () {
        final json = testTailor.toJson();

        expect(json.containsKey('total_stock'), isFalse);
        expect(json.containsKey('balance'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
      });
    });

    group('copyWith', () {
      test('should copy with single field change', () {
        final updated = testTailor.copyWith(name: 'Jane Doe');

        expect(updated.id, testTailor.id);
        expect(updated.name, 'Jane Doe');
        expect(updated.noTelp, testTailor.noTelp);
        expect(updated.totalStock, testTailor.totalStock);
        expect(updated.balance, testTailor.balance);
      });

      test('should copy with multiple field changes', () {
        final updated = testTailor.copyWith(
          name: 'Jane Doe',
          noTelp: '089876543210',
          address: 'Jl. New Address',
          balance: 10000.0,
        );

        expect(updated.id, testTailor.id);
        expect(updated.name, 'Jane Doe');
        expect(updated.noTelp, '089876543210');
        expect(updated.address, 'Jl. New Address');
        expect(updated.balance, 10000.0);
        expect(updated.totalStock, testTailor.totalStock);
      });

      test('should copy with new createdAt', () {
        final newDate = DateTime(2024, 6, 1);
        final updated = testTailor.copyWith(createdAt: newDate);

        expect(updated.createdAt, newDate);
        expect(updated.name, testTailor.name);
      });

      test('should copy with new totalStock and balance', () {
        final updated = testTailor.copyWith(
          totalStock: 200.0,
          balance: 10000.0,
        );

        expect(updated.totalStock, 200.0);
        expect(updated.balance, 10000.0);
        expect(updated.id, testTailor.id);
      });

      test('should not modify original when using copyWith', () {
        final original = TailorModel(
          id: 'id-1',
          name: 'Original',
          noTelp: '081111111111',
          address: 'Original Address',
          createdAt: DateTime(2024, 1, 1),
          totalStock: 100.0,
          balance: 5000.0,
        );

        final modified = original.copyWith(
          name: 'Modified',
          totalStock: 200.0,
        );

        expect(original.name, 'Original');
        expect(original.totalStock, 100.0);
        expect(modified.name, 'Modified');
        expect(modified.totalStock, 200.0);
      });

      test('should return identical copy when no changes', () {
        final copy = testTailor.copyWith();

        expect(copy.id, testTailor.id);
        expect(copy.name, testTailor.name);
        expect(copy.noTelp, testTailor.noTelp);
        expect(copy.totalStock, testTailor.totalStock);
      });
    });

    group('toString', () {
      test('should contain class name and key fields', () {
        final str = testTailor.toString();

        expect(str, contains('TailorModel'));
        expect(str, contains(testId));
        expect(str, contains(testName));
        expect(str, contains(testNoTelp));
        expect(str, contains(testTotalStock.toString()));
        expect(str, contains(testBalance.toString()));
      });
    });

    group('Equality and Hash', () {
      test('should be equal when ids match', () {
        final a = TailorModel(
          id: testId,
          name: 'Name A',
          noTelp: '081111111111',
          address: 'Address A',
          createdAt: DateTime(2024, 1, 1),
          totalStock: 50.0,
          balance: 2500.0,
        );

        final b = TailorModel(
          id: testId,
          name: 'Name B',
          noTelp: '089999999999',
          address: 'Address B',
          createdAt: DateTime(2024, 6, 1),
          totalStock: 150.0,
          balance: 7500.0,
        );

        expect(a == b, isTrue);
      });

      test('should not be equal when ids differ', () {
        final a = testTailor;
        final b = testTailor.copyWith(id: 'different-id');

        expect(a == b, isFalse);
      });

      test('should have same hashCode when ids match', () {
        final a = TailorModel(
          id: testId,
          name: 'Name A',
          noTelp: '081111111111',
          address: 'Address A',
          createdAt: DateTime(2024, 1, 1),
        );

        final b = TailorModel(
          id: testId,
          name: 'Name B',
          noTelp: '089999999999',
          address: 'Address B',
          createdAt: DateTime(2024, 6, 1),
        );

        expect(a.hashCode, b.hashCode);
      });

      test('should support equality in sets', () {
        final tailor1 = TailorModel(
          id: 'id-1',
          name: 'Tailor 1',
          noTelp: '081111111111',
          address: 'Address 1',
          createdAt: DateTime(2024, 1, 1),
        );

        final tailor2 = TailorModel(
          id: 'id-1',
          name: 'Tailor 1 Updated',
          noTelp: '081111111111',
          address: 'Address 1 Updated',
          createdAt: DateTime(2024, 1, 1),
        );

        final set = {tailor1};
        expect(set.contains(tailor2), isTrue);
      });
    });

    group('Edge cases', () {
      test('should handle empty strings', () {
        final tailor = TailorModel(
          id: '',
          name: '',
          noTelp: '',
          address: '',
          createdAt: DateTime.now(),
        );

        expect(tailor.id, '');
        expect(tailor.name, '');
      });

      test('should handle very long strings', () {
        const longString = 'A' * 1000;
        final tailor = TailorModel(
          id: longString,
          name: longString,
          noTelp: longString,
          address: longString,
          createdAt: DateTime.now(),
        );

        expect(tailor.id.length, 1000);
        expect(tailor.name.length, 1000);
      });

      test('should handle special characters', () {
        const specialChars = 'Test!@#$%^&*()_+-=[]{}|;:,.<>?/~`';
        final tailor = TailorModel(
          id: specialChars,
          name: specialChars,
          noTelp: specialChars,
          address: specialChars,
          createdAt: DateTime.now(),
        );

        expect(tailor.id, specialChars);
        expect(tailor.name, specialChars);
      });

      test('should handle zero balance and stock', () {
        final tailor = TailorModel(
          id: testId,
          name: testName,
          noTelp: testNoTelp,
          address: testAddress,
          createdAt: testCreatedAt,
          totalStock: 0,
          balance: 0,
        );

        expect(tailor.totalStock, 0);
        expect(tailor.balance, 0);
      });

      test('should handle negative values', () {
        final tailor = TailorModel(
          id: testId,
          name: testName,
          noTelp: testNoTelp,
          address: testAddress,
          createdAt: testCreatedAt,
          totalStock: -50.0,
          balance: -2500.0,
        );

        expect(tailor.totalStock, -50.0);
        expect(tailor.balance, -2500.0);
      });

      test('should handle very large numbers', () {
        const largeNumber = 999999999.99;
        final tailor = TailorModel(
          id: testId,
          name: testName,
          noTelp: testNoTelp,
          address: testAddress,
          createdAt: testCreatedAt,
          totalStock: largeNumber,
          balance: largeNumber,
        );

        expect(tailor.totalStock, largeNumber);
        expect(tailor.balance, largeNumber);
      });
    });

    group('JSON round-trip', () {
      test('should maintain data through toJson -> fromJson', () {
        final original = testTailor;
        final json = original.toJson();
        final restored = TailorModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.noTelp, original.noTelp);
        expect(restored.address, original.address);
        expect(restored.tailorImages, original.tailorImages);
      });
    });
  });
}
