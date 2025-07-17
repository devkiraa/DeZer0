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
  StreamSubscription<String>? _logSubscription;
  final TextEditingController _ipController = TextEditingController(text: '192.168.0.100');

  String _firmwareVersion = "-";
  String _buildDate = "-";
  int _ramUsed = 0;
  int _ramTotal = 0;
  int _flashTotal = 0;
  String _macAddress = "-";
  int _cpuFreq = 0;
  bool _isFetchingInfo = false;

  @override
  void initState() {
    super.initState();
    widget.wifiService.addListener(_onStateChanged);
    _logSubscription = widget.wifiService.logStream.listen(_onDataReceived);

    // Auto-connect using default IP if desired:
    if (_ipController.text.isNotEmpty) {
      widget.wifiService.connect(_ipController.text);
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
    if (!mounted) return;
    setState(() {});
    if (widget.wifiService.connectionState == WifiConnectionState.connected &&
        !_isFetchingInfo) {
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
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      if (jsonData['type'] == 'device_info') {
        if (!mounted) return;
        setState(() {
          _firmwareVersion = jsonData['firmware_version'] ?? "-";
          _buildDate = jsonData['build_date'] ?? "-";
          _ramUsed = jsonData['ram_used'] ?? 0;
          _ramTotal = jsonData['ram_total'] ?? 0;
          _flashTotal = jsonData['flash_total'] ?? 0;
          _macAddress = jsonData['mac_address'] ?? "-";
          _cpuFreq = jsonData['cpu_freq'] ?? 0;
          _isFetchingInfo = false;
        });
      }
    } catch (_) {
      // ignore malformed messages
    }
  }

  void _handleConnect() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an IP address.")),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    widget.wifiService.connect(ip);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.wifiService.connectionState;
    return Scaffold(
      appBar: AppBar(title: const Text("Device")),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeaderCard(state),
            const SizedBox(height: 24),
            if (state == WifiConnectionState.connected)
              Expanded(child: _buildConnectedView())
            else if (state == WifiConnectionState.connecting)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
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
        const SizedBox(height: 24),
        TextField(
          controller: _ipController,
          decoration: const InputDecoration(
            labelText: "DeZer0 IP Address",
            hintText: "e.g., 192.168.1.105",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
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
        if (state == WifiConnectionState.error) ...[
          const SizedBox(height: 20),
          const Text(
            "Connection Failed. Please check the IP address.",
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildConnectedView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFirmwareUpdateCard(),
          const SizedBox(height: 24),
          _buildDeviceInfoCard(),
          const SizedBox(height: 24),
          _buildDisconnectButton(),
        ],
      ),
    );
  }

  Widget _buildDisconnectButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: widget.wifiService.disconnect,
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        child: const Text("Disconnect"),
      ),
    );
  }

  Widget _buildHeaderCard(WifiConnectionState state) {
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
                Text("Release $_firmwareVersion",
                    style: const TextStyle(color: Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.wifiService.connectionState ==
                        WifiConnectionState.connected
                    ? () {
                        // implement update logic
                      }
                    : null,
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
          _buildInfoTile("MAC Address", _macAddress),
          _buildInfoTile("CPU Frequency", "$_cpuFreq MHz"),
          _buildInfoTile(
              "Flash Total", "${(_flashTotal / (1024 * 1024)).toStringAsFixed(0)} MB"),
          _buildInfoTile("RAM Used/Total",
              "${(_ramUsed / 1024).toStringAsFixed(0)} KiB / ${(_ramTotal / 1024).toStringAsFixed(0)} KiB"),
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
        return "Connecting…";
      case WifiConnectionState.connected:
        return "Connected";
      case WifiConnectionState.error:
        return "Error";
      default:
        return "Disconnected";
    }
  }
}
