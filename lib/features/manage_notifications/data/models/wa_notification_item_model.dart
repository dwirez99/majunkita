class WaNotificationItemModel {
  final int id;
  final String eventType;
  final String sourceTable;
  final String sourceId;
  final String recipientRole;
  final String recipientPhone;
  final String message;
  final String? imageUrl;
  final String status;
  final int retryCount;
  final int maxRetries;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? processedAt;

  final int? latestResponseStatus;
  final String? latestResponseBody;
  final bool? latestSuccess;
  final String? latestLogErrorMessage;
  final DateTime? latestLogCreatedAt;

  WaNotificationItemModel({
    required this.id,
    required this.eventType,
    required this.sourceTable,
    required this.sourceId,
    required this.recipientRole,
    required this.recipientPhone,
    required this.message,
    required this.status,
    required this.retryCount,
    required this.maxRetries,
    required this.createdAt,
    this.imageUrl,
    this.nextAttemptAt,
    this.lastError,
    this.updatedAt,
    this.processedAt,
    this.latestResponseStatus,
    this.latestResponseBody,
    this.latestSuccess,
    this.latestLogErrorMessage,
    this.latestLogCreatedAt,
  });

  factory WaNotificationItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic raw) {
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    }

    return WaNotificationItemModel(
      id: json['id'] as int? ?? 0,
      eventType: json['event_type']?.toString() ?? '-',
      sourceTable: json['source_table']?.toString() ?? '-',
      sourceId: json['source_id']?.toString() ?? '-',
      recipientRole: json['recipient_role']?.toString() ?? '-',
      recipientPhone: json['recipient_phone']?.toString() ?? '-',
      message: json['message']?.toString() ?? '-',
      imageUrl: json['image_url']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      retryCount: int.tryParse(json['retry_count']?.toString() ?? '0') ?? 0,
      maxRetries: int.tryParse(json['max_retries']?.toString() ?? '0') ?? 0,
      nextAttemptAt: _dt(json['next_attempt_at']),
      lastError: json['last_error']?.toString(),
      createdAt: _dt(json['created_at']) ?? DateTime.now(),
      updatedAt: _dt(json['updated_at']),
      processedAt: _dt(json['processed_at']),
      latestResponseStatus:
      int.tryParse(
      (json['latest_response_status'] ?? json['last_log_response_status'])
          ?.toString() ??
        '',
      ),
    latestResponseBody:
      (json['latest_response_body'] ?? json['last_log_response_body'])
        ?.toString(),
      latestSuccess:
      (json['latest_success'] ?? json['last_log_success']) == null
              ? null
        : (json['latest_success'] ?? json['last_log_success']) as bool,
    latestLogErrorMessage:
      (json['latest_log_error_message'] ?? json['last_log_error_message'])
        ?.toString(),
    latestLogCreatedAt:
      _dt(json['latest_log_created_at'] ?? json['last_log_created_at']),
    );
  }

  bool get isFailed => status == 'failed';
  bool get isSent => status == 'sent';
  bool get isProcessing => status == 'processing';
  bool get isPending => status == 'pending';

  WaNotificationItemModel copyWith({
    String? message,
    String? status,
    int? retryCount,
    String? lastError,
    DateTime? nextAttemptAt,
    DateTime? processedAt,
  }) {
    return WaNotificationItemModel(
      id: id,
      eventType: eventType,
      sourceTable: sourceTable,
      sourceId: sourceId,
      recipientRole: recipientRole,
      recipientPhone: recipientPhone,
      message: message ?? this.message,
      imageUrl: imageUrl,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt,
      updatedAt: updatedAt,
      processedAt: processedAt ?? this.processedAt,
      latestResponseStatus: latestResponseStatus,
      latestResponseBody: latestResponseBody,
      latestSuccess: latestSuccess,
      latestLogErrorMessage: latestLogErrorMessage,
      latestLogCreatedAt: latestLogCreatedAt,
    );
  }
}
