import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/flipper_theme.dart';

class ConnectionPreset {
  final String id;
  String nickname;
  String ipAddress;
  DateTime lastConnected;

  ConnectionPreset({
    required this.id,
    required this.nickname,
    required this.ipAddress,
    required this.lastConnected,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'ipAddress': ipAddress,
        'lastConnected': lastConnected.toIso8601String(),
      };

  factory ConnectionPreset.fromJson(Map<String, dynamic> json) => ConnectionPreset(
        id: json['id'],
        nickname: json['nickname'],
        ipAddress: json['ipAddress'],
        lastConnected: DateTime.parse(json['lastConnected']),
      );
}

class ConnectionPresetsScreen extends StatefulWidget {
  final Function(String) onConnect;

  const ConnectionPresetsScreen({
    super.key,
    required this.onConnect,
  });

  @override
  State<ConnectionPresetsScreen> createState() => _ConnectionPresetsScreenState();
}

class _ConnectionPresetsScreenState extends State<ConnectionPresetsScreen> {
  List<ConnectionPreset> _presets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final presetsJson = prefs.getStringList('connection_presets') ?? [];
    
    _presets = presetsJson.map((json) => ConnectionPreset.fromJson(jsonDecode(json))).toList();
    _presets.sort((a, b) => b.lastConnected.compareTo(a.lastConnected));
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePresets() async {
    final prefs = await SharedPreferences.getInstance();
    final presetsJson = _presets.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('connection_presets', presetsJson);
  }

  Future<void> _addPreset() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddPresetDialog(),
    );

    if (result != null) {
      final preset = ConnectionPreset(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nickname: result['nickname']!,
        ipAddress: result['ipAddress']!,
        lastConnected: DateTime.now(),
      );

      setState(() => _presets.insert(0, preset));
      await _savePresets();
    }
  }

  Future<void> _editPreset(ConnectionPreset preset) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddPresetDialog(
        initialNickname: preset.nickname,
        initialIp: preset.ipAddress,
      ),
    );

    if (result != null) {
      setState(() {
        preset.nickname = result['nickname']!;
        preset.ipAddress = result['ipAddress']!;
      });
      await _savePresets();
    }
  }

  Future<void> _deletePreset(ConnectionPreset preset) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlipperColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: FlipperColors.error, width: 1),
        ),
        title: const Text(
          'DELETE PRESET',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: FlipperColors.error,
          ),
        ),
        content: Text(
          'Delete "${preset.nickname}"?',
          style: const TextStyle(
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

    if (result == true) {
      setState(() => _presets.remove(preset));
      await _savePresets();
    }
  }

  void _connectToPreset(ConnectionPreset preset) {
    preset.lastConnected = DateTime.now();
    _savePresets();
    Navigator.pop(context);
    widget.onConnect(preset.ipAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONNECTION PRESETS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: FlipperColors.primary),
            onPressed: _addPreset,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FlipperColors.primary))
          : _presets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.router, size: 80, color: FlipperColors.textDisabled),
                      const SizedBox(height: 16),
                      const Text(
                        'NO SAVED CONNECTIONS',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: FlipperColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add ESP32 devices for quick access',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: FlipperColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addPreset,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'ADD DEVICE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlipperColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _presets.length,
                  itemBuilder: (context, index) {
                    final preset = _presets[index];
                    final isRecent = DateTime.now().difference(preset.lastConnected).inHours < 24;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: FlipperColors.surface,
                        border: Border.all(
                          color: isRecent 
                              ? FlipperColors.primary.withOpacity(0.5)
                              : FlipperColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isRecent
                                ? FlipperColors.primary.withOpacity(0.2)
                                : FlipperColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.router,
                            color: FlipperColors.primary,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          preset.nickname,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: FlipperColors.textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              preset.ipAddress,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: FlipperColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatLastConnected(preset.lastConnected),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: FlipperColors.textSecondary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: FlipperColors.textSecondary),
                              onPressed: () => _editPreset(preset),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: FlipperColors.error),
                              onPressed: () => _deletePreset(preset),
                            ),
                          ],
                        ),
                        onTap: () => _connectToPreset(preset),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatLastConnected(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _AddPresetDialog extends StatefulWidget {
  final String? initialNickname;
  final String? initialIp;

  const _AddPresetDialog({this.initialNickname, this.initialIp});

  @override
  State<_AddPresetDialog> createState() => _AddPresetDialogState();
}

class _AddPresetDialogState extends State<_AddPresetDialog> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.initialNickname ?? '');
    _ipController = TextEditingController(text: widget.initialIp ?? '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: FlipperColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: FlipperColors.primary, width: 1),
      ),
      title: Text(
        widget.initialNickname == null ? 'ADD DEVICE' : 'EDIT DEVICE',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: FlipperColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nicknameController,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: FlipperColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Device Nickname',
              labelStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: FlipperColors.textSecondary,
              ),
              hintText: 'e.g., Workshop ESP32',
              hintStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: FlipperColors.textSecondary.withOpacity(0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: FlipperColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: FlipperColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ipController,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: FlipperColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'IP Address',
              labelStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: FlipperColors.textSecondary,
              ),
              hintText: 'e.g., 192.168.1.100',
              hintStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: FlipperColors.textSecondary.withOpacity(0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: FlipperColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: FlipperColors.primary, width: 2),
              ),
            ),
          ),
        ],
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
            if (_nicknameController.text.isNotEmpty && _ipController.text.isNotEmpty) {
              Navigator.pop(context, {
                'nickname': _nicknameController.text,
                'ipAddress': _ipController.text,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: FlipperColors.primary,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'SAVE',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
