import 'package:flutter/material.dart';
import '../models/tool_package.dart';

// This widget will represent a single card in our lists
class ToolListItem extends StatelessWidget {
  final ToolPackage tool;
  final bool isInstalled;
  final VoidCallback onInstall;
  final VoidCallback onUninstall;
  final VoidCallback onRun;
  final VoidCallback onTap;

  const ToolListItem({
    super.key,
    required this.tool,
    required this.isInstalled,
    required this.onInstall,
    required this.onUninstall,
    required this.onRun,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.extension, size: 40, color: theme.primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tool.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text("v${tool.version} by ${tool.author}", style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text(tool.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Conditionally show Install or Run/Uninstall buttons
              if (isInstalled)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: onUninstall,
                  tooltip: "Uninstall",
                )
              else
                FilledButton(
                  onPressed: onInstall,
                  child: const Text("Install"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}