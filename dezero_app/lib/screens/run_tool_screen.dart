import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/tool_package.dart';
import '../services/wifi_service.dart';
import '../services/app_management_service.dart';
import '../screens/activity_history_screen.dart';
import '../theme/flipper_theme.dart';

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
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debouncedSetState(VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) setState(callback);
    });
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

  final lines = data.trim().split('\n');
  _consoleLogs.addAll(lines.where((line) => line.isNotEmpty));

  if (data.contains("--- Execution Finished ---")) {
    _isExecuting = false;
    
    // Check if execution was successful (no errors)
    final hasErrors = _consoleLogs.any((log) => 
      log.toLowerCase().contains('error') || 
      log.toLowerCase().contains('exception') ||
      log.toLowerCase().contains('failed')
    );
    
    ActivityHistoryService.addLog(
      type: 'tool_execution',
      title: hasErrors ? 'Tool execution failed' : 'Tool executed successfully',
      description: '${widget.tool.name}: ${hasErrors ? "Completed with errors" : "Completed successfully"}',
      isSuccess: !hasErrors,
    );
  }

  _debouncedSetState(() {});
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
    ActivityHistoryService.addLog(
      type: 'error',
      title: 'Script load failed',
      description: '${widget.tool.name}: Unable to load script file',
      isSuccess: false,
    );
    return;
  }

  if (widget.wifiService.connectionState != WifiConnectionState.connected) {
    print("[DEBUG] Blocked: Not connected to device");
    ActivityHistoryService.addLog(
      type: 'error',
      title: 'Not connected',
      description: '${widget.tool.name}: Device not connected',
      isSuccess: false,
    );
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

  // Log tool execution start
  ActivityHistoryService.addLog(
    type: 'tool_execution',
    title: 'Executing tool',
    description: '${widget.tool.name}: Started execution',
    isSuccess: true,
  );

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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tool.name.toUpperCase()),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getConnectionColor(connectionState).withOpacity(0.2),
                border: Border.all(color: _getConnectionColor(connectionState), width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getConnectionColor(connectionState),
                      shape: BoxShape.circle,
                      boxShadow: connectionState == WifiConnectionState.connected
                          ? [
                              BoxShadow(
                                color: _getConnectionColor(connectionState),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getConnectionText(connectionState),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getConnectionColor(connectionState),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildToolInfoCard(),
            const SizedBox(height: 12),
            _buildScriptPreviewCard(),
            const SizedBox(height: 12),
            _buildRunButton(connectionState),
            const SizedBox(height: 12),
            _buildConsoleHeader(),
            const SizedBox(height: 8),
            _buildConsole(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FlipperColors.surface,
        border: Border.all(color: FlipperColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: FlipperColors.primary, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getCategoryIcon(widget.tool.category),
              size: 28,
              color: FlipperColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.tool.name.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: FlipperColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v${widget.tool.version} • ${widget.tool.category.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: FlipperColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptPreviewCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: FlipperColors.surface,
        border: Border.all(color: FlipperColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: FlipperColors.border, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 16, color: FlipperColors.primary),
                const SizedBox(width: 8),
                Text(
                  widget.tool.scriptFilename.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: FlipperColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: FlipperColors.info, width: 1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'PAYLOAD',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: FlipperColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Script content
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: _isLoadingScript
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: FlipperColors.primary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'LOADING...',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              color: FlipperColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _scriptLoadError
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 32, color: FlipperColors.error),
                              SizedBox(height: 8),
                              Text(
                                'SCRIPT LOAD ERROR',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: FlipperColors.error,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            _scriptContent,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: Color(0xFF00FF00),
                              height: 1.4,
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton(WifiConnectionState connectionState) {
    final isDisabled = _isLoadingScript || 
                       _isExecuting || 
                       connectionState != WifiConnectionState.connected || 
                       _scriptLoadError;
    
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isDisabled ? null : _executeScript,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? FlipperColors.surface : FlipperColors.primary,
          foregroundColor: Colors.black,
          disabledBackgroundColor: FlipperColors.surface,
          disabledForegroundColor: FlipperColors.textDisabled,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isDisabled ? FlipperColors.border : FlipperColors.primary,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isExecuting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 3,
                ),
              )
            else
              const Icon(Icons.play_arrow_rounded, size: 28),
            const SizedBox(width: 10),
            Text(
              _isExecuting ? 'EXECUTING...' : 'RUN PAYLOAD',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsoleHeader() {
    return Row(
      children: [
        const Icon(Icons.terminal, size: 18, color: FlipperColors.primary),
        const SizedBox(width: 8),
        const Text(
          'OUTPUT CONSOLE',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: FlipperColors.textPrimary,
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 28,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _consoleLogs.clear()),
            style: OutlinedButton.styleFrom(
              foregroundColor: FlipperColors.textSecondary,
              side: const BorderSide(color: FlipperColors.border, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            icon: const Icon(Icons.delete_outline, size: 14),
            label: const Text(
              'CLEAR',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsole() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: FlipperColors.primary, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _consoleLogs.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.terminal, size: 48, color: FlipperColors.textDisabled),
                    SizedBox(height: 12),
                    Text(
                      'NO OUTPUT YET',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: FlipperColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Run the payload to see output',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: FlipperColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: _consoleLogs.length,
                itemBuilder: (context, index) {
                  final log = _consoleLogs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.4,
                        color: _getLogColor(log),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Color _getConnectionColor(WifiConnectionState state) {
    switch (state) {
      case WifiConnectionState.connected:
        return FlipperColors.success;
      case WifiConnectionState.connecting:
        return FlipperColors.warning;
      case WifiConnectionState.disconnected:
      case WifiConnectionState.error:
        return FlipperColors.error;
    }
  }

  String _getConnectionText(WifiConnectionState state) {
    switch (state) {
      case WifiConnectionState.connected:
        return 'CONNECTED';
      case WifiConnectionState.connecting:
        return 'CONNECTING';
      case WifiConnectionState.disconnected:
        return 'OFFLINE';
      case WifiConnectionState.error:
        return 'ERROR';
    }
  }

  Color _getLogColor(String log) {
    if (log.startsWith('->') || log.startsWith('Executing')) {
      return FlipperColors.primary;
    } else if (log.toLowerCase().contains('error') || log.toLowerCase().contains('failed')) {
      return FlipperColors.error;
    } else if (log.toLowerCase().contains('success') || log.contains('Finished')) {
      return FlipperColors.success;
    } else if (log.toLowerCase().contains('warning')) {
      return FlipperColors.warning;
    }
    return const Color(0xFF00FF00); // Terminal green
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'utility':
        return Icons.build_outlined;
      case 'security':
        return Icons.security_outlined;
      case 'network':
        return Icons.wifi_outlined;
      case 'hardware':
        return Icons.memory_outlined;
      case 'fun':
        return Icons.games_outlined;
      default:
        return Icons.apps_outlined;
    }
  }
}