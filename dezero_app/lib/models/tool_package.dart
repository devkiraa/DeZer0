class ToolPackage {
  final String id;
  final String name;
  final String author;
  final String version;
  final String description;
  final String repo;
  final String assetFilename;
  final String category; // New
  final String size;     // New

  ToolPackage({
    required this.id,
    required this.name,
    required this.author,
    required this.version,
    required this.description,
    required this.repo,
    required this.assetFilename,
    required this.category,
    required this.size,
  });

  factory ToolPackage.fromJson(Map<String, dynamic> json) {
    return ToolPackage(
      id: json['id'],
      name: json['name'],
      author: json['author'],
      version: json['version'],
      description: json['description'],
      repo: json['repo'],
      assetFilename: json['asset_filename'],
      category: json['category'],
      size: json['size'],
    );
  }
}