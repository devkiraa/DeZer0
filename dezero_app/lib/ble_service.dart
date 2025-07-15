import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Same UUIDs from before
final Guid dezeroServiceUUID = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
final Guid dezeroCommandUUID = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");
final Guid dezeroLogUUID = Guid("beb5483f-36e1-4688-b7f5-ea07361b26a8");

enum BleConnectionState { disconnected, scanning, connecting, connected }

class BleService {
  final ValueNotifier<BleConnectionState> connectionState = ValueNotifier(BleConnectionState.disconnected);
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _logCharacteristic;
  
  final StreamController<String> _logStreamController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logStreamController.stream;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _logValueSubscription;

  void startScan() {
    connectionState.value = BleConnectionState.scanning;
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (connectionState.value == BleConnectionState.scanning) {
        try {
          final result = results.firstWhere((r) => r.device.platformName == "DeZer0");
          FlutterBluePlus.stopScan();
          _connectToDevice(result.device);
        } catch (e) {
          // Device not found yet
        }
      }
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    connectionState.value = BleConnectionState.connecting;
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      targetDevice = device;
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid == dezeroServiceUUID) {
          for (var char in service.characteristics) {
            if (char.uuid == dezeroCommandUUID) _commandCharacteristic = char;
            if (char.uuid == dezeroLogUUID) _logCharacteristic = char;
          }
        }
      }
      
      if (_logCharacteristic != null) {
        await _logCharacteristic!.setNotifyValue(true);
        _logValueSubscription = _logCharacteristic!.onValueReceived.listen((value) {
          _logStreamController.add(utf8.decode(value));
        });
      }

      connectionState.value = BleConnectionState.connected;
    } catch (e) {
      print("Failed to connect: $e");
      disconnect();
    }
  }

  Future<void> sendCommand(String json) async {
    if (_commandCharacteristic == null) return;
    await _commandCharacteristic!.write(utf8.encode(json));
  }

  Future<void> disconnect() async {
    _scanSubscription?.cancel();
    _logValueSubscription?.cancel();
    await targetDevice?.disconnect();
    targetDevice = null;
    _commandCharacteristic = null;
    _logCharacteristic = null;
    connectionState.value = BleConnectionState.disconnected;
  }
}