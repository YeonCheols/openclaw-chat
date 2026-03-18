import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/websocket_service.dart';

class ChatProvider extends ChangeNotifier {
  final WebSocketService _wsService;
  StreamSubscription<Map<String, dynamic>>? _sub;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isWaiting = false;
  bool get isWaiting => _isWaiting;

  ChatProvider(this._wsService) {
    _sub = _wsService.chatStream.listen(_onChatEvent);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      type: MessageType.user,
      createdAt: DateTime.now(),
    ));
    _isWaiting = true;
    notifyListeners();

    _wsService.sendChatMessage(text.trim());
  }

  // OpenClaw chat event format:
  // { "type": "event", "event": "chat", "payload": {
  //     "runId": "...", "state": "delta|final|aborted|error",
  //     "message": { "content": [{"type": "text", "text": "..."}] },
  //     "errorMessage": "..."
  // }}
  void _onChatEvent(Map<String, dynamic> data) {
    final payload = data['payload'] as Map<String, dynamic>?;
    if (payload == null) return;

    final state = payload['state'] as String?;
    final runId = payload['runId'] as String?;
    if (runId == null) return;

    final message = payload['message'] as Map<String, dynamic>?;
    final errorMessage = payload['errorMessage'] as String?;
    final content = _extractText(message);

    switch (state) {
      case 'delta':
        if (content != null && content.isNotEmpty) {
          _upsertMessage(runId, content, loading: true);
        }
      case 'final':
        _isWaiting = false;
        if (content != null && content.isNotEmpty) {
          _upsertMessage(runId, content, loading: false);
        } else {
          _removeMessage(runId);
        }
      case 'error':
        _isWaiting = false;
        _upsertMessage(runId, errorMessage ?? '오류가 발생했습니다.', loading: false);
      case 'aborted':
        _isWaiting = false;
        if (content != null && content.isNotEmpty) {
          _upsertMessage(runId, content, loading: false);
        } else {
          _removeMessage(runId);
        }
    }
    notifyListeners();
  }

  String? _extractText(Map<String, dynamic>? message) {
    if (message == null) return null;
    final content = message['content'];
    if (content is List && content.isNotEmpty) {
      final first = content.first;
      if (first is Map) return first['text'] as String?;
    }
    return null;
  }

  void _upsertMessage(String runId, String content, {required bool loading}) {
    final idx = _messages.indexWhere((m) => m.id == runId);
    final msg = ChatMessage(
      id: runId,
      content: content,
      type: MessageType.bot,
      createdAt: DateTime.now(),
      isLoading: loading,
    );
    if (idx >= 0) {
      _messages[idx] = msg;
    } else {
      _messages.add(msg);
    }
  }

  void _removeMessage(String runId) {
    _messages.removeWhere((m) => m.id == runId);
  }

  void clear() {
    _messages.clear();
    _isWaiting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
