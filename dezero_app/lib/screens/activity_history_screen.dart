import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/flipper_theme.dart';

class ActivityLog {
  final String id;
  final String type; // 'connection', 'tool_execution', 'error'
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isSuccess;

  ActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isSuccess,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'isSuccess': isSuccess,
      };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        id: json['id'],
        type: json['type'],
        title: json['title'],
        description: json['description'],
        timestamp: DateTime.parse(json['timestamp']),
        isSuccess: json['isSuccess'],
      );
}

class ActivityHistoryService {
  static const _maxLogs = 100;
  static const _storageKey = 'activity_history';

  static Future<void> addLog({
    required String type,
    required String title,
    required String description,
    required bool isSuccess,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList(_storageKey) ?? [];
    
    final log = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      description: description,
      timestamp: DateTime.now(),
      isSuccess: isSuccess,
    );

    logsJson.insert(0, jsonEncode(log.toJson()));
    
    // Keep only the last N logs
    if (logsJson.length > _maxLogs) {
      logsJson.removeRange(_maxLogs, logsJson.length);
    }

    await prefs.setStringList(_storageKey, logsJson);
  }

  static Future<List<ActivityLog>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = prefs.getStringList(_storageKey) ?? [];
    return logsJson.map((json) => ActivityLog.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<void> exportLogs() async {
    // For future implementation with file export
  }
}

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  List<ActivityLog> _logs = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'connection', 'tool_execution', 'error'

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await ActivityHistoryService.getLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearLogs() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlipperColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: FlipperColors.error, width: 1),
        ),
        title: const Text(
          'CLEAR HISTORY',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: FlipperColors.error,
          ),
        ),
        content: const Text(
          'This will delete all activity logs. Continue?',
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
      await ActivityHistoryService.clearLogs();
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'History cleared',
              style: TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: FlipperColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<ActivityLog> get _filteredLogs {
    if (_filter == 'all') return _logs;
    return _logs.where((log) => log.type == _filter).toList();
  }

  IconData _getLogIcon(String type) {
    switch (type) {
      case 'connection':
        return Icons.link;
      case 'tool_execution':
        return Icons.play_arrow;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getLogColor(ActivityLog log) {
    if (!log.isSuccess) return FlipperColors.error;
    switch (log.type) {
      case 'connection':
        return FlipperColors.primary;
      case 'tool_execution':
        return FlipperColors.success;
      default:
        return FlipperColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ACTIVITY HISTORY'),
        actions: [
          if (_logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: FlipperColors.error),
              onPressed: _clearLogs,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('CONNECTIONS', 'connection'),
                  const SizedBox(width: 8),
                  _buildFilterChip('EXECUTIONS', 'tool_execution'),
                  const SizedBox(width: 8),
                  _buildFilterChip('ERRORS', 'error'),
                ],
              ),
            ),
          ),
          
          // Logs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: FlipperColors.primary))
                : _filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history, size: 80, color: FlipperColors.textDisabled),
                            const SizedBox(height: 16),
                            const Text(
                              'NO ACTIVITY YET',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: FlipperColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _filter == 'all'
                                  ? 'Your activity will appear here'
                                  : 'No ${_filter.replaceAll('_', ' ')} logs found',
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = _filteredLogs[index];
                          final color = _getLogColor(log);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: FlipperColors.surface,
                              border: Border.all(
                                color: color.withOpacity(0.3),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getLogIcon(log.type),
                                  color: color,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                log.title,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: FlipperColors.textPrimary,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    log.description,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: FlipperColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(log.timestamp),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      color: FlipperColors.textSecondary.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                log.isSuccess ? Icons.check_circle : Icons.cancel,
                                color: log.isSuccess ? FlipperColors.success : FlipperColors.error,
                                size: 20,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FlipperColors.primary : FlipperColors.surface,
          border: Border.all(
            color: isSelected ? FlipperColors.primary : FlipperColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : FlipperColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
