class DeliveryRecord {
  const DeliveryRecord({
    required this.id,
    required this.conversationId,
    required this.channelId,
    required this.status,
    this.messageId = '',
    this.createdAt = '',
  });

  final String id;
  final String conversationId;
  final String messageId;
  final String channelId;
  final String status;
  final String createdAt;

  String get statusLabel => switch (status) {
    'delivered' => '已送达',
    'failed' => '失败',
    'queued' => '排队中',
    _ => status.isEmpty ? '未知' : status,
  };
}
