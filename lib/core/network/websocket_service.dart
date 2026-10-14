import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';

/// A shared WebSocket connection with an in-memory activity history.
class WebSocketService {
  IOWebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Future<bool>? _connecting;
  bool _connected = false;
  bool _disposed = false;

  final _events = StreamController<String>.broadcast();
  final _connectionChanges = StreamController<bool>.broadcast();
  final List<String> _history = [];

  Stream<String> get events => _events.stream;
  Stream<bool> get connectionChanges => _connectionChanges.stream;
  List<String> get history => List.unmodifiable(_history);
  bool get isConnected => _connected;

  Future<bool> connect(String url) {
    if (_disposed) return Future.value(false);
    if (_connected) return Future.value(true);
    return _connecting ??= _open(url).whenComplete(() => _connecting = null);
  }

  Future<bool> _open(String url) async {
    IOWebSocketChannel? channel;
    try {
      debugPrint('WebSocket connecting: $url');
      channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        connectTimeout: const Duration(seconds: 6),
        pingInterval: const Duration(seconds: 20),
      );
      await channel.ready;
      if (_disposed) {
        await channel.sink.close();
        return false;
      }
      _channel = channel;
      _setConnected(true);
      _addHistory('WebSocket connected');
      _subscription = channel.stream.listen(
        (message) => _addHistory(message.toString()),
        onError: (Object error) {
          debugPrint('WebSocket stream error: $error');
          _setConnected(false);
          _addHistory('WebSocket connection error');
        },
        onDone: () {
          _setConnected(false);
          _addHistory('WebSocket disconnected');
        },
        cancelOnError: true,
      );
      return true;
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _setConnected(false);
      if (channel != null) {
        try { await channel.sink.close(); } catch (_) {}
      }
      return false;
    }
  }

  void _setConnected(bool value) {
    _connected = value;
    if (!_connectionChanges.isClosed) _connectionChanges.add(value);
  }

  void _addHistory(String message) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final entry = '$hh:$mm:$ss  $message';
    _history.insert(0, entry);
    if (_history.length > 50) _history.removeLast();
    if (!_events.isClosed) _events.add(entry);
  }

  /// Sends only when the socket is connected. No fabricated activity events.
  bool send(String message) {
    if (!_connected || _channel == null) return false;
    _channel!.sink.add(message);
    return true;
  }

  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    await _channel?.sink.close();
    await _events.close();
    await _connectionChanges.close();
  }
}
