import 'package:dio/dio.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'photo_detail_info_screen.dart';

class ImageDetailService {
  final Dio _dio;
  final String _baseUrl;

  ImageDetailService({Dio? dio})
      : _dio = dio ?? FlutterBetterAuth.dioClient,
        _baseUrl = dotenv.env['API_BASE_URL'] ?? '' {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL not configured');
    }
  }

  Future<PhotoDetailInfoData> fetchDetails(String imageId) async {
    final response = await _dio.get('$_baseUrl/images/$imageId/details');
    if (response.statusCode == 200) {
      return PhotoDetailInfoData.fromApi(
          Map<String, dynamic>.from(response.data ?? {}));
    }
    throw Exception('Failed to load image details: ${response.statusCode}');
  }
}
