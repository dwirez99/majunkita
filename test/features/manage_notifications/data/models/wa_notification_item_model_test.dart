import 'package:flutter_test/flutter_test.dart';
import 'package:majunkita/features/manage_notifications/data/models/wa_notification_item_model.dart';

void main() {
  group('WaNotificationItemModel', () {
    final testCreatedAt = DateTime(2024, 9, 1, 12, 0, 0);

    final validJson = {
      'id': 1,
      'event_type': 'setor_majun',
      'source_table': 'majun_transactions',
      'source_id': 'txn-uuid-001',
      'recipient_role': 'penjahit',
      'recipient_phone': '08111234567',
      'message': 'Setoran majun Anda telah diterima.',
      'image_url': 'https://example.com/proof.jpg',
      'status': 'pending',
      'retry_count': 0,
      'max_retries': 3,
      'next_attempt_at': null,
      'last_error': null,
      'created_at': '2024-09-01T12:00:00.000Z',
      'updated_at': null,
      'processed_at': null,
      'latest_response_status': null,
      'latest_response_body': null,
      'latest_success': null,
      'latest_log_error_message': null,
      'latest_log_created_at': null,
    };

    late WaNotificationItemModel testModel;

    setUp(() {
      testModel = WaNotificationItemModel(
        id: 1,
        eventType: 'setor_majun',
        sourceTable: 'majun_transactions',
        sourceId: 'txn-uuid-001',
        recipientRole: 'penjahit',
        recipientPhone: '08111234567',
        message: 'Setoran majun Anda telah diterima.',
        imageUrl: 'https://example.com/proof.jpg',
        status: 'pending',
        retryCount: 0,
        maxRetries: 3,
        createdAt: testCreatedAt,
      );
    });

    group('Constructor', () {
      test('should create model with required fields', () {
        expect(testModel.id, 1);
        expect(testModel.eventType, 'setor_majun');
        expect(testModel.sourceTable, 'majun_transactions');
        expect(testModel.sourceId, 'txn-uuid-001');
        expect(testModel.recipientRole, 'penjahit');
        expect(testModel.recipientPhone, '08111234567');
        expect(testModel.message, 'Setoran majun Anda telah diterima.');
        expect(testModel.status, 'pending');
        expect(testModel.retryCount, 0);
        expect(testModel.maxRetries, 3);
      });
    });

    group('fromJson', () {
      test('should parse valid JSON correctly', () {
        final model = WaNotificationItemModel.fromJson(validJson);

        expect(model.id, 1);
        expect(model.eventType, 'setor_majun');
        expect(model.sourceTable, 'majun_transactions');
        expect(model.sourceId, 'txn-uuid-001');
        expect(model.recipientRole, 'penjahit');
        expect(model.recipientPhone, '08111234567');
        expect(model.message, 'Setoran majun Anda telah diterima.');
        expect(model.imageUrl, 'https://example.com/proof.jpg');
        expect(model.status, 'pending');
        expect(model.retryCount, 0);
        expect(model.maxRetries, 3);
      });

      test('should default status to "pending" when missing', () {
        final json = Map<String, dynamic>.from(validJson)
          ..remove('status');
        final model = WaNotificationItemModel.fromJson(json);
        expect(model.status, 'pending');
      });

      test('should default event_type to "-" when null', () {
        final json = Map<String, dynamic>.from(validJson)
          ..['event_type'] = null;
        final model = WaNotificationItemModel.fromJson(json);
        expect(model.eventType, '-');
      });

      test('should handle null optional dates', () {
        final model = WaNotificationItemModel.fromJson(validJson);

        expect(model.nextAttemptAt, isNull);
        expect(model.processedAt, isNull);
        expect(model.updatedAt, isNull);
      });

      test('should parse non-null processed_at correctly', () {
        final json = Map<String, dynamic>.from(validJson)
          ..['processed_at'] = '2024-09-01T13:00:00.000Z';
        final model = WaNotificationItemModel.fromJson(json);

        expect(model.processedAt, isNotNull);
        expect(model.processedAt!.hour, 13);
      });

      test('should handle null latest_success', () {
        final model = WaNotificationItemModel.fromJson(validJson);
        expect(model.latestSuccess, isNull);
      });

      test('should parse latest_success as bool', () {
        final json = Map<String, dynamic>.from(validJson)
          ..['latest_success'] = true;
        final model = WaNotificationItemModel.fromJson(json);
        expect(model.latestSuccess, isTrue);
      });

      test('should default retryCount to 0 for invalid string', () {
        final json = Map<String, dynamic>.from(validJson)
          ..['retry_count'] = 'invalid';
        final model = WaNotificationItemModel.fromJson(json);
        expect(model.retryCount, 0);
      });
    });

    group('Status helpers', () {
      test('isPending returns true for pending status', () {
        expect(testModel.isPending, isTrue);
        expect(testModel.isSent, isFalse);
        expect(testModel.isFailed, isFalse);
        expect(testModel.isProcessing, isFalse);
      });

      test('isSent returns true for sent status', () {
        final sentModel = testModel.copyWith(status: 'sent');
        expect(sentModel.isSent, isTrue);
        expect(sentModel.isPending, isFalse);
      });

      test('isFailed returns true for failed status', () {
        final failedModel = testModel.copyWith(status: 'failed');
        expect(failedModel.isFailed, isTrue);
        expect(failedModel.isPending, isFalse);
      });

      test('isProcessing returns true for processing status', () {
        final processingModel = testModel.copyWith(status: 'processing');
        expect(processingModel.isProcessing, isTrue);
        expect(processingModel.isPending, isFalse);
      });
    });

    group('copyWith', () {
      test('should copy with updated status', () {
        final updated = testModel.copyWith(status: 'sent');
        expect(updated.status, 'sent');
        expect(updated.id, testModel.id);
        expect(updated.message, testModel.message);
      });

      test('should copy with updated retryCount', () {
        final updated = testModel.copyWith(retryCount: 2);
        expect(updated.retryCount, 2);
        expect(updated.id, testModel.id);
      });

      test('should copy with updated message', () {
        const newMessage = 'Updated message';
        final updated = testModel.copyWith(message: newMessage);
        expect(updated.message, newMessage);
        expect(updated.status, testModel.status);
      });

      test('should return same fields when no changes provided', () {
        final copy = testModel.copyWith();
        expect(copy.id, testModel.id);
        expect(copy.status, testModel.status);
        expect(copy.retryCount, testModel.retryCount);
      });
    });
  });
}
