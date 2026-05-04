import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_percas/data/models/perca_stock_model.dart';

void main() {
  group('PercasStock', () {
    final testDate = DateTime(2024, 3, 10);

    group('generateSackCode', () {
      test('generates K-prefix for "kaos" type (integer weight)', () {
        final code = PercasStock.generateSackCode('kaos', 45.0);
        expect(code, 'K-45');
      });

      test('generates K-prefix for "Kaos" (uppercase) type', () {
        final code = PercasStock.generateSackCode('Kaos', 30.0);
        expect(code, 'K-30');
      });

      test('generates B-prefix for non-kaos type (kain)', () {
        final code = PercasStock.generateSackCode('kain', 25.0);
        expect(code, 'B-25');
      });

      test('generates B-prefix for unknown perca type', () {
        final code = PercasStock.generateSackCode('other', 10.0);
        expect(code, 'B-10');
      });

      test('generates code with decimal weight when not integer', () {
        final code = PercasStock.generateSackCode('kaos', 12.5);
        expect(code, 'K-12.50');
      });

      test('generates code with zero weight', () {
        final code = PercasStock.generateSackCode('kaos', 0.0);
        expect(code, 'K-0');
      });
    });

    group('toJson', () {
      test('should convert PercasStock to JSON correctly', () {
        final stock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: testDate,
          percaType: 'kaos',
          weight: 45.0,
          deliveryProof: 'https://example.com/proof.jpg',
          sackCode: 'K-45',
        );

        final json = stock.toJson();

        expect(json['id_factory'], 'factory-001');
        expect(json['perca_type'], 'kaos');
        expect(json['weight'], 45.0);
        expect(json['delivery_proof'], 'https://example.com/proof.jpg');
        expect(json['sack_code'], 'K-45');
        expect(json.containsKey('date_entry'), isTrue);
      });

      test('should include date_entry as ISO 8601 string', () {
        final stock = PercasStock(
          idFactory: 'factory-001',
          dateEntry: DateTime(2024, 3, 10),
          percaType: 'kain',
          weight: 20.0,
          deliveryProof: 'https://example.com/proof2.jpg',
          sackCode: 'B-20',
        );

        final json = stock.toJson();
        final dateStr = json['date_entry'] as String;

        // Should parse back to the same date
        expect(DateTime.parse(dateStr).year, 2024);
        expect(DateTime.parse(dateStr).month, 3);
        expect(DateTime.parse(dateStr).day, 10);
      });
    });
  });
}
