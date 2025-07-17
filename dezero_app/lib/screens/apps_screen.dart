import 'package:flutter/material.dart';
import '../services/app_management_service.dart';
import '../services/marketplace_service.dart';
import '../services/wifi_service.dart';
import '../models/tool_package.dart';
import '../widgets/tool_list_item.dart';
import 'tool_detail_screen.dart';
import 'run_tool_screen.dart';

class AppsScreen extends StatefulWidget {
  final AppManagementService appManagementService;
  final WifiService wifiService;
  const AppsScreen({
    super.key,
    required this.appManagementService,
    required this.wifiService,
  });

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  List<ToolPackage> _allTools = [];
  List<ToolPackage> _installedPackages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.appManagementService.installedTools.addListener(_filterInstalledTools);
    _initialize();
  }

  @override
  void dispose() {
    widget.appManagementService.installedTools.removeListener(_filterInstalledTools);
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _allTools = await _marketplaceService.fetchTools();
      _filterInstalledTools();
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _filterInstalledTools() {
    final installedIds = widget.appManagementService.installedTools.value;
    final filtered = _allTools.where((tool) => installedIds.containsKey(tool.id)).toList();
    if (mounted) setState(() { _installedPackages = filtered; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Installed Apps")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _installedPackages.isEmpty
              ? const Center(child: Text("No apps installed."))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _installedPackages.length,
                  itemBuilder: (context, index) {
                    final tool = _installedPackages[index];
                    return ToolListItem(
                      tool: tool,
                      isInstalled: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RunToolScreen(
                              tool: tool,
                              wifiService: widget.wifiService,
                            ),
                          ),
                        );
                      },
                      onInstall: () {},
                      onUninstall: () => widget.appManagementService.uninstallTool(tool.id),
                      onRun: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RunToolScreen(
                              tool: tool,
                              wifiService: widget.wifiService,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}