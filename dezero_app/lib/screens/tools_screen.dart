import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/wifi_service.dart';
import '../services/app_management_service.dart';
import '../services/marketplace_service.dart';
import '../models/tool_package.dart';
import '../theme/flipper_theme.dart';
import 'tool_detail_screen.dart';
import 'tool_updates_screen.dart';

class ToolsScreen extends StatefulWidget {
  final WifiService wifiService;
  final AppManagementService appManagementService;
  final VoidCallback onMenuPressed;
  const ToolsScreen(
      {super.key,
      required this.wifiService,
      required this.appManagementService,
      required this.onMenuPressed});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  List<ToolPackage> _allTools = [];
  List<ToolPackage> _filteredTools = [];
  bool _isLoading = true;
  bool _hasUpdates = false;
  String _selectedCategory = 'ALL';
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    widget.appManagementService.installedTools.addListener(_onInstallStatusChanged);
    _fetchTools();
    _loadFavorites();
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

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesList = prefs.getStringList('favorite_tools') ?? [];
    if (mounted) {
      setState(() {
        _favoriteIds = favoritesList.toSet();
      });
    }
  }

  Future<void> _toggleFavorite(String toolId) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      if (_favoriteIds.contains(toolId)) {
        _favoriteIds.remove(toolId);
      } else {
        _favoriteIds.add(toolId);
      }
    });
    
    await prefs.setStringList('favorite_tools', _favoriteIds.toList());
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
      var filtered = _allTools.where((tool) =>
          tool.name.toLowerCase().contains(query.toLowerCase()) ||
          tool.description.toLowerCase().contains(query.toLowerCase()));
      
      if (_selectedCategory != 'ALL') {
        filtered = filtered.where((tool) => tool.category.toUpperCase() == _selectedCategory);
      }
      
      _filteredTools = filtered.toList();
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'ALL') {
        _filteredTools = _allTools;
      } else {
        _filteredTools = _allTools.where((tool) => tool.category.toUpperCase() == category).toList();
      }
    });
  }

  List<String> _getCategories() {
    final categories = _allTools.map((tool) => tool.category.toUpperCase()).toSet().toList();
    categories.sort();
    return ['ALL', ...categories];
  }

  void _navigateToDetail(ToolPackage tool) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ToolDetailScreen(
          tool: tool,
          wifiService: widget.wifiService,
          appManagementService: widget.appManagementService,
        ),
      ),
    );
  }

  Widget _buildToolCard(ToolPackage tool, bool isInstalled) {
    return GestureDetector(
      onTap: () => _navigateToDetail(tool),
      child: Container(
        decoration: BoxDecoration(
          color: FlipperColors.surface,
          border: Border.all(color: FlipperColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Area
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  border: Border(
                    bottom: BorderSide(color: FlipperColors.border, width: 1.5),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border.all(color: FlipperColors.primary, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(tool.category),
                          size: 32,
                          color: FlipperColors.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(
                          _favoriteIds.contains(tool.id) ? Icons.star : Icons.star_border,
                          color: FlipperColors.primary,
                          size: 20,
                        ),
                        onPressed: () => _toggleFavorite(tool.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Info Area
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tool Name
                    Text(
                      tool.name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: FlipperColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Category Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: FlipperColors.primary, width: 1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        tool.category.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: FlipperColors.primary,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Version
                    Text(
                      'v${tool.version}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: FlipperColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: isInstalled
                          ? OutlinedButton(
                              onPressed: () {
                                widget.appManagementService.uninstallTool(tool.id);
                                setState(() {});
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                side: const BorderSide(color: FlipperColors.error, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline, size: 12, color: FlipperColors.error),
                                  SizedBox(width: 4),
                                  Text(
                                    'REMOVE',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: FlipperColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () => _navigateToDetail(tool),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FlipperColors.primary,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'INSTALL',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        title: const Text("MARKETPLACE"),
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
                      builder: (context) => ToolUpdatesScreen(
                        updatableTools: updatableTools,
                        wifiService: widget.wifiService,
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: _filterTools,
              decoration: InputDecoration(
                hintText: 'SEARCH TOOLS...',
                hintStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                prefixIcon: const Icon(Icons.search, color: FlipperColors.primary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: FlipperColors.border),
                ),
                filled: true,
                fillColor: FlipperColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          
          // Category Chips
          if (!_isLoading && _allTools.isNotEmpty)
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _getCategories().map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : FlipperColors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) => _filterByCategory(category),
                      backgroundColor: FlipperColors.surface,
                      selectedColor: FlipperColors.primary,
                      checkmarkColor: Colors.black,
                      side: BorderSide(
                        color: isSelected ? FlipperColors.primary : FlipperColors.border,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Tools Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: FlipperColors.primary))
                : _filteredTools.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 80, color: FlipperColors.textDisabled),
                            const SizedBox(height: 16),
                            const Text(
                              "NO TOOLS FOUND",
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
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredTools.length,
                        itemBuilder: (context, index) {
                          final tool = _filteredTools[index];
                          final isInstalled = widget.appManagementService.isInstalled(tool.id);
                          return _buildToolCard(tool, isInstalled);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}