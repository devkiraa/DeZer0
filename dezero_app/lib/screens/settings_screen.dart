import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/flipper_theme.dart';
import '../services/app_management_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoConnect = false;
  bool _notifications = true;
  bool _darkMode = true;
  String _lastConnectedIP = '';
  String _appVersion = '';
  String _buildNumber = '';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _autoConnect = prefs.getBool('auto_connect') ?? false;
        _notifications = prefs.getBool('notifications') ?? true;
        _darkMode = prefs.getBool('dark_mode') ?? true;
        _lastConnectedIP = prefs.getString('last_connected_ip') ?? '';
      });
    }
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _clearCache() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlipperColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: FlipperColors.primary, width: 1),
        ),
        title: const Text(
          'CLEAR CACHE',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: FlipperColors.textPrimary,
          ),
        ),
        content: const Text(
          'This will clear all cached data. Continue?',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: FlipperColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
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
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlipperColors.primary,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'CLEAR',
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

    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _loadSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cache cleared successfully',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: FlipperColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _resetApp() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlipperColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: FlipperColors.error, width: 1),
        ),
        title: const Text(
          'RESET APP',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: FlipperColors.error,
          ),
        ),
        content: const Text(
          'This will delete all data including installed apps and settings. This action cannot be undone!',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: FlipperColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
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
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlipperColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'RESET',
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

    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await AppManagementService.instance.clearAllTools();
      await _loadSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'App reset successfully',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: FlipperColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: FlipperColors.primary,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: FlipperColors.surface,
            border: Border.all(color: FlipperColors.primary.withOpacity(0.3), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: FlipperColors.primary, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: FlipperColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: FlipperColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: FlipperColors.primary,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? FlipperColors.primary, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: iconColor ?? FlipperColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          color: FlipperColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: FlipperColors.textDisabled),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: FlipperColors.primary, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: FlipperColors.textPrimary,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: FlipperColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSection(
            'PREFERENCES',
            [
              _buildSwitchTile(
                title: 'Auto Connect',
                subtitle: 'Connect to last device on startup',
                value: _autoConnect,
                icon: Icons.link,
                onChanged: (value) {
                  setState(() => _autoConnect = value);
                  _saveSetting('auto_connect', value);
                },
              ),
              const Divider(height: 1, color: FlipperColors.border),
              _buildSwitchTile(
                title: 'Notifications',
                subtitle: 'Show alerts and updates',
                value: _notifications,
                icon: Icons.notifications_outlined,
                onChanged: (value) {
                  setState(() => _notifications = value);
                  _saveSetting('notifications', value);
                },
              ),
              const Divider(height: 1, color: FlipperColors.border),
              _buildSwitchTile(
                title: 'Dark Mode',
                subtitle: 'Use dark theme (restart required)',
                value: _darkMode,
                icon: Icons.dark_mode_outlined,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                  _saveSetting('dark_mode', value);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'CONNECTION',
            [
              _buildInfoTile(
                title: 'Last Connected IP',
                value: _lastConnectedIP.isEmpty ? 'None' : _lastConnectedIP,
                icon: Icons.router,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'DATA & STORAGE',
            [
              _buildActionTile(
                title: 'Clear Cache',
                subtitle: 'Remove temporary files',
                icon: Icons.cleaning_services_outlined,
                onTap: _clearCache,
              ),
              const Divider(height: 1, color: FlipperColors.border),
              _buildActionTile(
                title: 'Reset App',
                subtitle: 'Delete all data and settings',
                icon: Icons.delete_forever,
                iconColor: FlipperColors.error,
                onTap: _resetApp,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'ABOUT',
            [
              _buildInfoTile(
                title: 'Version',
                value: _appVersion.isEmpty ? '1.0.0' : _appVersion,
                icon: Icons.info_outline,
              ),
              const Divider(height: 1, color: FlipperColors.border),
              _buildInfoTile(
                title: 'Build Number',
                value: _buildNumber.isEmpty ? '1' : _buildNumber,
                icon: Icons.build_outlined,
              ),
              const Divider(height: 1, color: FlipperColors.border),
              _buildActionTile(
                title: 'GitHub Repository',
                subtitle: 'devkiraa/DeZer0',
                icon: Icons.code,
                onTap: () {
                  // Open GitHub repository
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Made with ❤️ by devkiraa',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: FlipperColors.textSecondary.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
