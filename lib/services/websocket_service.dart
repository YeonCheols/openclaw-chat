import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  pending, // 페어링 승인 대기 중
  connected,
  error,
}

class WebSocketService extends ChangeNotifier {
  static const _defaultHost = '192.168.0.x';
  static const _defaultPort = 18789;
  static const _reconnectDelay = Duration(seconds: 4);
  static const _pendingRetryDelay = Duration(seconds: 8);
  static const _maxReconnectAttempts = 5;

  static const _prefKeyHost = 'ws_host';
  static const _prefKeyPort = 'ws_port';
  static const _prefKeyPrivateKeySeed = 'device_private_key_seed';
  static const _prefKeyPublicKey = 'device_public_key';
  static const _prefKeyDeviceToken = 'device_token';

  static const _clientMode = 'webchat';
  static const _role = 'operator';
  static const _scopes = ['operator.read', 'operator.write'];
  static const _clientVersion = '1.0.0';

  WebSocketChannel? _channel;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _host = _defaultHost;
  int _port = _defaultPort;

  SimpleKeyPair? _keyPair;
  String? _deviceId;
  String? _deviceToken;

  int _requestId = 0;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};

  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _manualDisconnect = false;

  final _chatController = StreamController<Map<String, dynamic>>.broadcast();
  final _stubNewsController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;
  Stream<Map<String, dynamic>> get newsStream => _stubNewsController.stream;

  ConnectionStatus get status => _status;
  String get host => _host;
  int get port => _port;
  String get serverUrl => 'ws://$_host:$_port';

  Future<void> loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString(_prefKeyHost) ?? _defaultHost;
    _port = prefs.getInt(_prefKeyPort) ?? _defaultPort;
    _deviceToken = prefs.getString(_prefKeyDeviceToken);
    await _loadOrCreateKeyPair(prefs);
    notifyListeners();
  }

  Future<void> _loadOrCreateKeyPair(SharedPreferences prefs) async {
    final ed25519 = Ed25519();
    final seedB64 = prefs.getString(_prefKeyPrivateKeySeed);

    if (seedB64 != null) {
      try {
        final seed = base64Decode(seedB64);
        _keyPair = await ed25519.newKeyPairFromSeed(seed);
        final pub = await _keyPair!.extractPublicKey();
        _deviceId = _deriveDeviceId(pub.bytes);
        return;
      } catch (_) {}
    }

    _keyPair = await ed25519.newKeyPair();
    final pub = await _keyPair!.extractPublicKey();
    final seed = await _keyPair!.extractPrivateKeyBytes();

    await prefs.setString(_prefKeyPrivateKeySeed, base64Encode(seed));
    await prefs.setString(_prefKeyPublicKey, base64Encode(pub.bytes));
    _deviceId = _deriveDeviceId(pub.bytes);
  }

  String _deriveDeviceId(List<int> pubKeyBytes) {
    final hash = sha256.convert(pubKeyBytes);
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _base64Url(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _getClientId() {
    if (Platform.isIOS) return 'openclaw-ios';
    if (Platform.isAndroid) return 'openclaw-android';
    if (Platform.isMacOS) return 'openclaw-macos';
    return 'openclaw-flutter';
  }

  String _getPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    return 'flutter';
  }

  String _getDeviceFamily() {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) return 'desktop';
    return 'phone';
  }

  Future<void> configure(String host, int port) async {
    _host = host;
    _port = port;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyHost, host);
    await prefs.setInt(_prefKeyPort, port);
    notifyListeners();
  }

  Future<void> connect() async {
    if (_status == ConnectionStatus.connecting || _status == ConnectionStatus.connected) return;
    _manualDisconnect = false;
    _setStatus(ConnectionStatus.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      await _channel!.ready;
      _channel!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);
    } catch (e) {
      debugPrint('[WS] Connect error: $e');
      _setStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  Future<void> _sendConnectRequest(String nonce) async {
    if (_keyPair == null || _deviceId == null) return;

    final ed25519 = Ed25519();
    final clientId = _getClientId();
    final platform = _getPlatform();
    final deviceFamily = _getDeviceFamily();
    final signedAt = DateTime.now().millisecondsSinceEpoch;
    final tokenStr = _deviceToken ?? '';

    final payloadStr = [
      'v3',
      _deviceId!,
      clientId,
      _clientMode,
      _role,
      _scopes.join(','),
      signedAt.toString(),
      tokenStr,
      nonce,
      platform,
      deviceFamily,
    ].join('|');

    final sig = await ed25519.sign(utf8.encode(payloadStr), keyPair: _keyPair!);
    final pub = await _keyPair!.extractPublicKey();

    final id = 'connect-${++_requestId}';
    _channel?.sink.add(jsonEncode({
      'type': 'req',
      'id': id,
      'method': 'connect',
      'params': {
        'minProtocol': 1,
        'maxProtocol': 1,
        'client': {
          'id': clientId,
          'version': _clientVersion,
          'platform': platform,
          'deviceFamily': deviceFamily,
          'mode': _clientMode,
        },
        'role': _role,
        'scopes': _scopes,
        'device': {
          'id': _deviceId!,
          'publicKey': _base64Url(pub.bytes),
          'signature': _base64Url(sig.bytes),
          'signedAt': signedAt,
          'nonce': nonce,
        },
        if (_deviceToken != null) 'auth': {'deviceToken': _deviceToken},
      },
    }));
  }

  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    for (final c in _pendingRequests.values) {
      c.completeError('disconnected');
    }
    _pendingRequests.clear();
    _channel?.sink.close();
    _channel = null;
    _setStatus(ConnectionStatus.disconnected);
  }

  Future<void> sendChatMessage(String text, {String sessionKey = 'main'}) async {
    await _request('chat.send', {
      'sessionKey': sessionKey,
      'message': text,
      'idempotencyKey': DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  // stub - news not supported by OpenClaw server
  void requestNews({String? category}) {}

  Future<Map<String, dynamic>?> _request(
    String method,
    Map<String, dynamic> params,
  ) async {
    if (_status != ConnectionStatus.connected) return null;

    final id = 'req-${++_requestId}';
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;

    _channel?.sink.add(jsonEncode({
      'type': 'req',
      'id': id,
      'method': method,
      'params': params,
    }));

    try {
      return await completer.future.timeout(const Duration(seconds: 30));
    } catch (_) {
      _pendingRequests.remove(id);
      return null;
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = json['type'] as String?;
      if (type == 'event') {
        _handleEvent(json);
      } else if (type == 'res') {
        _handleResponse(json);
      }
    } catch (e) {
      debugPrint('[WS] Parse error: $e');
    }
  }

  void _handleEvent(Map<String, dynamic> json) {
    final event = json['event'] as String?;
    final payload = json['payload'] as Map<String, dynamic>?;

    switch (event) {
      case 'connect.challenge':
        final nonce = payload?['nonce'] as String?;
        if (nonce != null) _sendConnectRequest(nonce);

      case 'device.pair.resolved':
        final decision = payload?['decision'] as String?;
        if (decision == 'approved') {
          _reconnectTimer?.cancel();
          _reconnectAttempts = 0;
          _channel?.sink.close();
          _channel = null;
          Future.delayed(const Duration(milliseconds: 500), connect);
        } else if (decision == 'rejected') {
          disconnect();
        }

      case 'chat':
        _chatController.add(json);
    }
  }

  void _handleResponse(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final ok = json['ok'] as bool?;

    if (id != null && _pendingRequests.containsKey(id)) {
      _pendingRequests.remove(id)?.complete(json);
    }

    if (id?.startsWith('connect-') == true) {
      if (ok == true) {
        final payload = json['payload'] as Map<String, dynamic>?;
        final auth = payload?['auth'] as Map<String, dynamic>?;
        final newToken = auth?['deviceToken'] as String?;
        if (newToken != null) {
          _deviceToken = newToken;
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString(_prefKeyDeviceToken, newToken);
          });
        }
        _reconnectAttempts = 0;
        _setStatus(ConnectionStatus.connected);
      } else {
        final error = json['error'] as Map<String, dynamic>?;
        final code = error?['code'] as String?;
        final details = error?['details'] as Map<String, dynamic>?;
        final reason = details?['reason'] as String?;

        if (code == 'NOT_PAIRED' || reason == 'not-paired') {
          _setStatus(ConnectionStatus.pending);
          // 승인될 때까지 주기적으로 재시도
          _reconnectTimer?.cancel();
          _reconnectTimer = Timer(_pendingRetryDelay, () {
            _channel?.sink.close();
            _channel = null;
            if (!_manualDisconnect) connect();
          });
        } else {
          debugPrint('[WS] Auth error: $code - ${error?['message']}');
          _setStatus(ConnectionStatus.error);
          _scheduleReconnect();
        }
      }
    }
  }

  void _onError(Object error) {
    debugPrint('[WS] Error: $error');
    _setStatus(ConnectionStatus.error);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[WS] Connection closed');
    if (_status == ConnectionStatus.pending) return;
    if (_status != ConnectionStatus.disconnected) _setStatus(ConnectionStatus.disconnected);
    if (!_manualDisconnect) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    debugPrint('[WS] Reconnect attempt $_reconnectAttempts in ${_reconnectDelay.inSeconds}s');
    _reconnectTimer = Timer(_reconnectDelay, connect);
  }

  void _setStatus(ConnectionStatus s) {
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _chatController.close();
    _stubNewsController.close();
    super.dispose();
  }
}
