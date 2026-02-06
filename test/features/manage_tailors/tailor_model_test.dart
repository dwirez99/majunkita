import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_tailors/data/models/tailor_model.dart';

void main() {
  group('TailorModel', () {
    test('should create TailorModel from JSON', () {
      // Arrange
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'nama_lengkap': 'John Doe',
        'email': 'john@example.com',
        'no_telp': '081234567890',
        'alamat': 'Jl. Test No. 1',
        'spesialisasi': 'Jahit Baju',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      // Act
      final tailor = TailorModel.fromJson(json);

      // Assert
      expect(tailor.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(tailor.namaLengkap, 'John Doe');
      expect(tailor.email, 'john@example.com');
      expect(tailor.noTelp, '081234567890');
      expect(tailor.alamat, 'Jl. Test No. 1');
      expect(tailor.spesialisasi, 'Jahit Baju');
      expect(tailor.createdAt, isNotNull);
      expect(tailor.updatedAt, isNotNull);
    });

    test('should handle null values gracefully', () {
      // Arrange
      final json = {
        'id': '123',
        'nama_lengkap': 'Jane Doe',
        'email': 'jane@example.com',
        'no_telp': '081234567890',
      };

      // Act
      final tailor = TailorModel.fromJson(json);

      // Assert
      expect(tailor.alamat, isNull);
      expect(tailor.spesialisasi, isNull);
      expect(tailor.createdAt, isNull);
      expect(tailor.updatedAt, isNull);
    });

    test('should convert TailorModel to JSON', () {
      // Arrange
      final tailor = TailorModel(
        id: '123',
        namaLengkap: 'John Doe',
        email: 'john@example.com',
        noTelp: '081234567890',
        alamat: 'Jl. Test No. 1',
        spesialisasi: 'Jahit Baju',
      );

      // Act
      final json = tailor.toJson();

      // Assert
      expect(json['id'], '123');
      expect(json['nama_lengkap'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['no_telp'], '081234567890');
      expect(json['alamat'], 'Jl. Test No. 1');
      expect(json['spesialisasi'], 'Jahit Baju');
    });

    test('should create copy with modified fields', () {
      // Arrange
      final original = TailorModel(
        id: '123',
        namaLengkap: 'John Doe',
        email: 'john@example.com',
        noTelp: '081234567890',
      );

      // Act
      final modified = original.copyWith(
        namaLengkap: 'Jane Doe',
        email: 'jane@example.com',
      );

      // Assert
      expect(modified.id, original.id);
      expect(modified.namaLengkap, 'Jane Doe');
      expect(modified.email, 'jane@example.com');
      expect(modified.noTelp, original.noTelp);
    });

    test('should compare TailorModels by id', () {
      // Arrange
      final tailor1 = TailorModel(
        id: '123',
        namaLengkap: 'John Doe',
        email: 'john@example.com',
        noTelp: '081234567890',
      );

      final tailor2 = TailorModel(
        id: '123',
        namaLengkap: 'Different Name',
        email: 'different@example.com',
        noTelp: '089876543210',
      );

      final tailor3 = TailorModel(
        id: '456',
        namaLengkap: 'John Doe',
        email: 'john@example.com',
        noTelp: '081234567890',
      );

      // Assert
      expect(tailor1 == tailor2, true); // Same ID
      expect(tailor1 == tailor3, false); // Different ID
    });
  });
}
