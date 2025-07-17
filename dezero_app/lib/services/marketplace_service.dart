import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/tool_package.dart';

class MarketplaceService {
  // Updated to use your new repository
  final String _repoOwner = "devkiraa";
  final String _repoName = "DeZer0-Tools";

  late final String _repoContentsUrl;
  late final String _rawFileUrlBase;

  MarketplaceService() {
    _repoContentsUrl = 'https://api.github.com/repos/$_repoOwner/$_repoName/contents/';
    _rawFileUrlBase = 'https://raw.githubusercontent.com/$_repoOwner/$_repoName/main/';
  }

  Future<List<ToolPackage>> fetchTools() async {
    print("Fetching tool list from: $_repoContentsUrl");
    try {
      final response = await http.get(Uri.parse(_repoContentsUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load tool repository index. Status: ${response.statusCode}');
      }

      final List<dynamic> contents = json.decode(response.body);
      final List<ToolPackage> tools = [];
      
      for (var item in contents) {
        if (item['type'] == 'dir') {
          final manifestUrl = '$_rawFileUrlBase${item['name']}/manifest.json';
          final manifestResponse = await http.get(Uri.parse(manifestUrl));
          if (manifestResponse.statusCode == 200) {
            final manifestData = json.decode(manifestResponse.body);
            tools.add(ToolPackage.fromJson(manifestData));
          }
        }
      }
      return tools;
    } catch (e) {
      print("Failed to fetch tools: $e");
      rethrow;
    }
  }

  Future<Uint8List?> downloadToolWithProgress(
    ToolPackage package,
    void Function(double progress) onProgress,
  ) async {
    final downloadUrl = '$_rawFileUrlBase${package.id}/${package.scriptFilename}';
    print("Downloading from: $downloadUrl");

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      final totalSize = response.contentLength;
      if (totalSize == null) throw Exception("Cannot get file size from server.");
      
      List<int> bytes = [];
      int receivedBytes = 0;

      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes / totalSize);
      }
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      print("Download failed: $e");
      return null;
    }
  }
}