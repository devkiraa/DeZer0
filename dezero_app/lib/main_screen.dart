import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/wifi_service.dart';
import 'services/hotspot_service.dart';
import 'services/app_management_service.dart';
import 'screens/device_screen.dart';
import 'screens/apps_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/activity_history_screen.dart';
import 'theme/flipper_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Create the service instances once
  final WifiService _wifiService = WifiService();
  final AppManagementService _appManagementService = AppManagementService.instance;
  late HotspotService _hotspotService;

  @override
  void initState() {
    super.initState();
    // Get the HotspotService from Provider
    _hotspotService = context.read<HotspotService>();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  List<Widget> get _widgetOptions => [
    DeviceScreen(
      wifiService: _wifiService,
      hotspotService: _hotspotService,
      onMenuPressed: _openDrawer,
    ),
    AppsScreen(
      appManagementService: _appManagementService,
      wifiService: _wifiService,
      onMenuPressed: _openDrawer,
    ),
    ToolsScreen(
      wifiService: _wifiService,
      appManagementService: _appManagementService,
      onMenuPressed: _openDrawer,
    ),
  ];

  @override
  void dispose() {
    _wifiService.disconnect();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: FlipperColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: FlipperColors.surface,
              border: Border(
                bottom: BorderSide(color: FlipperColors.primary, width: 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: FlipperColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.developer_board,
                    size: 32,
                    color: FlipperColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'DEZERO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: FlipperColors.primary,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.star,
            title: 'Favorites',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(
                    wifiService: _wifiService,
                  ),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.history,
            title: 'Activity History',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActivityHistoryScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.update,
            title: 'Updates',
            onTap: () {
              Navigator.pop(context);
              // Updates screen navigation
            },
          ),
          const Divider(color: FlipperColors.border, height: 1),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: FlipperColors.primary),
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: FlipperColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlipperColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: FlipperColors.primary, width: 1),
        ),
        title: const Text(
          'ABOUT DEZERO',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: FlipperColors.textPrimary,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESP32 Tool Platform',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: FlipperColors.textSecondary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'A comprehensive platform for running scripts and tools on ESP32 devices.',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: FlipperColors.textSecondary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Developer: devkiraa',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: FlipperColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlipperColors.primary,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'CLOSE',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: FlipperColors.primary.withOpacity(0.3), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.router),
              label: 'DEVICE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apps),
              label: 'APPS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.construction),
              label: 'TOOLS',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}