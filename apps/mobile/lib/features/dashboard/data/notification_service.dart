import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/constants/api_constants.dart';

typedef NotificationCallback = void Function();

class NotificationService {
  NotificationService({
    required this.token,
    required this.onNotification,
    required this.onMarkAllRead,
  });

  final String token;
  final NotificationCallback onNotification;
  final NotificationCallback onMarkAllRead;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _disposed = false;

  Future<void> connect() async {
    if (_disposed || _isConnecting || _socket != null) {
      return;
    }

    _isConnecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      final uri = Uri.parse(
        ApiConstants.wsUrl,
      ).replace(queryParameters: {'token': token});

      final socket = await WebSocket.connect(uri.toString());
      _socket = socket;
      _replaceSubscription(
        socket.listen(
          _handleMessage,
          onDone: _handleDisconnect,
          onError: (_) => _handleDisconnect(),
          cancelOnError: true,
        ),
      );
      _startPing();
    } catch (_) {
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  void markAllRead() {
    onMarkAllRead();
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;

    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      await subscription.cancel();
    }

    final socket = _socket;
    _socket = null;
    await socket?.close();
  }

  void _handleMessage(dynamic payload) {
    final data = _decodePayload(payload);
    final type = data?['type'];

    if (type is! String || type == 'connected' || type == 'pong') {
      return;
    }

    onNotification();
  }

  void _handleDisconnect() {
    _pingTimer?.cancel();
    _pingTimer = null;

    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }

    _socket = null;

    if (!_disposed) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectTimer != null) {
      return;
    }

    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _reconnectTimer = null;
      if (!_disposed) {
        unawaited(connect());
      }
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      try {
        _socket?.add('ping');
      } catch (_) {
        _handleDisconnect();
      }
    });
  }

  void _replaceSubscription(StreamSubscription<dynamic> subscription) {
    final previous = _subscription;
    _subscription = subscription;
    if (previous != null) {
      unawaited(previous.cancel());
    }
  }

  Map<String, dynamic>? _decodePayload(dynamic payload) {
    if (payload is String) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        return null;
      }
    }

    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}