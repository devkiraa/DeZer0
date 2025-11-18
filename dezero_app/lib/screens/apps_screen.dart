import 'package:flutter/material.dart';
import '../services/app_management_service.dart';
import '../services/marketplace_service.dart';
import '../services/wifi_service.dart';
import '../models/tool_package.dart';
import '../screens/activity_history_screen.dart';
import '../theme/flipper_theme.dart';
import 'run_tool_screen.dart';

class AppsScreen extends StatefulWidget {
  final AppManagementService appManagementService;
  final WifiService wifiService;
  final VoidCallback onMenuPressed;
  
  const AppsScreen({
    super.key,
    required this.appManagementService,
    required this.wifiService,
    required this.onMenuPressed,
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
  
  void _navigateToRunScreen(ToolPackage tool) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunToolScreen(
          tool: tool,
          wifiService: widget.wifiService,
        ),
      ),
    );
  }

  Widget _buildAppCard(ToolPackage tool) {
    return GestureDetector(
      onTap: () => _navigateToRunScreen(tool),
      child: Container(
        decoration: BoxDecoration(
          color: FlipperColors.surface,
          border: Border.all(color: FlipperColors.primary.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon section
            Expanded(
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: FlipperColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(tool.category),
                    size: 40,
                    color: FlipperColors.primary,
                  ),
                ),
              ),
            ),
            
            // Tool name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                tool.name,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: FlipperColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Category badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FlipperColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tool.category.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: FlipperColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: () => _navigateToRunScreen(tool),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlipperColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'RUN',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: IconButton(
                      onPressed: () {
                        _showDeleteConfirmation(tool);
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: FlipperColors.surface,
                        side: BorderSide(color: FlipperColors.error.withOpacity(0.5), width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: FlipperColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ToolPackage tool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlipperColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: FlipperColors.primary, width: 1),
        ),
        title: const Text(
          'DELETE APP',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: FlipperColors.textPrimary,
          ),
        ),
        content: Text(
          'Remove ${tool.name} from installed apps?',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: FlipperColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: FlipperColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              widget.appManagementService.uninstallTool(tool.id);
              
              // Log uninstallation
              ActivityHistoryService.addLog(
                type: 'tool_execution',
                title: 'App uninstalled',
                description: '${tool.name} removed from installed apps',
                isSuccess: true,
              );
              
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlipperColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'DELETE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuPressed,
        ),
        title: const Text("INSTALLED APPS"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FlipperColors.primary))
          : _installedPackages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apps, size: 80, color: FlipperColors.textDisabled),
                      const SizedBox(height: 16),
                      const Text(
                        "NO APPS INSTALLED",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: FlipperColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _installedPackages.length,
                  itemBuilder: (context, index) {
                    final tool = _installedPackages[index];
                    return _buildAppCard(tool);
                  },
                ),
    );
  }
}