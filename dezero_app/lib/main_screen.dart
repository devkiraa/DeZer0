import 'package:flutter/material.dart';
import 'services/wifi_service.dart';
import 'services/app_management_service.dart';
import 'screens/device_screen.dart';
import 'screens/apps_screen.dart';
import 'screens/tools_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final WifiService _wifiService = WifiService();
  final AppManagementService _appManagementService = AppManagementService();
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      DeviceScreen(wifiService: _wifiService),
      AppsScreen(
        appManagementService: _appManagementService,
        wifiService: _wifiService,
      ),
      ToolsScreen(
        wifiService: _wifiService,
        appManagementService: _appManagementService,
      ),
    ];
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.wifi_tethering), label: 'Device'),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Apps'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Tools'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}