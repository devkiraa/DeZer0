import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tool_package.dart';

class AppManagementService {
  static final AppManagementService _instance = AppManagementService._internal();
  factory AppManagementService() => _instance;
  AppManagementService._internal();

  final ValueNotifier<Map<String, String>> installedTools = ValueNotifier({});
  static const _storageKey = 'installed_tools';
  String _appDocsPath = '';

  // This must be called once when the app starts
  Future<void> init() async {
    // Get the app's private documents directory path
    final directory = await getApplicationDocumentsDirectory();
    _appDocsPath = directory.path;
    
    // Load the list of installed tools from shared_preferences
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

  // Save the downloaded script to a file in the correct directory
  Future<void> installTool(ToolPackage tool, Uint8List scriptBytes) async {
    if (_appDocsPath.isEmpty) await init(); // Ensure path is initialized

    // FIX: Construct the full, correct path inside the app's directory
    final file = File('$_appDocsPath/${tool.id}.py');
    await file.writeAsBytes(scriptBytes);
    print("Installed ${tool.name} to ${file.path}");

    if (!isInstalled(tool.id) || getInstalledVersion(tool.id) != tool.version) {
      final currentTools = Map<String, String>.from(installedTools.value);
      currentTools[tool.id] = tool.version;
      installedTools.value = currentTools;
      await _save();
    }
  }

  // Read the script from the correct file path
  Future<String?> getScript(String toolId) async {
    if (!isInstalled(toolId)) return null;
    if (_appDocsPath.isEmpty) await init();

    try {
      final file = File('$_appDocsPath/$toolId.py');
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  // Delete the script file from the correct path
  Future<void> uninstallTool(String toolId) async {
    if (isInstalled(toolId)) {
      if (_appDocsPath.isEmpty) await init();
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