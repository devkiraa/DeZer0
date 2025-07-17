class ToolPackage {
  final String id;
  final String name;
  final String author;
  final String version;
  final String description;
  final String category;
  final String size;
  final String scriptFilename;
  final String changelog; // Added

  ToolPackage({
    required this.id,
    required this.name,
    required this.author,
    required this.version,
    required this.description,
    required this.category,
    required this.size,
    required this.scriptFilename,
    required this.changelog, // Added
  });

  factory ToolPackage.fromJson(Map<String, dynamic> json) {
    return ToolPackage(
      id: json['id'] ?? 'unknown',
      name: json['name'] ?? 'Unnamed Tool',
      author: json['author'] ?? 'Unknown Author',
      version: json['version'] ?? '0.0',
      description: json['description'] ?? 'No description.',
      category: json['category'] ?? 'General',
      size: json['size'] ?? '0 KB',
      scriptFilename: json['script_filename'] ?? '',
      changelog: json['changelog'] ?? 'No changelog available.', // Added
    );
  }
}