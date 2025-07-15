import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WifiConnectionState { disconnected, connecting, connected, error }

class WifiService with ChangeNotifier {
  WifiConnectionState _connectionState = WifiConnectionState.disconnected;
  WebSocketChannel? _channel;

  final StreamController<String> _logStreamController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logStreamController.stream;
  WifiConnectionState get connectionState => _connectionState;

  Future<void> connect(String ipAddress) async {
    if (_connectionState == WifiConnectionState.connecting || _connectionState == WifiConnectionState.connected) return;

    _connectionState = WifiConnectionState.connecting;
    notifyListeners();

    // Strip schemes and paths, just extract the clean IP/hostname
    final cleanIP = ipAddress
        .replaceAll(RegExp(r"^(http://|https://|ws://|wss://)"), "")
        .split("/")[0]
        .trim();

    final url = "ws://$cleanIP:80";
    print("Connecting to WebSocket at: $url");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _connectionState = WifiConnectionState.connected;
      notifyListeners();
      print("WebSocket Connected");

      _channel!.stream.listen(
        (message) {
          print("Received: $message");
          _logStreamController.add(message);
        },
        onDone: () {
          print("WebSocket disconnected.");
          disconnect();
        },
        onError: (error) {
          print("WebSocket error: $error");
          _connectionState = WifiConnectionState.error;
          notifyListeners();
        }
      );
    } catch (e) {
      _connectionState = WifiConnectionState.error;
      print("Failed to connect to WebSocket: $e");
    }
    notifyListeners();
  }

  void sendCommand(String json) {
    if (_connectionState == WifiConnectionState.connected && _channel != null) {
      _channel!.sink.add(json);
      print("Sent: $json");
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _connectionState = WifiConnectionState.disconnected;
    notifyListeners();
  }
}
