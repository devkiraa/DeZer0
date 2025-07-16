import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum WifiConnectionState { disconnected, connecting, connected, error }

class WifiService with ChangeNotifier {
  WifiConnectionState _connectionState = WifiConnectionState.disconnected;
  Socket? _socket;
  final StreamController<String> _logStreamController =
      StreamController<String>.broadcast();

  Stream<String> get logStream => _logStreamController.stream;
  WifiConnectionState get connectionState => _connectionState;

  /// Connects via plain TCP to port 80 (TCP‑JSON mode).
  Future<void> connect(String rawInput) async {
    if (_connectionState == WifiConnectionState.connecting ||
        _connectionState == WifiConnectionState.connected) return;

    _connectionState = WifiConnectionState.connecting;
    notifyListeners();

    // Extract just the IPv4 address
    final match = RegExp(r'(\d{1,3}(?:\.\d{1,3}){3})')
        .firstMatch(rawInput.trim());
    if (match == null) {
      _fail('Invalid IP: "$rawInput"');
      return;
    }
    final host = match.group(1)!;
    print('🔗 [WifiService] connecting raw TCP to $host:80');

    try {
      _socket = await Socket.connect(host, 80, timeout: Duration(seconds: 5));
      _connectionState = WifiConnectionState.connected;
      print('✅ [WifiService] TCP connected to $host:80');
      notifyListeners();

      // Listen for newline-terminated JSON from the ESP32
      _socket!.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          print('📥 [WifiService] recv: $line');
          _logStreamController.add(line);
        },
        onError: (err) {
          print('⚠️ [WifiService] error: $err');
          _fail('Receive error');
        },
        onDone: () {
          print('🔌 [WifiService] remote closed');
          disconnect();
        },
      );
    } catch (e) {
      print('❌ [WifiService] connect failed: $e');
      _fail('Connect failed');
    }
  }

  /// Sends a JSON command + newline
  void sendCommand(String json) {
    if (_connectionState == WifiConnectionState.connected && _socket != null) {
      final msg = json.trim() + '\n';
      try {
        _socket!.write(msg);
        print('📤 [WifiService] sent: $msg');
      } catch (e) {
        print('⚠️ [WifiService] send failed: $e');
      }
    } else {
      print('❌ [WifiService] not connected, send blocked');
    }
  }

  /// Close the socket
  void disconnect() {
    print('🛑 [WifiService] manual disconnect');
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    _connectionState = WifiConnectionState.disconnected;
    notifyListeners();
  }

  void _fail(String reason) {
    print('❌ [WifiService] failing: $reason');
    disconnect();
    _connectionState = WifiConnectionState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _logStreamController.close();
    super.dispose();
  }
}
