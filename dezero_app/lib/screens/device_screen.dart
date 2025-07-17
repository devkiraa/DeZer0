import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/wifi_service.dart';

class DeviceScreen extends StatefulWidget {
  final WifiService wifiService;
  const DeviceScreen({super.key, required this.wifiService});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  StreamSubscription? _logSubscription;
  final TextEditingController _ipController = TextEditingController();

  String _firmwareVersion = "-";
  String _buildDate = "-";
  int _ramUsed = 0;
  int _ramTotal = 0;
  int _flashTotal = 0;
  String _macAddress = "-";
  int _cpuFreq = 0;
  bool _isFetchingInfo = false;
  bool _autoConnected = false;

  @override
  void initState() {
    super.initState();
    widget.wifiService.addListener(_onStateChanged);
    _logSubscription = widget.wifiService.logStream.listen(_onDataReceived);

    _ipController.text = "192.168.0.100"; // Set default IP

    // Attempt auto-connect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoConnected && widget.wifiService.connectionState == WifiConnectionState.disconnected) {
        _autoConnected = true;
        widget.wifiService.connect(_ipController.text);
      }
    });

    if (widget.wifiService.connectionState == WifiConnectionState.connected) {
      _fetchDeviceInfoWithDelay();
    }
  }

  @override
  void dispose() {
    widget.wifiService.removeListener(_onStateChanged);
    _logSubscription?.cancel();
    _ipController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
    if (widget.wifiService.connectionState == WifiConnectionState.connected && !_isFetchingInfo) {
      _fetchDeviceInfoWithDelay();
    }
  }

  void _fetchDeviceInfoWithDelay() {
    _isFetchingInfo = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.wifiService.connectionState == WifiConnectionState.connected) {
        widget.wifiService.sendCommand('{"command":"get_device_info"}');
      }
    });
  }

  void _onDataReceived(String data) {
    try {
      final jsonData = jsonDecode(data);
      if (jsonData['type'] == 'device_info') {
        if (mounted) {
          setState(() {
            _firmwareVersion = jsonData['firmware_version'] ?? "-";
            _macAddress = jsonData['mac_address'] ?? "-";
            _cpuFreq = jsonData['cpu_freq'] ?? 0;
            _ramUsed = jsonData['ram_used'] ?? 0;
            _ramTotal = jsonData['ram_total'] ?? 0;
            _isFetchingInfo = false;
          });
        }
      }
    } catch (_) {}
  }

  void _handleConnect() {
    if (_ipController.text.isNotEmpty) {
      FocusScope.of(context).unfocus();
      widget.wifiService.connect(_ipController.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter an IP address.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.wifiService.connectionState;
    return Scaffold(
      appBar: AppBar(title: const Text("Device")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeaderCard(state),
            const SizedBox(height: 24),
            if (state == WifiConnectionState.connected)
              Expanded(child: _buildConnectedView())
            else if (state == WifiConnectionState.connecting)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              _buildConnectionForm(state),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionForm(WifiConnectionState state) {
    return Column(
      children: [
        TextField(
          controller: _ipController,
          decoration: const InputDecoration(
            labelText: "DeZer0 IP Address",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lan),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            icon: const Icon(Icons.wifi_tethering),
            label: const Text("Connect"),
            onPressed: _handleConnect,
          ),
        ),
        if (state == WifiConnectionState.error)
          const Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: Text("Connection Failed.", style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildConnectedView() {
    return Column(
      children: [
        _buildDeviceInfoCard(),
        const Spacer(),
        _buildDisconnectButton(),
      ],
    );
  }

  Widget _buildDisconnectButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.link_off),
        onPressed: widget.wifiService.disconnect,
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        label: const Text("Disconnect"),
      ),
    );
  }

  Widget _buildHeaderCard(WifiConnectionState state) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.memory, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("DeZer0 ESP Device", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  _getTextForState(state),
                  style: TextStyle(color: _getColorForState(state), fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildInfoTile("Firmware Version", _firmwareVersion),
          _buildInfoTile("MAC Address", _macAddress),
          _buildInfoTile("CPU Frequency", "$_cpuFreq MHz"),
          _buildInfoTile("RAM Used/Total", "${(_ramUsed / 1024).toStringAsFixed(0)} KiB / ${(_ramTotal / 1024).toStringAsFixed(0)} KiB"),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      dense: true,
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _getColorForState(WifiConnectionState state) {
    switch (state) {
      case WifiConnectionState.connected:
        return Colors.green;
      case WifiConnectionState.connecting:
        return Colors.orange;
      case WifiConnectionState.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTextForState(WifiConnectionState state) {
    switch (state) {
      case WifiConnectionState.connecting:
        return "Connecting...";
      case WifiConnectionState.connected:
        return "Connected";
      case WifiConnectionState.error:
        return "Error";
      default:
        return "Disconnected";
    }
  }
}
