/// OpenClaw Gateway 표준 JSON 메시지 스펙
class OpenClawMessage {
  final String type;
  final String? deviceId;
  final String? deviceName;
  final dynamic data;
  final String? message;
  final String? category;

  const OpenClawMessage({
    required this.type,
    this.deviceId,
    this.deviceName,
    this.data,
    this.message,
    this.category,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    if (deviceId != null) 'device_id': deviceId,
    if (deviceName != null) 'device_name': deviceName,
    if (data != null) 'data': data,
    if (message != null) 'message': message,
    if (category != null) 'category': category,
  };

  factory OpenClawMessage.fromJson(Map<String, dynamic> json) {
    return OpenClawMessage(
      type: json['type'] as String? ?? '',
      deviceId: json['device_id'] as String?,
      deviceName: json['device_name'] as String?,
      data: json['data'],
      message: json['message'] as String?,
      category: json['category'] as String?,
    );
  }

  // --- 클라이언트→서버 메시지 팩토리 ---

  factory OpenClawMessage.pairingRequest({
    required String deviceId,
    required String deviceName,
  }) => OpenClawMessage(type: 'pairing_request', deviceId: deviceId, deviceName: deviceName);

  factory OpenClawMessage.chatMessage(String text) =>
      OpenClawMessage(type: 'chat', message: text);

  factory OpenClawMessage.newsRequest({String? category}) =>
      OpenClawMessage(type: 'news_request', category: category);
}

/// 서버→클라이언트 메시지 타입 상수
class OpenClawType {
  static const pairingApproved = 'pairing_approved';
  static const pairingPending  = 'pairing_pending';
  static const pairingRejected = 'pairing_rejected';
  static const news            = 'news';
  static const newsUpdate      = 'news_update';
  static const chat            = 'chat';
  static const assistant       = 'assistant';
  static const message         = 'message';
}
