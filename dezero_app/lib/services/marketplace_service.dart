import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/tool_package.dart';

class MarketplaceService {
  final String _indexUrl =
      'https://gist.githubusercontent.com/devkiraa/c1cba16be4b8cb1760bca8ffbe388a67/raw/tools.json';

  Future<List<ToolPackage>> fetchTools() async {
    try {
      final response = await http.get(
        Uri.parse(_indexUrl),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ToolPackage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tool index: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to fetch tools: $e');
    }
  }

  Future<String> fetchReleaseNotes(ToolPackage package) async {
    final url = 'https://api.github.com/repos/${package.repo}/releases/latest';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['body'] ?? 'No release notes found.';
      } else {
        return 'Could not load release notes.';
      }
    } catch (e) {
      return 'Error fetching release notes.';
    }
  }

  Future<Uint8List?> downloadToolWithProgress(
    ToolPackage package,
    void Function(double progress) onProgress,
  ) async {
    final downloadUrl =
        'https://github.com/${package.repo}/releases/latest/download/${package.assetFilename}';

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      final totalSize = response.contentLength;
      if (totalSize == null) {
        throw Exception("Cannot get file size.");
      }

      List<int> bytes = [];
      int receivedBytes = 0;

      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        final progress = receivedBytes / totalSize;
        onProgress(progress);
      }

      print("Download complete. Total size: $receivedBytes bytes.");
      return Uint8List.fromList(bytes);
    } catch (e) {
      print("Download failed: $e");
      return null;
    }
  }
}