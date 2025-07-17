import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  // Services
  final AppManagementService _appManagementService = AppManagementService.instance;
  late WifiService _wifiService;
  
  // State
  StreamSubscription? _logSubscription;
  final List<String> _consoleLogs = [];
  final ScrollController _scrollController = ScrollController();
  String _scriptContent = "Loading script...";
  bool _isLoadingScript = true;
  bool _isExecuting = false;
  
  // Settings State
  bool _logOutput = true;

  @override
  void initState() {
    super.initState();
    _wifiService = Provider.of<WifiService>(context, listen: false);
    _logSubscription = _wifiService.logStream.listen(_onDataReceived);
    _loadScript();
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadScript({bool showSnackbar = false}) async {
    if (!mounted) return;
    setState(() { _isLoadingScript = true; });
    
    final content = await _appManagementService.getScript(widget.tool.id);
    
    if (mounted) {
      setState(() {
        _scriptContent = content ?? "Error: Could not load script.";
        _isLoadingScript = false;
      });
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Script reloaded."), duration: Duration(seconds: 1)),
        );
      }
    }
  }

  void _onDataReceived(String data) {
    if (!mounted) return;
    setState(() {
      _consoleLogs.addAll(data.trim().split('\n').where((s) => s.isNotEmpty));
      if (data.contains("--- Execution Finished ---")) {
        _isExecuting = false;
      }
    });
    _scrollToBottom();
  }

  void _executeScript() {
    if (_isLoadingScript || _isExecuting || !_scriptContent.startsWith("import")) return;
    
    final scriptBytes = utf8.encode(_scriptContent);
    final scriptBase64 = base64Encode(scriptBytes);
    final command = {"command": "execute_script", "script": scriptBase64};
    
    setState(() {
      _isExecuting = true;
      _consoleLogs.clear();
      _consoleLogs.add("-> Executing '${widget.tool.name}' on DeZer0...");
    });
    _wifiService.sendCommand(jsonEncode(command));
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
    // Watch for connection state changes to update button enabled status
    final connectionState = context.watch<WifiService>().connectionState;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("DeZer0 Tool Executor")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildInfoCard(theme),
                  const SizedBox(height: 8),
                  _buildScriptPreviewCard(theme),
                  const SizedBox(height: 8),
                  _buildSettingsCard(theme),
                  const SizedBox(height: 8),
                  _buildStatusCard(theme, connectionState),
                ],
              ),
            ),
            _buildRunButton(connectionState),
            _buildConsole(theme),
          ],
        ),
      ),
    );
  }

  // --- UI Builder Methods ---

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.psychology_alt_outlined),
            title: Text(widget.tool.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: const Text("Tool Name"),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(widget.tool.scriptFilename, style: theme.textTheme.titleMedium),
            subtitle: const Text("Payload Script"),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptPreviewCard(ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Text("Script Preview", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ),
          const Divider(),
          Container(
            color: theme.scaffoldBackgroundColor,
            height: 120,
            width: double.infinity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _isLoadingScript ? "Loading..." : _scriptContent,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
              ),
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () { /* Placeholder for Edit */ }, child: const Text("Edit")),
              TextButton(onPressed: () => _loadScript(showSnackbar: true), child: const Text("Reload")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Text("Execution Settings", style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ),
          CheckboxListTile(
            title: const Text("Log Output to Console"),
            value: _logOutput,
            onChanged: (val) => setState(() => _logOutput = val!),
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, WifiConnectionState state) {
    return Card(
      child: ListTile(
        leading: Icon(
          state == WifiConnectionState.connected ? Icons.wifi_channel : Icons.wifi_off,
          color: state == WifiConnectionState.connected ? Colors.green : Colors.red,
        ),
        title: const Text("Target Device"),
        subtitle: Text(
          state == WifiConnectionState.connected ? 'Connected' : 'Disconnected',
        ),
      ),
    );
  }
  
  Widget _buildRunButton(WifiConnectionState connectionState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          icon: _isExecuting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Icon(Icons.play_arrow_rounded),
          label: Text(_isExecuting ? "EXECUTING..." : "RUN PAYLOAD", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          onPressed: (_isLoadingScript || _isExecuting || connectionState != WifiConnectionState.connected) ? null : _executeScript,
        ),
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
            child: Text("Output Console", style: theme.textTheme.titleMedium),
          ),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                color: Colors.black.withOpacity(0.02),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _consoleLogs.length,
                  itemBuilder: (context, index) {
                    final log = _consoleLogs.reversed.toList()[index];
                    return Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: log.startsWith("->") ? theme.primaryColor : Colors.black87,
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