import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_tailors/data/models/tailor_model.dart';

void main() {
  group('TailorModel', () {
    test('should create TailorModel from JSON', () {
      // Arrange
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'name': 'John Doe',
        'no_telp': '081234567890',
        'address': 'Jl. Test No. 1',
        'tailor_images': 'https://example.com/image.jpg',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      // Act
      final tailor = TailorModel.fromJson(json);

      // Assert
      expect(tailor.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(tailor.name, 'John Doe');
      expect(tailor.noTelp, '081234567890');
      expect(tailor.address, 'Jl. Test No. 1');
      expect(tailor.tailorImages, 'https://example.com/image.jpg');
      expect(tailor.createdAt, isNotNull);
    });

    test('should handle null tailor_images gracefully', () {
      // Arrange
      final json = {
        'id': '123',
        'name': 'Jane Doe',
        'no_telp': '081234567890',
        'address': 'Jl. Test No. 2',
        'tailor_images': null,
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      // Act
      final tailor = TailorModel.fromJson(json);

      // Assert
      expect(tailor.name, 'Jane Doe');
      expect(tailor.tailorImages, isNull);
      expect(tailor.createdAt, isNotNull);
    });

    test('should convert TailorModel to JSON', () {
      // Arrange
      final createdAt = DateTime(2024, 1, 1);
      final tailor = TailorModel(
        id: '123',
        name: 'John Doe',
        noTelp: '081234567890',
        address: 'Jl. Test No. 1',
        createdAt: createdAt,
        tailorImages: 'https://example.com/image.jpg',
      );

      // Act
      final json = tailor.toJson();

      // Assert
      expect(json['id'], '123');
      expect(json['name'], 'John Doe');
      expect(json['no_telp'], '081234567890');
      expect(json['address'], 'Jl. Test No. 1');
      expect(json['tailor_images'], 'https://example.com/image.jpg');
    });

    test('should create copy with modified fields', () {
      // Arrange
      final createdAt = DateTime(2024, 1, 1);
      final original = TailorModel(
        id: '123',
        name: 'John Doe',
        noTelp: '081234567890',
        address: 'Jl. Test No. 1',
        createdAt: createdAt,
      );

      // Act
      final modified = original.copyWith(
        name: 'Jane Doe',
        address: 'Jl. Test No. 2',
      );

      // Assert
      expect(modified.id, original.id);
      expect(modified.name, 'Jane Doe');
      expect(modified.address, 'Jl. Test No. 2');
      expect(modified.noTelp, original.noTelp);
      expect(modified.createdAt, original.createdAt);
    });

    test('should compare TailorModels by id', () {
      // Arrange
      final createdAt = DateTime(2024, 1, 1);
      final tailor1 = TailorModel(
        id: '123',
        name: 'John Doe',
        noTelp: '081234567890',
        address: 'Jl. Test No. 1',
        createdAt: createdAt,
      );

      final tailor2 = TailorModel(
        id: '123',
        name: 'Different Name',
        noTelp: '089876543210',
        address: 'Jl. Test No. 2',
        createdAt: createdAt,
      );

      final tailor3 = TailorModel(
        id: '456',
        name: 'John Doe',
        noTelp: '081234567890',
        address: 'Jl. Test No. 1',
        createdAt: createdAt,
      );

      // Assert
      expect(tailor1 == tailor2, true); // Same ID
      expect(tailor1 == tailor3, false); // Different ID
    });
  });
}
