class ToolPinRequirement {
  final String name;
  final String function;
  final String mode;
  final bool required;
  final String? description;

  ToolPinRequirement({
    required this.name,
    required this.function,
    required this.mode,
    required this.required,
    this.description,
  });

  factory ToolPinRequirement.fromJson(Map<String, dynamic> json) {
    return ToolPinRequirement(
      name: json['name'] ?? '',
      function: json['function'] ?? 'Signal',
      mode: json['mode'] ?? 'output',
      required: json['required'] ?? true,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'function': function,
      'mode': mode,
      'required': required,
      if (description != null) 'description': description,
    };
  }
}

class ToolPackage {
  final String id;
  final String name;
  final String author;
  final String version;
  final String description;
  final String category;
  final String size;
  final String scriptFilename;
  final String changelog;
  final List<ToolPinRequirement> pinRequirements;

  ToolPackage({
    required this.id,
    required this.name,
    required this.author,
    required this.version,
    required this.description,
    required this.category,
    required this.size,
    required this.scriptFilename,
    required this.changelog,
    this.pinRequirements = const [],
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
      changelog: json['changelog'] ?? 'No changelog available.',
      pinRequirements: (json['pin_requirements'] as List<dynamic>?)
              ?.map((e) => ToolPinRequirement.fromJson(e))
              .toList() ??
          [],
    );
  }
}