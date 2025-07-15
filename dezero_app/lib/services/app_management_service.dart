import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tool_package.dart';

class AppManagementService {
  // --- Singleton Setup ---
  static final AppManagementService _instance = AppManagementService._internal();
  factory AppManagementService() => _instance;
  AppManagementService._internal();

  // --- State ---
  final ValueNotifier<Map<String, String>> installedTools = ValueNotifier({});
  static const _storageKey = 'installed_tools';

  // --- Methods ---

  // Load the list from device storage when the app starts
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedToolsJson = prefs.getString(_storageKey);
    if (savedToolsJson != null) {
      final Map<String, dynamic> savedTools = json.decode(savedToolsJson);
      installedTools.value = savedTools.map((key, value) => MapEntry(key, value.toString()));
    }
  }

  // Save the list to device storage
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

  void installTool(ToolPackage tool) {
    if (!isInstalled(tool.id)) {
      final currentTools = Map<String, String>.from(installedTools.value);
      currentTools[tool.id] = tool.version;
      installedTools.value = currentTools;
      _save(); // Save after installing
    }
  }

  void uninstallTool(String toolId) {
    if (isInstalled(toolId)) {
      final currentTools = Map<String, String>.from(installedTools.value);
      currentTools.remove(toolId);
      installedTools.value = currentTools;
      _save(); // Save after uninstalling
    }
  }
}