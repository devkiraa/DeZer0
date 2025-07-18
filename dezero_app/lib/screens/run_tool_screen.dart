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
  final AppManagementService _appManagementService = AppManagementService.instance;
  StreamSubscription? _logSubscription;

  final List<String> _consoleLogs = [];
  final ScrollController _scrollController = ScrollController();
  String _scriptContent = "";
  bool _isLoadingScript = true;
  bool _isExecuting = false;
  bool _scriptLoadError = false;

  @override
  void initState() {
    super.initState();
    widget.wifiService.addListener(_onStateChanged);
    _logSubscription = widget.wifiService.logStream.listen(_onDataReceived);
    _loadScript();
  }

  @override
  void dispose() {
    widget.wifiService.removeListener(_onStateChanged);
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadScript() async {
  final content = await _appManagementService.getScript(widget.tool.id);
  if (mounted) {
    setState(() {
      if (content == null) {
        _scriptContent = "";
        _scriptLoadError = true;
        _consoleLogs.add("Error: Could not load script.");
      } else {
        _scriptContent = content;
        _scriptLoadError = false;
      }
      _isLoadingScript = false;
      print("[DEBUG] Script loaded: ${_scriptLoadError ? 'Failed' : 'Success'}");
    });
  }
}

 void _onDataReceived(String data) {
  if (!mounted) return;

  setState(() {
    final lines = data.trim().split('\n');
    _consoleLogs.addAll(lines.where((line) => line.isNotEmpty));

    if (data.contains("--- Execution Finished ---")) {
      _isExecuting = false;
    }
  });

  _scrollToBottom();
}

  void _executeScript() {
  print("[DEBUG] Run button pressed");

  if (_isLoadingScript) {
    print("[DEBUG] Blocked: Script is still loading");
    return;
  }

  if (_isExecuting) {
    print("[DEBUG] Blocked: Script already executing");
    return;
  }

  if (_scriptLoadError) {
    print("[DEBUG] Blocked: Script failed to load");
    return;
  }

  if (widget.wifiService.connectionState != WifiConnectionState.connected) {
    print("[DEBUG] Blocked: Not connected to device");
    return;
  }

  print("[DEBUG] Script content:\n$_scriptContent");

  final scriptBytes = utf8.encode(_scriptContent);
  final scriptBase64 = base64Encode(scriptBytes);

  final command = {
    "command": "execute_script",
    "script": scriptBase64
  };

  final jsonCommand = jsonEncode(command);
  print("[DEBUG] Sending command: $jsonCommand");

  setState(() {
    _isExecuting = true;
    _consoleLogs.clear();
    _consoleLogs.add("-> Executing '${widget.tool.name}' on DeZer0...");
  });

  widget.wifiService.sendCommand(jsonCommand);
}

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = widget.wifiService.connectionState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("DeZer0 Tool Executor")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildScriptPreviewCard(theme),
            const SizedBox(height: 8),
            _buildRunButton(connectionState),
            const SizedBox(height: 8),
            const Divider(),
            _buildConsole(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildScriptPreviewCard(ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(widget.tool.scriptFilename,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: const Text("Payload Script"),
          ),
          const Divider(height: 1),
          Container(
            color: Colors.black.withOpacity(0.05),
            height: 150,
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: _isLoadingScript
                  ? const Text("Loading...")
                  : _scriptLoadError
                      ? const Text("Error: Could not load script.",
                          style: TextStyle(color: Colors.red))
                      : Text(
                          _scriptContent,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.black87),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(WifiConnectionState connectionState) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton.icon(
      icon: _isExecuting
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : const Icon(Icons.play_arrow_rounded),
      label: Text(
        _isExecuting ? "EXECUTING..." : "RUN PAYLOAD",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onPressed: (_isLoadingScript || _isExecuting || connectionState != WifiConnectionState.connected || _scriptLoadError)
          ? null
          : _executeScript,
    ),
  );
}

  Widget _buildConsole(ThemeData theme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Output Console", style: theme.textTheme.titleMedium),
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
            child: Card(
              margin: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                color: Colors.black.withOpacity(0.8),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _consoleLogs.length,
                  itemBuilder: (context, index) {
                    final log = _consoleLogs[index];
                    return Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: log.startsWith("->") ? Colors.amberAccent : Colors.white70,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}