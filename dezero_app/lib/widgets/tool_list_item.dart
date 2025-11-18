import 'package:flutter/material.dart';
import '../models/tool_package.dart';
import '../theme/flipper_theme.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      decoration: FlipperDecorations.container(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with Flipper style
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: FlipperColors.surfaceLight,
                  border: Border.all(color: FlipperColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.extension,
                  size: 28,
                  color: FlipperColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Tool info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: FlipperColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v${tool.version} • ${tool.author}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: FlipperColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tool.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: FlipperColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Action button
              if (isInstalled)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: FlipperColors.error, width: 1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: FlipperColors.error,
                    onPressed: onUninstall,
                    tooltip: 'UNINSTALL',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: FlipperColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onInstall,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'INSTALL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}