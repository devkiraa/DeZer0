import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../ble_service.dart';

class DeviceScreen extends StatefulWidget {
  final BleService bleService;
  const DeviceScreen({super.key, required this.bleService});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  StreamSubscription? _logSubscription;
  String _firmwareVersion = "-";
  String _buildDate = "-";
  int _ramUsed = 0;
  int _ramTotal = 0;
  int _flashTotal = 0;
  bool _isFetchingInfo = false;

  @override
  void initState() {
    super.initState();
    widget.bleService.connectionState.addListener(_onConnectionStateChanged);
    _logSubscription = widget.bleService.logStream.listen(_onDataReceived);

    // Initial check for already connected state
    if (widget.bleService.connectionState.value == BleConnectionState.connected) {
      _fetchDeviceInfoWithDelay();
    }
  }

  @override
  void dispose() {
    widget.bleService.connectionState.removeListener(_onConnectionStateChanged);
    _logSubscription?.cancel();
    super.dispose();
  }

  void _onConnectionStateChanged() {
    if (mounted) {
      setState(() {});
    }
    if (widget.bleService.connectionState.value == BleConnectionState.connected && !_isFetchingInfo) {
      _fetchDeviceInfoWithDelay();
    }
  }

  void _fetchDeviceInfoWithDelay() {
    _isFetchingInfo = true;
    Future.delayed(const Duration(seconds: 1), () {
      print("Requesting device info...");
      widget.bleService.sendCommand('{"command":"get_device_info"}');
    });
  }

  void _onDataReceived(String data) {
    try {
      final jsonData = jsonDecode(data);
      if (jsonData['type'] == 'device_info') {
        if (mounted) {
          setState(() {
            _firmwareVersion = jsonData['firmware_version'] ?? "-";
            _buildDate = jsonData['build_date'] ?? "-";
            _ramUsed = jsonData['ram_used'] ?? 0;
            _ramTotal = jsonData['ram_total'] ?? 0;
            _flashTotal = jsonData['flash_total'] ?? 0;
            _isFetchingInfo = false;
          });
        }
      }
    } catch (e) {
      // Ignore other message types
    }
  }

  // Main widget builder that changes based on state
  Widget _buildContent() {
    final state = widget.bleService.connectionState.value;

    // If connected, show the full info layout
    if (state == BleConnectionState.connected) {
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeaderCard(state),
          const SizedBox(height: 24),
          _buildFirmwareUpdateCard(),
          const SizedBox(height: 24),
          _buildDeviceInfoCard(),
        ],
      );
    }

    // Otherwise, show a simplified view
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildHeaderCard(state),
          const Spacer(),
          if (state == BleConnectionState.disconnected)
            SizedBox(
              width: double.infinity,
              height: 50,
              // The new connect button
              child: FilledButton.icon(
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text("Scan & Connect"),
                onPressed: () => widget.bleService.startScan(),
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Device")),
      body: _buildContent(),
    );
  }

  // --- Helper Widgets for Cleaner Code ---

  Widget _buildHeaderCard(BleConnectionState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.memory, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("DeZer0", style: Theme.of(context).textTheme.titleLarge),
                Text(
                  _getTextForState(state),
                  style: TextStyle(color: _getColorForState(state)),
                ),
              ],
            ),
            const Spacer(),
            if (state == BleConnectionState.scanning || state == BleConnectionState.connecting)
              const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 3)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFirmwareUpdateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Firmware Update", style: Theme.of(context).textTheme.titleMedium),
                Text("Release $_firmwareVersion", style: const TextStyle(color: Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (widget.bleService.connectionState.value == BleConnectionState.connected) ? () {} : null,
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("UPDATE"),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeviceInfoCard() {
    return Card(
      child: Column(
        children: [
          _buildInfoTile("Firmware Version", _firmwareVersion),
          _buildInfoTile("Build Date", _buildDate),
          _buildInfoTile("Int. Flash Total", "${(_flashTotal / 1024 / 1024).toStringAsFixed(0)} MB"),
          _buildInfoTile("RAM (Used/Total)", "${(_ramUsed / 1024).toStringAsFixed(0)} KiB / ${(_ramTotal / 1024).toStringAsFixed(0)} KiB"),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      dense: true,
      title: Text(title),
      trailing: Text(value, style: TextStyle(color: Colors.grey[600])),
    );
  }
  
  Color _getColorForState(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.connected: return Colors.green;
      case BleConnectionState.scanning:
      case BleConnectionState.connecting: return Colors.orange;
      default: return Colors.red;
    }
  }

  String _getTextForState(BleConnectionState state) {
    switch (state) {
      case BleConnectionState.scanning: return "Searching...";
      case BleConnectionState.connecting: return "Connecting...";
      case BleConnectionState.connected: return "Connected";
      default: return "Disconnected";
    }
  }
}