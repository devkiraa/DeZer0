import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wifi_service.dart';
import '../services/hotspot_service.dart';
import '../theme/flipper_theme.dart';
import 'connection_presets_screen.dart';
import 'activity_history_screen.dart';

class DeviceScreen extends StatefulWidget {
  final WifiService wifiService;
  final HotspotService hotspotService;
  final VoidCallback onMenuPressed;
  
  const DeviceScreen({
    super.key, 
    required this.wifiService,
    required this.hotspotService,
    required this.onMenuPressed,
  });

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  StreamSubscription? _logSubscription;
  final TextEditingController _ipController = TextEditingController();

  String _firmwareVersion = "-";
  int _ramUsed = 0;
  int _ramTotal = 0;
  String _macAddress = "-";
  int _cpuFreq = 0;
  bool _isFetchingInfo = false;
  
  // Hotspot settings
  bool _isHostMode = false;

  @override
  void initState() {
    super.initState();
    widget.wifiService.addListener(_onStateChanged);
    widget.hotspotService.addListener(_onHotspotChanged);
    _logSubscription = widget.wifiService.logStream.listen(_onDataReceived);

    if (widget.wifiService.connectionState == WifiConnectionState.connected) {
      _fetchDeviceInfoWithDelay();
    }
  }

  @override
  void dispose() {
    widget.wifiService.removeListener(_onStateChanged);
    widget.hotspotService.removeListener(_onHotspotChanged);
    _logSubscription?.cancel();
    _ipController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final currentState = widget.wifiService.connectionState;
    
    // Log connection state changes
    if (currentState == WifiConnectionState.connected) {
      ActivityHistoryService.addLog(
        type: 'connection',
        title: 'Connected to ESP32',
        description: 'IP: ${_ipController.text}',
        isSuccess: true,
      );
      if (mounted && !_isFetchingInfo) {
        _fetchDeviceInfoWithDelay();
      }
    } else if (currentState == WifiConnectionState.error) {
      ActivityHistoryService.addLog(
        type: 'error',
        title: 'Connection Failed',
        description: 'Failed to connect to ${_ipController.text}',
        isSuccess: false,
      );
    } else if (currentState == WifiConnectionState.disconnected) {
      ActivityHistoryService.addLog(
        type: 'connection',
        title: 'Disconnected from ESP32',
        description: 'Session ended',
        isSuccess: true,
      );
    }
    
    if (mounted) setState(() {});
  }

  void _onHotspotChanged() {
    if (mounted) setState(() {});
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
            _ramUsed = jsonData['ram_used'] ?? 0;
            _ramTotal = jsonData['ram_total'] ?? 0;
            _macAddress = jsonData['mac_address'] ?? "-";
            _cpuFreq = jsonData['cpu_freq'] ?? 0;
            _isFetchingInfo = false;
          });
        }
      }
    } catch (e) { /* Ignore other messages */ }
  }

  void _handleConnect() {
    if (_ipController.text.isNotEmpty) {
      FocusScope.of(context).unfocus();
      final ip = _ipController.text;
      widget.wifiService.connect(ip);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter an IP address.")));
    }
  }

  void _toggleHostMode() {
    setState(() {
      _isHostMode = !_isHostMode;
      // Auto-disable hotspot when switching to client mode
      if (!_isHostMode && widget.hotspotService.isHotspotEnabled) {
        _toggleHotspot();
      }
    });
  }

  Future<void> _toggleHotspot() async {
    if (widget.hotspotService.isHotspotEnabled) {
      // Turn off hotspot
      final success = await widget.hotspotService.stopHotspot();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hotspot disabled',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: FlipperColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Turn on hotspot
      final success = await widget.hotspotService.startHotspot();
      if (mounted) {
        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hotspot Setup Required',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please enable hotspot manually with:\nSSID: ${widget.hotspotService.ssid}\nPassword: ${widget.hotspotService.password}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              backgroundColor: FlipperColors.primary,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'SETTINGS',
                textColor: FlipperColors.textPrimary,
                onPressed: () {
                  // User can open settings manually
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to enable hotspot. Check permissions.',
                style: TextStyle(fontFamily: 'monospace'),
              ),
              backgroundColor: FlipperColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label copied to clipboard',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: FlipperColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.wifiService.connectionState;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuPressed,
        ),
        title: const Text("DEVICE"),
        actions: [
          // Mode toggle button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _toggleHostMode,
              icon: Icon(
                _isHostMode ? Icons.router : Icons.devices,
                color: FlipperColors.primary,
              ),
              tooltip: _isHostMode ? 'Switch to Client Mode' : 'Switch to Host Mode',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildModeSelector(),
            const SizedBox(height: 16),
            _buildHeaderCard(state),
            const SizedBox(height: 16),
            if (_isHostMode)
              _buildHostModeView()
            else if (state == WifiConnectionState.connected)
              _buildConnectedView()
            else if (state == WifiConnectionState.connecting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: FlipperColors.primary),
                ),
              )
            else
              _buildConnectionForm(state),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: FlipperColors.surface,
        border: Border.all(color: FlipperColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isHostMode = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isHostMode ? FlipperColors.primary : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.devices,
                      size: 18,
                      color: !_isHostMode ? Colors.black : FlipperColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CLIENT MODE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: !_isHostMode ? Colors.black : FlipperColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1.5, height: 46, color: FlipperColors.border),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isHostMode = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isHostMode ? FlipperColors.primary : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.router,
                      size: 18,
                      color: _isHostMode ? Colors.black : FlipperColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HOST MODE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isHostMode ? Colors.black : FlipperColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostModeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHotspotCard(),
        const SizedBox(height: 16),
        _buildHotspotInstructions(),
        const SizedBox(height: 16),
        if (widget.hotspotService.isHotspotEnabled) _buildConnectedDevicesCard(),
      ],
    );
  }

  Widget _buildHotspotCard() {
    final isHotspotActive = widget.hotspotService.isHotspotEnabled;
    
    return Container(
      decoration: BoxDecoration(
        color: FlipperColors.surface,
        border: Border.all(
          color: isHotspotActive ? FlipperColors.success : FlipperColors.border,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: FlipperColors.border, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: FlipperColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.wifi_tethering,
                    color: FlipperColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WIFI HOTSPOT',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: FlipperColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isHotspotActive ? FlipperColors.success : FlipperColors.textDisabled,
                              shape: BoxShape.circle,
                              boxShadow: isHotspotActive
                                  ? [
                                      BoxShadow(
                                        color: FlipperColors.success,
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isHotspotActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isHotspotActive ? FlipperColors.success : FlipperColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isHotspotActive,
                  onChanged: (_) => _toggleHotspot(),
                  activeColor: FlipperColors.success,
                  activeTrackColor: FlipperColors.success.withOpacity(0.3),
                ),
              ],
            ),
          ),
          
          // Credentials
          if (isHotspotActive) ...[
            _buildCredentialRow('SSID', widget.hotspotService.ssid, Icons.wifi),
            _buildCredentialRow('PASSWORD', widget.hotspotService.password, Icons.lock),
            _buildCredentialRow('IP ADDRESS', widget.hotspotService.ipAddress, Icons.router),
          ] else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.wifi_off, size: 48, color: FlipperColors.textDisabled),
                  const SizedBox(height: 12),
                  const Text(
                    'Enable hotspot to share network',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: FlipperColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: FlipperColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: FlipperColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: FlipperColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: FlipperColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(value, label),
            icon: const Icon(Icons.copy, size: 18),
            color: FlipperColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlipperColors.primary.withOpacity(0.1),
        border: Border.all(color: FlipperColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: FlipperColors.primary),
              const SizedBox(width: 8),
              const Text(
                'SETUP INSTRUCTIONS',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: FlipperColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'Enable hotspot on this device'),
          _buildInstructionStep('2', 'Connect ESP32 to network "${widget.hotspotService.ssid}"'),
          _buildInstructionStep('3', 'Use password: ${widget.hotspotService.password}'),
          _buildInstructionStep('4', 'ESP32 will connect automatically'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: FlipperColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: FlipperColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDevicesCard() {
    final connectedDevices = widget.hotspotService.connectedDevices;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlipperColors.surface,
        border: Border.all(color: FlipperColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.devices, size: 18, color: FlipperColors.primary),
              const SizedBox(width: 8),
              const Text(
                'CONNECTED DEVICES',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: FlipperColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FlipperColors.primary.withOpacity(0.2),
                  border: Border.all(color: FlipperColors.primary, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${connectedDevices.length}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: FlipperColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (connectedDevices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.devices_other, size: 48, color: FlipperColors.textDisabled),
                    const SizedBox(height: 12),
                    Text(
                      'Waiting for ESP32 connection...',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: FlipperColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...connectedDevices.map((device) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDeviceItem(
                device.name,
                device.ipAddress,
                device.isESP32,
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(String name, String ip, bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: isConnected ? FlipperColors.success : FlipperColors.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? FlipperColors.success : FlipperColors.textDisabled,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: FlipperColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ip,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: FlipperColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: FlipperColors.success, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'READY',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: FlipperColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionForm(WifiConnectionState state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FlipperColors.surface,
            border: Border.all(color: FlipperColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cable, size: 18, color: FlipperColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'CONNECT TO ESP32',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: FlipperColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Connection Presets Button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConnectionPresetsScreen(
                          onConnect: (ipAddress) {
                            setState(() {
                              _ipController.text = ipAddress;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bookmark_border, size: 18),
                  label: const Text(
                    'SAVED DEVICES',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FlipperColors.primary,
                    side: const BorderSide(color: FlipperColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ipController,
                decoration: InputDecoration(
                  labelText: "IP ADDRESS",
                  labelStyle: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: FlipperColors.border, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: FlipperColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: FlipperColors.primary, width: 2),
                  ),
                  hintText: "192.168.4.1",
                  hintStyle: const TextStyle(fontFamily: 'monospace', color: FlipperColors.textDisabled),
                  filled: true,
                  fillColor: Colors.black,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: FlipperColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlipperColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.power_settings_new, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "CONNECT",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (state == WifiConnectionState.error)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FlipperColors.error.withOpacity(0.1),
                border: Border.all(color: FlipperColors.error, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: FlipperColors.error, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    "CONNECTION FAILED",
                    style: TextStyle(
                      color: FlipperColors.error,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConnectedView() {
    return Column(
      children: [
        _buildDeviceInfoCard(),
        const SizedBox(height: 16),
        _buildDisconnectButton(),
      ],
    );
  }

  Widget _buildDisconnectButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: widget.wifiService.disconnect,
        style: ElevatedButton.styleFrom(
          backgroundColor: FlipperColors.error,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: FlipperColors.error, width: 2),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.power_off, size: 20),
            SizedBox(width: 10),
            Text(
              "DISCONNECT",
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(WifiConnectionState state) {
    final isHotspotActive = widget.hotspotService.isHotspotEnabled;
    
    return RepaintBoundary(
      child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: FlipperColors.surface,
        border: Border.all(
          color: _isHostMode 
              ? (isHotspotActive ? FlipperColors.primary : FlipperColors.border)
              : _getColorForState(state), 
          width: 2
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _isHostMode
                    ? (isHotspotActive ? FlipperColors.primary : FlipperColors.border)
                    : _getColorForState(state),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _isHostMode ? Icons.wifi_tethering : Icons.router,
              size: 32,
              color: _isHostMode
                  ? (isHotspotActive ? FlipperColors.primary : FlipperColors.textDisabled)
                  : FlipperColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DEZERO",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: FlipperColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isHostMode
                            ? (isHotspotActive ? FlipperColors.success : FlipperColors.textDisabled)
                            : _getColorForState(state),
                        shape: BoxShape.circle,
                        boxShadow: (_isHostMode && isHotspotActive) || 
                                   (!_isHostMode && state == WifiConnectionState.connected)
                            ? [
                                BoxShadow(
                                  color: _isHostMode ? FlipperColors.success : _getColorForState(state),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isHostMode
                          ? (isHotspotActive ? 'HOTSPOT ACTIVE' : 'HOTSPOT OFF')
                          : _getTextForState(state),
                      style: TextStyle(
                        color: _isHostMode
                            ? (isHotspotActive ? FlipperColors.success : FlipperColors.textDisabled)
                            : _getColorForState(state),
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDeviceInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: FlipperColors.surface,
        border: Border.all(color: FlipperColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: FlipperColors.border, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: FlipperColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'DEVICE INFORMATION',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: FlipperColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _buildInfoTile("FIRMWARE", _firmwareVersion),
          _buildInfoTile("MAC ADDRESS", _macAddress),
          _buildInfoTile("CPU FREQ", "$_cpuFreq MHz"),
          _buildInfoTile("RAM", "${(_ramUsed / 1024).toStringAsFixed(0)} / ${(_ramTotal / 1024).toStringAsFixed(0)} KB"),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FlipperColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: FlipperColors.textTertiary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: FlipperColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForState(WifiConnectionState state) {
    switch (state) {
      case WifiConnectionState.connected: return FlipperColors.success;
      case WifiConnectionState.connecting: return FlipperColors.warning;
      case WifiConnectionState.error: return FlipperColors.error;
      default: return FlipperColors.textDisabled;
    }
  }

  String _getTextForState(WifiConnectionState state) {
    switch (state) {
      case WifiConnectionState.connecting: return "CONNECTING...";
      case WifiConnectionState.connected: return "CONNECTED";
      case WifiConnectionState.error: return "ERROR";
      default: return "DISCONNECTED";
    }
  }
}