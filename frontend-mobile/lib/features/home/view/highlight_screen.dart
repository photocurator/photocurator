import 'package:flutter/material.dart';
import 'package:photocurator/common/theme/colors.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_better_auth/core/flutter_better_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photocurator/common/theme/colors.dart';
import 'package:photocurator/common/bar/view/detail_app_bar.dart';
import 'package:photocurator/common/widgets/view_more_icon.dart';
import 'package:photocurator/common/widgets/photo_item.dart';
import 'package:photocurator/common/widgets/preview_bar.dart';
import 'dart:typed_data';

import 'package:provider/provider.dart';

import '../../../provider/current_project_provider.dart';

class HighlightScreen extends StatefulWidget {
  const HighlightScreen({Key? key}) : super(key: key);

  @override
  State<HighlightScreen> createState() => _HighlightScreenState();
}

class _HighlightScreenState extends State<HighlightScreen> {
  // Helper 함수 (너가 준 그대로)
  Future<Uint8List?> _fetchImageBytes(String imageId) async {
    try {
      final dio = FlutterBetterAuth.dioClient; // 인증된 Dio
      final response = await dio.get(
        '${dotenv.env['API_BASE_URL']}/images/$imageId/file',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (e) {
      debugPrint('Failed to fetch image bytes: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = context.read<CurrentProjectImagesProvider>();
    final bestShotImages = imageProvider.bestShotImages;

    /// musiq 기준 내림차순 정렬 후 상위 3개 사용
    final bannerImages = [...bestShotImages]
      ..sort((a, b) =>
          (b.qualityScore?.musiq ?? 0).compareTo(a.qualityScore?.musiq ?? 0));
    final topImages = bannerImages.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.wh1,
      body: Column(
        children: [
          // 🔥 배너
          SizedBox(
            height: 260,
            child: PageView.builder(
              itemCount: topImages.length,
              itemBuilder: (context, index) {
                final img = topImages[index];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppColors.lgE9ECEF,
                  child: FutureBuilder<Uint8List?>(
                    future: _fetchImageBytes(img.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      } else if (snapshot.hasError) {
                        debugPrint('Error loading banner image ${img.id}: ${snapshot.error}');
                        return const Center(child: Icon(Icons.broken_image));
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // 🔽 여기에 나머지 영역
          Expanded(
            child: Center(
              child: Text("아래 메인 컨텐츠 영역"),
            ),
          ),
        ],
      ),
    );
  }
}
