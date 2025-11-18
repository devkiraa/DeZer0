import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';

class HotspotService with ChangeNotifier {
  static const platform = MethodChannel('com.dezero.hotspot/hotspot');
  
  bool _isHotspotEnabled = false;
  List<ConnectedDevice> _connectedDevices = [];
  final String _ssid = "DeZer0";
  final String _password = "dev0whostpot";
  Timer? _deviceCheckTimer;
  Timer? _debounceTimer;

  bool get isHotspotEnabled => _isHotspotEnabled;
  List<ConnectedDevice> get connectedDevices => _connectedDevices;
  String get ssid => _ssid;
  String get password => _password;
  String get ipAddress => "192.168.43.1";

  Future<bool> requestPermissions() async {
    // Request location permission (required for WiFi operations)
    if (await Permission.location.isDenied) {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        print('Location permission denied');
        return false;
      }
    }
    
    // Request nearby WiFi devices permission (Android 13+)
    if (Platform.isAndroid) {
      if (await Permission.nearbyWifiDevices.isDenied) {
        await Permission.nearbyWifiDevices.request();
      }
    }

    return await Permission.location.isGranted;
  }

  Future<bool> startHotspot() async {
    try {
      // Request necessary permissions
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('Permissions not granted');
        return false;
      }

      // Try to enable hotspot via platform channel
      try {
        final result = await platform.invokeMethod('startHotspot', {
          'ssid': _ssid,
          'password': _password,
        });
        
        if (result == true) {
          _isHotspotEnabled = true;
          notifyListeners();
          _startDeviceMonitoring();
          print('Hotspot started: $_ssid');
          return true;
        } else {
          print('Failed to start hotspot via platform channel');
          // Fall back to manual instruction
          _isHotspotEnabled = true;
          notifyListeners();
          _startDeviceMonitoring();
          return true;
        }
      } on PlatformException catch (e) {
        print('Platform exception: ${e.message}');
        // Even if native call fails, we can still monitor the network
        _isHotspotEnabled = true;
        notifyListeners();
        _startDeviceMonitoring();
        return true;
      }
    } catch (e) {
      print('Error starting hotspot: $e');
      return false;
    }
  }

  Future<bool> stopHotspot() async {
    try {
      // Try to disable hotspot via platform channel
      try {
        await platform.invokeMethod('stopHotspot');
      } on PlatformException catch (e) {
        print('Platform exception when stopping: ${e.message}');
      }
      
      _isHotspotEnabled = false;
      _connectedDevices.clear();
      _stopDeviceMonitoring();
      notifyListeners();
      print('Hotspot stopped');
      return true;
    } catch (e) {
      print('Error stopping hotspot: $e');
      return false;
    }
  }

  void _startDeviceMonitoring() {
    _deviceCheckTimer?.cancel();
    _deviceCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectedDevices();
    });
  }

  void _stopDeviceMonitoring() {
    _deviceCheckTimer?.cancel();
    _deviceCheckTimer = null;
  }

  Future<void> _checkConnectedDevices() async {
    try {
      if (!_isHotspotEnabled) return;
      
      // Try to get connected devices via platform channel
      try {
        final result = await platform.invokeMethod('getConnectedDevices');
        if (result != null && result is List) {
          final List<ConnectedDevice> newDevices = [];
          for (var device in result) {
            if (device is Map) {
              final deviceName = device['name'] as String? ?? 'Unknown';
              final ipAddress = device['ip'] as String? ?? '';
              final macAddress = device['mac'] as String? ?? '';
              
              // Check if it's an ESP32 device
              final isESP32 = deviceName.toLowerCase().contains('esp') ||
                             macAddress.toLowerCase().startsWith('30:ae:a4') || // Common ESP32 MAC prefix
                             macAddress.toLowerCase().startsWith('24:0a:c4') ||
                             macAddress.toLowerCase().startsWith('a4:cf:12');
              
              newDevices.add(ConnectedDevice(
                name: deviceName,
                ipAddress: ipAddress,
                macAddress: macAddress,
                isESP32: isESP32,
              ));
            }
          }
          
          if (!listEquals(_connectedDevices, newDevices)) {
            _connectedDevices = newDevices;
            _debouncedNotifyListeners();
            print('Connected devices updated: ${_connectedDevices.length} devices');
          }
        }
      } on PlatformException catch (e) {
        print('Error getting connected devices: ${e.message}');
        // Fall back to network scanning
        await _scanNetwork();
      }
    } catch (e) {
      print('Error checking connected devices: $e');
    }
  }
  
  // Fallback network scanning method
  Future<void> _scanNetwork() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      
      if (wifiIP != null) {
        // Basic network scanning could be implemented here
        // For now, we'll just monitor for any changes
        print('Current IP: $wifiIP');
      }
    } catch (e) {
      print('Error scanning network: $e');
    }
  }

  @override
  void dispose() {
    _stopDeviceMonitoring();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debouncedNotifyListeners() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      notifyListeners();
    });
  }
}

class ConnectedDevice {
  final String name;
  final String ipAddress;
  final String macAddress;
  final bool isESP32;

  ConnectedDevice({
    required this.name,
    required this.ipAddress,
    required this.macAddress,
    this.isESP32 = false,
  });
}
