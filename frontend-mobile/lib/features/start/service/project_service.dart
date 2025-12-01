import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;

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

  String? get coverImageUrl {
    if (coverImageId == null || ProjectService.baseUrl == null) {
      return null;
    }
    return '${ProjectService.baseUrl}/images/$coverImageId/file';
  }
}

class ProjectService {
  late Dio _dio;
  static String? baseUrl;

  ProjectService() {
    _dio = FlutterBetterAuth.dioClient;
    baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('API_BASE_URL not found in .env file');
    }
  }

  Future<Project?> createProject(String projectName) async {
    try {
      final response = await _dio.post(
        '${ProjectService.baseUrl}/projects',
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
      if (photoPaths.isEmpty) {
        throw Exception('No photos provided for upload');
      }

      final files = await Future.wait(photoPaths.map((photoPath) async {
        final fileName = path.basename(photoPath);
        return await MultipartFile.fromFile(photoPath, filename: fileName);
      }));

      final formData = FormData();
      for (final file in files) {
        // 서버가 files[] 배열을 기대하므로 키를 files[]로 명시
        formData.files.add(MapEntry('files[]', file));
      }

      final response = await _dio.post(
        '${ProjectService.baseUrl}/projects/$projectId/images',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 202) {
        // 업로드 성공 시 프로젝트 분석 트리거
        try {
          await analyzeProject(projectId);
        } catch (e) {
          print('Failed to trigger project analyze: $e');
        }
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
      final response = await _dio.get('${ProjectService.baseUrl}/projects');
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

  Future<bool> analyzeProject(String projectId, {String jobType = 'FULL_SCAN'}) async {
    try {
      final response = await _dio.post(
        '${ProjectService.baseUrl}/projects/$projectId/analyze',
        data: {'jobType': jobType},
      );
      return response.statusCode == 200 || response.statusCode == 202;
    } catch (e) {
      print('Error analyzing project $projectId: $e');
      return false;
    }
  }

  Future<Uint8List?> getImage(String imageUrl) async {
    try {
      final response = await _dio.get<Uint8List>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Failed to get image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting image: $e');
      return null;
    }
  }
}
