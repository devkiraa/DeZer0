import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/flipper_theme.dart';
import '../services/update_service.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final UpdateService _updateService = UpdateService();
  bool _isLoading = true;
  bool _isCheckingUpdate = false;
  Map<String, dynamic>? _updateInfo;
  List<Map<String, dynamic>> _allReleases = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
    _loadAllReleases();
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
      _error = null;
    });

    try {
      final updateInfo = await _updateService.getUpdateInfo();
      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
          _isCheckingUpdate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to check for updates';
          _isCheckingUpdate = false;
        });
      }
    }
  }

  Future<void> _loadAllReleases() async {
    try {
      final releases = await _updateService.getAllReleases();
      if (mounted) {
        setState(() {
          _allReleases = releases;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load releases';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlipperColors.background,
      appBar: AppBar(
        backgroundColor: FlipperColors.surface,
        elevation: 0,
        title: const Text(
          'APP UPDATES',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: FlipperColors.textPrimary,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FlipperColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _checkForUpdates();
          await _loadAllReleases();
        },
        color: FlipperColors.primary,
        backgroundColor: FlipperColors.surface,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: FlipperColors.primary,
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Update Status Card
                  _buildUpdateStatusCard(),
                  const SizedBox(height: 24),
                  
                  // Releases Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'RELEASE HISTORY',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: FlipperColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (_allReleases.isEmpty && !_isLoading)
                    _buildEmptyState()
                  else
                    ..._allReleases.map((release) => _buildReleaseCard(release)),
                ],
              ),
      ),
    );
  }

  Widget _buildUpdateStatusCard() {
    if (_isCheckingUpdate) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: FlipperColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FlipperColors.border, width: 1),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: FlipperColors.primary,
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Checking for updates...',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: FlipperColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: FlipperColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade800, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkForUpdates,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlipperColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_updateInfo != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: FlipperColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FlipperColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: FlipperColors.primary.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FlipperColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: FlipperColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'UPDATE AVAILABLE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: FlipperColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Current: ${_updateInfo!['current_version']}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: FlipperColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward, size: 16, color: FlipperColors.primary),
                const SizedBox(width: 16),
                Text(
                  'Latest: ${_updateInfo!['latest_version']}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: FlipperColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final url = _updateInfo!['download_url'] ?? _updateInfo!['html_url'];
                  if (url != null) {
                    _launchUrl(url);
                  }
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'DOWNLOAD UPDATE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FlipperColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Up to date
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FlipperColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade800, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green.shade400,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOU\'RE UP TO DATE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: FlipperColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Running latest version',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: FlipperColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseCard(Map<String, dynamic> release) {
    final tagName = release['tag_name'] as String? ?? '';
    final name = release['name'] as String? ?? 'Unnamed Release';
    final body = release['body'] as String? ?? '';
    final publishedAt = release['published_at'] as String? ?? '';
    final htmlUrl = release['html_url'] as String? ?? '';
    final isPrerelease = release['prerelease'] as bool? ?? false;
    
    DateTime? publishDate;
    try {
      publishDate = DateTime.parse(publishedAt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlipperColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrerelease 
              ? FlipperColors.primary.withOpacity(0.3)
              : FlipperColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FlipperColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: FlipperColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  tagName,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: FlipperColors.primary,
                  ),
                ),
              ),
              if (isPrerelease) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'PRE-RELEASE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (publishDate != null)
                Text(
                  '${publishDate.day}/${publishDate.month}/${publishDate.year}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: FlipperColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: FlipperColors.textPrimary,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              body.length > 150 ? '${body.substring(0, 150)}...' : body,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: FlipperColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _launchUrl(htmlUrl),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text(
                'VIEW ON GITHUB',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: FlipperColors.primary, width: 1),
                foregroundColor: FlipperColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: FlipperColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'NO RELEASES FOUND',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: FlipperColors.textSecondary.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for updates',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: FlipperColors.textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
