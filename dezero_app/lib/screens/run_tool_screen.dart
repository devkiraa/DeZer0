import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/tool_package.dart';
import '../services/wifi_service.dart';
import '../services/app_management_service.dart';

class RunToolScreen extends StatefulWidget {
  final ToolPackage tool;
  final WifiService wifiService;
  const RunToolScreen({super.key, required this.tool, required this.wifiService});

  @override
  State<RunToolScreen> createState() => _RunToolScreenState();
}

class _RunToolScreenState extends State<RunToolScreen> {
  final AppManagementService _appManagementService = AppManagementService();
  StreamSubscription? _logSubscription;
  
  final List<String> _consoleLogs = [];
  String _scriptContent = "Loading script...";
  bool _isLoadingScript = true;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _logSubscription = widget.wifiService.logStream.listen(_onDataReceived);
    _loadScript();
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadScript() async {
    final content = await _appManagementService.getScript(widget.tool.id);
    if (mounted) {
      setState(() {
        _scriptContent = content ?? "Error: Could not load script.";
        _isLoadingScript = false;
      });
    }
  }

  void _onDataReceived(String data) {
    if (!mounted) return;
    setState(() {
      _consoleLogs.insert(0, data);
      if (data.contains("--- Execution Finished ---")) {
        _isExecuting = false;
      }
    });
  }

  void _executeScript() {
    if (_isLoadingScript || _isExecuting || !_scriptContent.startsWith("import")) return;
    
    final scriptBytes = utf8.encode(_scriptContent);
    final scriptBase64 = base64Encode(scriptBytes);
    
    final command = {"command": "execute_script", "script": scriptBase64};
    
    setState(() {
      _isExecuting = true;
      _consoleLogs.clear();
      _consoleLogs.insert(0, "-> Executing '${widget.tool.name}' on DeZer0...");
    });
    widget.wifiService.sendCommand(jsonEncode(command));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tool.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              icon: _isExecuting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Icon(Icons.play_arrow),
              label: Text(_isExecuting ? "Executing..." : "Execute on DeZer0"),
              onPressed: (_isLoadingScript || _isExecuting || widget.wifiService.connectionState != WifiConnectionState.connected) ? null : _executeScript,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Console", style: Theme.of(context).textTheme.titleMedium),
                 IconButton(
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 20,
                  tooltip: "Clear Console",
                  onPressed: () => setState(() => _consoleLogs.clear()),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).cardColor.withOpacity(0.5),
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                reverse: true,
                itemCount: _consoleLogs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      _consoleLogs[index],
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
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