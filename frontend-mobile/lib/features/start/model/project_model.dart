class Project {
  final String projectId;
  final String name;
  final String? coverImageId;
  final DateTime createdAt;

  Project({
    required this.projectId,
    required this.name,
    this.coverImageId,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      coverImageId: json['coverImageId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'name': name,
      'coverImageId': coverImageId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

