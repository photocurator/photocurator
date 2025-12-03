import 'package:dio/dio.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserStatistics {
  final String nickname;
  final String email;
  final DateTime? createdAt;

  UserStatistics({
    required this.nickname,
    required this.email,
    required this.createdAt,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    final createdRaw = json['createdAt']?.toString();
    if (createdRaw != null) {
      try {
        created = DateTime.parse(createdRaw);
      } catch (_) {}
    }
    return UserStatistics(
      nickname: json['nickname']?.toString() ?? '-',
      email: json['email']?.toString() ?? '-',
      createdAt: created,
    );
  }
}

class UserService {
  final Dio _dio;
  final String _baseUrl;

  UserService({Dio? dio})
      : _dio = dio ?? FlutterBetterAuth.dioClient,
        _baseUrl = dotenv.env['API_BASE_URL'] ?? '' {
    if (_baseUrl.isEmpty) {
      throw Exception('API_BASE_URL not configured');
    }
  }

  Future<UserStatistics> fetchMyStatistics() async {
    final response = await _dio.get('$_baseUrl/users/me/statistics');
    if (response.statusCode == 200) {
      return UserStatistics.fromJson(
          Map<String, dynamic>.from(response.data ?? {}));
    }
    throw Exception('Failed to load user statistics: ${response.statusCode}');
  }

  Future<String> calculateStatistics() async {
    final response = await _dio.post('$_baseUrl/users/me/statistics/calculate');
    if (response.statusCode == 202) {
      return response.data?.toString() ?? '';
    }
    throw Exception('Failed to calculate statistics: ${response.statusCode}');
  }
}
