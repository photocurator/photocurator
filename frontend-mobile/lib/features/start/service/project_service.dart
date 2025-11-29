import 'package:dio/dio.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Project {
  final String id;
  final String userId;
  final String projectName;
  final String? description; // Added description
  final String? coverImageId;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  Project({
    required this.id,
    required this.userId,
    required this.projectName,
    this.description, // Added description
    this.coverImageId,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      userId: json['userId'],
      projectName: json['projectName'],
      description: json['description'], // Added description
      coverImageId: json['coverImageId'],
      isArchived: json['isArchived'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      archivedAt: json['archivedAt'] != null ? DateTime.parse(json['archivedAt']) : null,
    );
  }
}

class ProjectService {
  late Dio _dio;
  String? _baseUrl;

  ProjectService() {
    _dio = FlutterBetterAuth.dioClient;
    _baseUrl = dotenv.env['API_BASE_URL'];
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      throw Exception('API_BASE_URL not found in .env file');
    }
    _dio.options.baseUrl = _baseUrl!;
  }

  Future<Project?> createProject(String projectName) async {
    try {
      final response = await _dio.post(
        '/projects',
        data: {
          'name': projectName,
        },
      );
      if (response.statusCode == 201) {
        print('Project created successfully');
        return Project.fromJson(response.data);
      } else {
        print('Failed to create project: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error creating project: $e');
      return null;
    }
  }
  Future<String?> uploadImages(String projectId, List<String> photoPaths) async {
    try {
      final formData = FormData();
      for (var path in photoPaths) {
        formData.files.add(MapEntry(
          'files',
          await MultipartFile.fromFile(path),
        ));
      }

      final response = await _dio.post(
        '/projects/$projectId/images',
        data: formData,
      );

      if (response.statusCode == 201) {
        return response.data['message'];
      } else {
        print('Failed to upload images: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading images: $e');
      return null;
    }
  }

  Future<List<Project>> getProjects() async {
    try {
      final response = await _dio.get('/projects');
      if (response.statusCode == 200) {
        final List<dynamic> projectJsonList = response.data;
        return projectJsonList.map((json) => Project.fromJson(json)).toList();
      } else {
        print('Failed to get projects: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting projects: $e');
      return [];
    }
  }
}
