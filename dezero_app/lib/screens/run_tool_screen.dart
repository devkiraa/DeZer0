import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool_package.dart';
import '../services/wifi_service.dart';

class RunToolScreen extends StatefulWidget {
  final ToolPackage tool;
  const RunToolScreen({super.key, required this.tool});

  @override
  State<RunToolScreen> createState() => _RunToolScreenState();
}

class _RunToolScreenState extends State<RunToolScreen> {
  late WifiService _wifiService;
  StreamSubscription? _logSubscription;
  final List<String> _consoleLogs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the WifiService from Provider and add listeners
    _wifiService = Provider.of<WifiService>(context, listen: false);
    _logSubscription?.cancel(); // Cancel any old subscription
    _logSubscription = _wifiService.logStream.listen(_onDataReceived);
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    super.dispose();
  }

  void _onDataReceived(String data) {
    if (!mounted) return;

    // Add raw message to console
    setState(() {
      _consoleLogs.insert(0, data);
    });

    // Try to parse it for pretty printing
    try {
      final jsonData = jsonDecode(data);
      if (jsonData['type'] == 'wifi_scan_results') {
        final networks = jsonData['networks'] as List;
        setState(() {
          _consoleLogs.insert(0, "✅ Found ${networks.length} networks.");
          for (var net in networks) {
             _consoleLogs.insert(0, "  - ${net['ssid']} (${net['rssi']} dBm)");
          }
        });
      }
    } catch (e) {
      // Ignore if it's not valid JSON
    }
  }

  void _runScan() {
    // Clear previous logs and send command
    setState(() {
      _consoleLogs.insert(0, "-> Sending command: scan_wifi");
    });
    _wifiService.sendCommand('{"command":"scan_wifi"}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tool.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Controls Section ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.wifi_tethering),
              label: const Text("Scan for Networks"),
              onPressed: _runScan,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15)
              ),
            ),
          ),

          const Divider(),

          // --- Console Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Console", style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black.withOpacity(0.05),
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                reverse: true, // To show newest logs at the bottom
                itemCount: _consoleLogs.length,
                itemBuilder: (context, index) {
                  return Text(
                    _consoleLogs[index],
                    style: const TextStyle(fontFamily: 'monospace'),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}