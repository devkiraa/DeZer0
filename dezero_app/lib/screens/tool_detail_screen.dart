import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/tool_package.dart';
import '../services/app_management_service.dart';
import '../services/marketplace_service.dart';
import '../services/wifi_service.dart';
import 'run_tool_screen.dart';

enum ActionState { idle, downloading }

class ToolDetailScreen extends StatefulWidget {
  final ToolPackage tool;
  final WifiService wifiService;
  // FIX: Add the field that the constructor requires
  final AppManagementService appManagementService;

  const ToolDetailScreen({
    super.key,
    required this.tool,
    required this.wifiService,
    required this.appManagementService,
  });

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  
  ActionState _actionState = ActionState.idle;
  double _progress = 0.0;
  late bool _isInstalled;
  bool _isUpdateAvailable = false;
  String _changelog = "Loading changelog...";

  @override
  void initState() {
    super.initState();
    // Access the service via the widget now
    widget.appManagementService.installedTools.addListener(_checkInstallationStatus);
    _checkInstallationStatus();
    _fetchChangelog();
  }

  @override
  void dispose() {
    widget.appManagementService.installedTools.removeListener(_checkInstallationStatus);
    super.dispose();
  }
  
  void _checkInstallationStatus() {
    if (!mounted) return;
    final isInstalled = widget.appManagementService.isInstalled(widget.tool.id);
    bool hasUpdate = false;
    if (isInstalled) {
      final installedVersion = widget.appManagementService.getInstalledVersion(widget.tool.id);
      if (installedVersion != widget.tool.version) {
        hasUpdate = true;
      }
    }
    setState(() {
      _isInstalled = isInstalled;
      _isUpdateAvailable = hasUpdate;
    });
  }

  Future<void> _fetchChangelog() async {
    setState(() {
      _changelog = widget.tool.changelog;
    });
  }

  Future<void> _startDownloadOrUpdate() async {
    setState(() { _actionState = ActionState.downloading; _progress = 0.0; });

    final fileBytes = await _marketplaceService.downloadToolWithProgress(
      widget.tool, (p) => setState(() => _progress = p));

    if(mounted) {
      if (fileBytes != null) {
        widget.appManagementService.installTool(widget.tool, fileBytes);
      }
      setState(() { _actionState = ActionState.idle; });
    }
  }

  void _uninstall() {
    widget.appManagementService.uninstallTool(widget.tool.id);
  }

  void _openTool() {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => RunToolScreen(
        tool: widget.tool,
        wifiService: widget.wifiService,
      )
    ));
  }

  Future<void> _launchRepoUrl() async {
    final url = Uri.parse('https://github.com/devkiraa/DeZer0-Tools');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Handle error
    }
  }

  Widget _buildActionButton() {
    if (_actionState == ActionState.downloading) {
      return SizedBox(
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            LinearProgressIndicator(value: _progress, minHeight: 50, borderRadius: BorderRadius.circular(25)),
            Text("${(_progress * 100).toStringAsFixed(0)}%"),
          ],
        ),
      );
    }
    
    if (_isUpdateAvailable) {
      return FilledButton.icon(
        icon: const Icon(Icons.system_update_alt),
        label: const Text("Update"),
        onPressed: _startDownloadOrUpdate,
        style: FilledButton.styleFrom(backgroundColor: Colors.green),
      );
    }

    if (_isInstalled) {
      return FilledButton(
        onPressed: _openTool,
        child: const Text("Open"),
      );
    }

    return FilledButton(
      onPressed: _startDownloadOrUpdate,
      child: const Text("Install"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tool.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.extension, size: 60, color: Theme.of(context).primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.tool.name, style: Theme.of(context).textTheme.headlineSmall),
                      Text(widget.tool.category, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip("Version", widget.tool.version),
                _buildInfoChip("Size", widget.tool.size),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 50, child: _buildActionButton()),
            if (_isInstalled)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _uninstall,
                  child: const Text("Uninstall", style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ),
            const SizedBox(height: 24),
            Text("Description", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Text(widget.tool.description),
            const SizedBox(height: 24),
            Text("Changelog", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Text(_changelog),
            const SizedBox(height: 24),
            Text("Developer", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.github),
              title: const Text("Repository"),
              onTap: _launchRepoUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}