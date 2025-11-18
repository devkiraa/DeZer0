import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WifiConnectionState { disconnected, connecting, connected, error }

class WifiService with ChangeNotifier {
  WifiConnectionState _connectionState = WifiConnectionState.disconnected;
  Socket? _socket;
  
  final StreamController<String> _logStreamController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logStreamController.stream;
  WifiConnectionState get connectionState => _connectionState;

  Future<void> connect(String ipAddress) async {
    if (_connectionState != WifiConnectionState.disconnected && _connectionState != WifiConnectionState.error) return;
    
    _connectionState = WifiConnectionState.connecting;
    notifyListeners();
    print('Connecting TCP to $ipAddress:8888');

    try {
      _socket = await Socket.connect(ipAddress, 8888, timeout: const Duration(seconds: 5));
      _connectionState = WifiConnectionState.connected;
      print('TCP Connected!');
      
      // Save last connected IP
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_connected_ip', ipAddress);
      
      notifyListeners();

      _socket!.cast<List<int>>()
  .transform(utf8.decoder)
  .transform(const LineSplitter())
  .listen(
    (line) {
      _logStreamController.add(line);
    },
    onDone: () => disconnect(),
    onError: (err) => disconnect(),
    cancelOnError: true,
  );
    } catch (e) {
      print('Connect failed: $e');
      _fail();
    }
  }

  void sendCommand(String json) {
  if (_connectionState == WifiConnectionState.connected && _socket != null) {
    final msg = json.trim() + '\n';
    try {
      _socket!.write(msg);
      print('Sent: $msg');
    } catch (e) {
      disconnect();
    }
  }
}

  void disconnect() {
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    if (_connectionState != WifiConnectionState.disconnected) {
      _connectionState = WifiConnectionState.disconnected;
      notifyListeners();
    }
  }

  void _fail() {
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