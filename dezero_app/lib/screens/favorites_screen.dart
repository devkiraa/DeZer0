import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tool_package.dart';
import '../services/marketplace_service.dart';
import '../services/wifi_service.dart';
import '../theme/flipper_theme.dart';
import 'run_tool_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final WifiService wifiService;
  
  const FavoritesScreen({
    super.key,
    required this.wifiService,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  List<ToolPackage> _favoriteTools = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final favoritesList = prefs.getStringList('favorite_tools') ?? [];
    _favoriteIds = favoritesList.toSet();

    if (_favoriteIds.isNotEmpty) {
      final allTools = await _marketplaceService.fetchTools();
      _favoriteTools = allTools.where((tool) => _favoriteIds.contains(tool.id)).toList();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite(String toolId) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_favoriteIds.contains(toolId)) {
      _favoriteIds.remove(toolId);
    } else {
      _favoriteIds.add(toolId);
    }
    
    await prefs.setStringList('favorite_tools', _favoriteIds.toList());
    await _loadFavorites();
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

  Widget _buildFavoriteCard(ToolPackage tool) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: FlipperColors.surface,
        border: Border.all(color: FlipperColors.primary.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: FlipperColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(tool.category),
            color: FlipperColors.primary,
            size: 28,
          ),
        ),
        title: Text(
          tool.name,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: FlipperColors.textPrimary,
          ),
        ),
        subtitle: Text(
          tool.category.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: FlipperColors.primary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _navigateToRunScreen(tool),
              icon: const Icon(Icons.play_arrow, color: FlipperColors.primary),
              style: IconButton.styleFrom(
                backgroundColor: FlipperColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _toggleFavorite(tool.id),
              icon: const Icon(Icons.star, color: FlipperColors.primary),
              style: IconButton.styleFrom(
                backgroundColor: FlipperColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        onTap: () => _navigateToRunScreen(tool),
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
        title: const Text('FAVORITES'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FlipperColors.primary))
          : _favoriteTools.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_border, size: 80, color: FlipperColors.textDisabled),
                      const SizedBox(height: 16),
                      const Text(
                        'NO FAVORITES YET',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: FlipperColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Star tools from the marketplace\nto add them here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: FlipperColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _favoriteTools.length,
                  itemBuilder: (context, index) {
                    return _buildFavoriteCard(_favoriteTools[index]);
                  },
                ),
    );
  }
}
