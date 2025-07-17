import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tool_package.dart';

class AppManagementService {
  final ValueNotifier<Map<String, String>> installedTools = ValueNotifier({});
  static const _storageKey = 'installed_tools';
  String _appDocsPath = '';

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _appDocsPath = directory.path;
    
    final prefs = await SharedPreferences.getInstance();
    final String? savedToolsJson = prefs.getString(_storageKey);
    if (savedToolsJson != null) {
      final Map<String, dynamic> savedTools = json.decode(savedToolsJson);
      installedTools.value = savedTools.map((key, value) => MapEntry(key, value.toString()));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(installedTools.value));
  }
  
  bool isInstalled(String toolId) {
    return installedTools.value.containsKey(toolId);
  }
  
  String getInstalledVersion(String toolId) {
    return installedTools.value[toolId] ?? "";
  }

  Future<void> installTool(ToolPackage tool, Uint8List scriptBytes) async {
    if (!isInstalled(tool.id) || getInstalledVersion(tool.id) != tool.version) {
      final file = File('$_appDocsPath/${tool.id}.py');
      await file.writeAsBytes(scriptBytes);
      
      final currentTools = Map<String, String>.from(installedTools.value);
      currentTools[tool.id] = tool.version;
      installedTools.value = currentTools;
      await _save();
    }
  }

  Future<String?> getScript(String toolId) async {
    if (!isInstalled(toolId)) return null;
    try {
      final file = File('$_appDocsPath/$toolId.py');
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<void> uninstallTool(String toolId) async {
    if (isInstalled(toolId)) {
      try {
        final file = File('$_appDocsPath/$toolId.py');
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print("Error deleting script file: $e");
      }
      
      final currentTools = Map<String, String>.from(installedTools.value);
      currentTools.remove(toolId);
      installedTools.value = currentTools;
      await _save();
    }
  }
}