import 'package:dio/dio.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;

class Project {
  // ... existing fields ...

  String? get coverImageUrl {
    if (coverImageId == null || ProjectService.baseUrl == null) {
      return null;
    }
    return '${ProjectService.baseUrl}/images/$coverImageId/file';
  }
}

class ProjectService {
  late Dio _dio;
  static String? baseUrl; // Made static

  ProjectService() {
    _dio = FlutterBetterAuth.dioClient;
    baseUrl = dotenv.env['API_BASE_URL']; // Initialize static field
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('API_BASE_URL not found in .env file');
    }
  }

  // ... existing methods ...