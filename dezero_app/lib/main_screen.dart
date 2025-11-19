import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/wifi_service.dart';
import 'services/hotspot_service.dart';
import 'services/app_management_service.dart';
import 'screens/device_screen.dart';
import 'screens/apps_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/hardware_config_screen.dart';
import 'screens/payloads_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/activity_history_screen.dart';
import 'screens/updates_screen.dart';
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

  String? _getDeviceIP() {
    // Try to get device IP from SharedPreferences synchronously
    // Note: This is a simplified approach. Consider using FutureBuilder in production.
    return null; // Will be fetched async in HardwareConfigScreen
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
    HardwareConfigScreen(
      deviceIP: _getDeviceIP(),
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
      child: Column(
        children: [
          // Modern header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FlipperColors.surface,
                  FlipperColors.background,
                ],
              ),
              border: const Border(
                bottom: BorderSide(color: FlipperColors.primary, width: 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with glow effect
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: FlipperColors.surface,
                    border: Border.all(color: FlipperColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: FlipperColors.primary.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.developer_board,
                    size: 36,
                    color: FlipperColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                // App name with version
                const Text(
                  'DEZERO',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: FlipperColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ESP32 TOOLKIT',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: FlipperColors.textSecondary.withOpacity(0.7),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    'QUICK ACCESS',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: FlipperColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _buildModernDrawerItem(
                  icon: Icons.star_rounded,
                  title: 'Favorites',
                  subtitle: 'Starred tools',
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
                _buildModernDrawerItem(
                  icon: Icons.widgets_rounded,
                  title: 'Payloads',
                  subtitle: 'Manage payloads',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PayloadsScreen(
                          wifiService: _wifiService,
                          onMenuPressed: _openDrawer,
                        ),
                      ),
                    );
                  },
                ),
                _buildModernDrawerItem(
                  icon: Icons.history_rounded,
                  title: 'Activity History',
                  subtitle: 'Recent actions',
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
                _buildModernDrawerItem(
                  icon: Icons.system_update_rounded,
                  title: 'Updates',
                  subtitle: 'Check for updates',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UpdatesScreen(),
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text(
                    'SYSTEM',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: FlipperColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _buildModernDrawerItem(
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  subtitle: 'App preferences',
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
                _buildModernDrawerItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  subtitle: 'App information',
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: FlipperColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'CONNECTED',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: FlipperColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: FlipperColors.textSecondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: FlipperColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: FlipperColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: FlipperColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: FlipperColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: FlipperColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: FlipperColors.textSecondary.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.developer_board),
              label: 'HARDWARE',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}