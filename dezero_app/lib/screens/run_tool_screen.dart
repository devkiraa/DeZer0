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
  final ScrollController _scrollController = ScrollController();
  String _scriptContent = "Loading script...";
  bool _isLoadingScript = true;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    // FIX: Add a listener to the service to rebuild when connection state changes
    widget.wifiService.addListener(_onStateChanged);
    _logSubscription = widget.wifiService.logStream.listen(_onDataReceived);
    _loadScript();
  }

  @override
  void dispose() {
    // FIX: Remove the listener to prevent memory leaks
    widget.wifiService.removeListener(_onStateChanged);
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
  
  // This function will now be called whenever the connection state changes,
  // forcing the UI to rebuild and update the button's status.
  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
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
      _consoleLogs.insert(0, data.trim());
      if (data.contains("--- Execution Finished ---")) {
        _isExecuting = false;
      }
    });
    _scrollToBottom();
  }

  void _executeScript() {
    print("Execute button pressed..."); // DEBUG
    if (_isLoadingScript) {
      print("Execution blocked: Script is still loading.");
      return;
    }
    if (_isExecuting) {
      print("Execution blocked: A script is already running.");
      return;
    }
    if (widget.wifiService.connectionState != WifiConnectionState.connected) {
      print("Execution blocked: Device not connected.");
      return;
    }
    
    print("All checks passed. Preparing to send script.");
    
    final scriptBytes = utf8.encode(_scriptContent);
    final scriptBase64 = base64Encode(scriptBytes);
    
    final command = {
      "command": "execute_script",
      "script": scriptBase64
    };
    
    setState(() {
      _isExecuting = true;
      _consoleLogs.clear();
      _consoleLogs.insert(0, "-> Executing '${widget.tool.name}' on DeZer0...");
    });
    widget.wifiService.sendCommand(jsonEncode(command));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = widget.wifiService.connectionState;
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.tool.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              icon: _isExecuting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                : const Icon(Icons.play_arrow),
              label: Text(_isExecuting ? "Executing..." : "Execute on DeZer0"),
              onPressed: (_isLoadingScript || _isExecuting || connectionState != WifiConnectionState.connected) ? null : _executeScript,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            ),
          ),
          const Divider(height: 1),
          // Console UI... (omitted for brevity, it is the same as before)
          Expanded(
            child: Container(
              color: Theme.of(context).cardColor.withOpacity(0.5),
              child: ListView.builder(
                controller: _scrollController,
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