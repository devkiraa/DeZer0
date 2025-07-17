import 'package:flutter/material.dart';
import '../models/tool_package.dart';
import '../services/app_management_service.dart';
import '../services/wifi_service.dart';
import '../widgets/tool_list_item.dart';
import 'tool_detail_screen.dart';

class UpdatesScreen extends StatelessWidget {
  final List<ToolPackage> updatableTools;
  final AppManagementService appManagementService;
  final WifiService wifiService; // FIX: Accept the WifiService

  const UpdatesScreen({
    super.key,
    required this.updatableTools,
    required this.appManagementService,
    required this.wifiService, // FIX: Accept the WifiService
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Updates"),
      ),
      body: updatableTools.isEmpty
          ? const Center(child: Text("All installed apps are up to date."))
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: updatableTools.length,
              itemBuilder: (context, index) {
                final tool = updatableTools[index];
                return ToolListItem(
                  tool: tool,
                  isInstalled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ToolDetailScreen(
                          tool: tool,
                          // FIX: Pass both required services
                          appManagementService: appManagementService,
                          wifiService: wifiService,
                        ),
                      ),
                    );
                  },
                  onInstall: () {},
                  onUninstall: () => appManagementService.uninstallTool(tool.id),
                  onRun: () {},
                );
              },
            ),
    );
  }
}