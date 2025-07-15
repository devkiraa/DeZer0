import 'package:flutter/material.dart';
import '../models/tool_package.dart';
import '../services/marketplace_service.dart';

// The different states our install button can be in
enum InstallButtonState { normal, downloading, installed }

class ToolCard extends StatefulWidget {
  final ToolPackage tool;
  final MarketplaceService marketplaceService;

  const ToolCard({
    super.key,
    required this.tool,
    required this.marketplaceService,
  });

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  InstallButtonState _installState = InstallButtonState.normal;
  double _progress = 0.0;

  Future<void> _installTool() async {
    // Change state to downloading and update the UI
    setState(() {
      _installState = InstallButtonState.downloading;
      _progress = 0.0; // Reset progress
    });

    // Start the download
    await widget.marketplaceService.downloadToolWithProgress(
      widget.tool,
      (p) {
        // Update the progress from the download stream
        setState(() {
          _progress = p;
        });
      },
    ).then((fileBytes) {
      // Once download is complete, update state to installed
      setState(() {
        _installState = fileBytes != null
            ? InstallButtonState.installed
            : InstallButtonState.normal; // Or handle error state
      });
    });
  }

  // This builds the button based on the current state
  Widget _buildInstallButton() {
    switch (_installState) {
      case InstallButtonState.downloading:
        return SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: _progress,
            strokeWidth: 3.0,
            backgroundColor: Colors.grey[300],
          ),
        );
      case InstallButtonState.installed:
        return const FilledButton(
          onPressed: null, // Disable button after install
          style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Colors.green)),
          child: Text("Installed"),
        );
      default: // Normal state
        return FilledButton(
          onPressed: _installTool,
          child: const Text("Install"),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.tool.name, style: Theme.of(context).textTheme.titleLarge),
            Text("by ${widget.tool.author} • ${widget.tool.version}", style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(widget.tool.description),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: _buildInstallButton(), // Use our new stateful button
            )
          ],
        ),
      ),
    );
  }
}