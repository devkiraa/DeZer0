import 'package:flutter/material.dart';
import '../services/wifi_service.dart';
import '../services/app_management_service.dart';
import '../services/marketplace_service.dart';
import '../models/tool_package.dart';
import '../widgets/tool_list_item.dart';
import 'tool_detail_screen.dart';
import 'updates_screen.dart';

class ToolsScreen extends StatefulWidget {
  final WifiService wifiService;
  final AppManagementService appManagementService;
  const ToolsScreen(
      {super.key,
      required this.wifiService,
      required this.appManagementService});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  List<ToolPackage> _allTools = [];
  List<ToolPackage> _filteredTools = [];
  bool _isLoading = true;
  bool _hasUpdates = false;

  @override
  void initState() {
    super.initState();
    widget.appManagementService.installedTools.addListener(_onInstallStatusChanged);
    _fetchTools();
  }

  @override
  void dispose() {
    widget.appManagementService.installedTools
        .removeListener(_onInstallStatusChanged);
    super.dispose();
  }

  void _onInstallStatusChanged() {
    if (mounted) {
      _checkForUpdates();
      setState(() {});
    }
  }

  Future<void> _fetchTools() async {
    try {
      final tools = await _marketplaceService.fetchTools();
      if (mounted) {
        setState(() {
          _allTools = tools;
          _filteredTools = tools;
          _isLoading = false;
        });
        _checkForUpdates();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print(e);
    }
  }

  void _checkForUpdates() {
    final installed = widget.appManagementService.installedTools.value;
    bool foundUpdates = false;
    for (var installedToolId in installed.keys) {
      try {
        final installedVersion = installed[installedToolId];
        final marketplaceTool =
            _allTools.firstWhere((t) => t.id == installedToolId);
        if (marketplaceTool.version != installedVersion) {
          foundUpdates = true;
          break;
        }
      } catch (e) { /* ignore */ }
    }
    if (mounted) {
      setState(() {
        _hasUpdates = foundUpdates;
      });
    }
  }

  void _filterTools(String query) {
    setState(() {
      _filteredTools = _allTools
          .where((tool) =>
              tool.name.toLowerCase().contains(query.toLowerCase()) ||
              tool.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _navigateToDetail(ToolPackage tool) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ToolDetailScreen(
          tool: tool,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tools Marketplace"),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.system_update_alt),
                onPressed: () {
                  final installed =
                      widget.appManagementService.installedTools.value;
                  final List<ToolPackage> updatableTools = [];

                  for (var installedToolId in installed.keys) {
                    try {
                      final installedVersion = installed[installedToolId];
                      final marketplaceTool = _allTools
                          .firstWhere((t) => t.id == installedToolId);
                      if (marketplaceTool.version != installedVersion) {
                        updatableTools.add(marketplaceTool);
                      }
                    } catch (e) { /* ignore */ }
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdatesScreen(
                        updatableTools: updatableTools,
                        appManagementService: widget.appManagementService,
                      ),
                    ),
                  );
                },
                tooltip: "Updates",
              ),
              if (_hasUpdates)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                )
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              onChanged: _filterTools,
              decoration: InputDecoration(
                hintText: 'Search tools...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTools.isEmpty
                    ? const Center(child: Text("No tools found."))
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _filteredTools.length,
                        itemBuilder: (context, index) {
                          final tool = _filteredTools[index];
                          final isInstalled =
                              widget.appManagementService.isInstalled(tool.id);
                          return ToolListItem(
                            tool: tool,
                            isInstalled: isInstalled,
                            onTap: () => _navigateToDetail(tool),
                            onInstall: () => _navigateToDetail(tool),
                            onUninstall: () => widget.appManagementService
                                .uninstallTool(tool.id),
                            onRun: () {},
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}