import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_management_service.dart';
import '../services/marketplace_service.dart';
import '../models/tool_package.dart';
import '../widgets/tool_list_item.dart';
import 'run_tool_screen.dart';

class AppsScreen extends StatefulWidget {
  // Constructor is simple and takes no parameters
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  // Services are accessed directly
  final AppManagementService _appManagementService = AppManagementService();
  final MarketplaceService _marketplaceService = MarketplaceService();
  
  List<ToolPackage> _allTools = [];
  List<ToolPackage> _installedPackages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _appManagementService.installedTools.addListener(_filterInstalledTools);
    _initialize();
  }

  @override
  void dispose() {
    _appManagementService.installedTools.removeListener(_filterInstalledTools);
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _allTools = await _marketplaceService.fetchTools();
      _filterInstalledTools();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterInstalledTools() {
    final installedIds = _appManagementService.installedTools.value;
    final filtered =
        _allTools.where((tool) => installedIds.containsKey(tool.id)).toList();
    if (mounted) {
      setState(() {
        _installedPackages = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Installed Apps")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _installedPackages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "No apps installed.\nGo to the Tools tab to add some.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                              builder: (context) => RunToolScreen(tool: tool)),
                        );
                      },
                      onInstall: () {},
                      onUninstall: () =>
                          _appManagementService.uninstallTool(tool.id),
                      onRun: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RunToolScreen(tool: tool)),
                        );
                      },
                    );
                  },
                ),
    );
  }
}