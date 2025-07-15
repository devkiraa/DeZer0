import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/tool_package.dart';
import '../services/app_management_service.dart';
import '../services/marketplace_service.dart';

enum DownloadState { none, downloading, complete, error }

class ToolDetailScreen extends StatefulWidget {
  final ToolPackage tool;

  const ToolDetailScreen({
    super.key,
    required this.tool,
  });

  @override
  State<ToolDetailScreen> createState() => _ToolDetailScreenState();
}

class _ToolDetailScreenState extends State<ToolDetailScreen> {
  final AppManagementService _appManagementService = AppManagementService();
  final MarketplaceService _marketplaceService = MarketplaceService();
  
  DownloadState _downloadState = DownloadState.none;
  double _progress = 0.0;
  String _releaseNotes = "Loading changelog...";
  late bool _isInstalled;

  @override
  void initState() {
    super.initState();
    _isInstalled = _appManagementService.isInstalled(widget.tool.id);
    _fetchNotes();
    _appManagementService.installedTools.addListener(_onInstallStatusChanged);
  }

  @override
  void dispose() {
    _appManagementService.installedTools.removeListener(_onInstallStatusChanged);
    super.dispose();
  }
  
  void _onInstallStatusChanged() {
    final newStatus = _appManagementService.isInstalled(widget.tool.id);
    if (newStatus != _isInstalled && mounted) {
      setState(() {
        _isInstalled = newStatus;
      });
    }
  }

  Future<void> _fetchNotes() async {
    final notes = await _marketplaceService.fetchReleaseNotes(widget.tool);
    if (mounted) {
      setState(() {
        _releaseNotes = notes;
      });
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloadState = DownloadState.downloading;
      _progress = 0.0;
    });

    final fileBytes = await _marketplaceService.downloadToolWithProgress(
      widget.tool, (p) {
        if (mounted) setState(() => _progress = p);
      });

    if(mounted) {
      setState(() {
        _downloadState = (fileBytes != null) ? DownloadState.complete : DownloadState.error;
        if (fileBytes != null) {
          _appManagementService.installTool(widget.tool);
        }
      });
    }
  }

  void _uninstall() {
    _appManagementService.uninstallTool(widget.tool.id);
    setState(() {
      _downloadState = DownloadState.none;
    });
  }

  Future<void> _launchRepoUrl() async {
    final url = Uri.parse('https://github.com/${widget.tool.repo}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open repository link."))
        );
      }
    }
  }

  Widget _buildInstallButton() {
    if (_isInstalled) {
      return OutlinedButton(
        onPressed: _uninstall,
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        child: const Text("Uninstall"),
      );
    }

    switch (_downloadState) {
      case DownloadState.downloading:
        return SizedBox(
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              LinearProgressIndicator(value: _progress, minHeight: 50, borderRadius: BorderRadius.circular(25)),
              Text("${(_progress * 100).toStringAsFixed(0)}%"),
            ],
          ),
        );
      case DownloadState.complete:
        return const FilledButton(onPressed: null, child: Text("Installed"));
      case DownloadState.error:
         return FilledButton.icon(onPressed: _startDownload, icon: const Icon(Icons.error), label: const Text("Retry"));
      default:
        return FilledButton(onPressed: _startDownload, child: const Text("Install"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tool.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.extension, size: 60, color: Theme.of(context).primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.tool.name, style: Theme.of(context).textTheme.headlineSmall),
                      Text(widget.tool.category, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip("Version", widget.tool.version),
                _buildInfoChip("Size", widget.tool.size),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: _buildInstallButton()),
            const SizedBox(height: 24),
            Text("Description", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Text(widget.tool.description),
            const SizedBox(height: 24),
            Text("Changelog", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            _releaseNotes == "Loading changelog..." 
              ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
              : Text(_releaseNotes),
            const SizedBox(height: 24),
            Text("Developer", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.github),
              title: const Text("Repository"),
              onTap: _launchRepoUrl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}