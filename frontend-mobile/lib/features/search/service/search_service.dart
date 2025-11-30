import 'package:dio/dio.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';

class SearchResultImage {
  final String id;
  final String url;
  final String thumbnailUrl;

  SearchResultImage({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
  });

  factory SearchResultImage.fromJson(Map<String, dynamic> json) {
    final imageJson = json['image'] as Map<String, dynamic>?;
    if (imageJson == null) {
      throw Exception('Image data is missing in the response');
    }

    final baseUrl = SearchService.baseUrl ?? dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('API_BASE_URL not found in .env file');
    }

    final String imageId = imageJson['id'];
    final String imageFileUrl = '$baseUrl/images/$imageId/file';

    return SearchResultImage(
      id: imageId,
      url: imageFileUrl,
      thumbnailUrl: imageFileUrl,
    );
  }
}

class SearchService {
  late Dio _dio;
  static String? baseUrl;

  SearchService() {
    _dio = FlutterBetterAuth.dioClient;
    baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl!.isEmpty) {
      throw Exception('API_BASE_URL not found in .env file');
    }
  }

  Future<List<SearchResultImage>> searchImages({
    String? projectId,
    List<String> detectedObjects = const [],
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (detectedObjects.isNotEmpty) {
        params['detectedObject'] = detectedObjects.join(',');
      }

      if (projectId != null && projectId.isNotEmpty) {
        params['projectId'] = projectId;
      }

      final response = await _dio.get(
        '$baseUrl/search',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => SearchResultImage.fromJson(json)).toList();
      } else {
        print('Failed to search images: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching images: $e');
      return [];
    }
  }

  Future<Uint8List?> fetchImageBytes(String imageUrl) async {
    try {
      final response = await _dio.get<Uint8List>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Error fetching image bytes: $e');
    }
    return null;
  }
}
